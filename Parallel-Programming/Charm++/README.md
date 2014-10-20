General
========
1. readonly  CProxy_Master name; // This name should not be mainchare
2. All the entry methods should be public
3. Add Worker(CkMigrateMessage*) {}
4. Given a CProxy_worker arra; you cannot do array[index].memberVar. The only way to get  a member var is to pass it using a entry method.
5. The place where we do mainProxy.entryM(); the control does not go to the mainchare, but instead it will call in asuynchronously and go ahead, so better make sure that the following code has a cleaner exit in case you do  not want to do anything else after calling mainchare entry method.
6. array [1D] Worker NOT chare [1D] ...
7. Worker(CkMigrateMessage* msg) {} //In C file only
8. In ci, Main constructor is also an entry method 
9. To enable generation of the serialization code, the entry method signatures must be declared in the interface file.
10. Since Charm++ runs on distributed memory machines, we cannot pass an array via a pointer in the usual C++ way. The array length expression is evaluated exactly once per invocation, on the sending side only. Thus executing the doGeneral method above will invoke the (user-defined) product function exactly once on the sending processor.
```C++
    entry void doLine(float data[n],int n);
    entry void doPlane(float data[n*n],int n);
    entry void doSpace(int n,int m,int o,float data[n*m*o]);
    entry void doGeneral(int nd,int dims[nd],float data[product(dims,nd)]);
```
11. For creating chare arrays
```C++
    CProxy_array A = CProxy_array::ckNew(p1, size); // size must be the last arg
    
    array::array(int p1) {}
```
12. MPI: a node have cores and which in turn has hardware threads. In MPI, if we have a 100 nodes each with 10 cores we run a 1000 rank mpi prog with each process on each core. Even if the cores share the same node, they still do message passing.
13. Adding more cores does not help in parallelism as the memory contemtion occurs as all the core will be shareing the memry bus and if there is lot of memory request then there might be contention.
14. setcpuaffinity: to say operating system that if a thread is cintext swicthed due to some reason then again host that in the same core. Hosting in other cores lead to loosing chached data.

SDAG
=====
1.  structure dagger entry method in ci file should end with semicolon
2.  handy to use wrap (x) ((x + n) %n) 
3.  for reduction with logical_and use int as the contributing elements
4.  Dont forget to the following
    ``` C++
    class Worker: public CBase_Worker {
      Worker_SDAG_CODE
      public:
    
        Worker() {
          __sdag_init();
        }

        void pup(PUP::er &p) {
          CBase_Worker::pup(p);
          __sdag_pup(p);
        }
    }
    ```
    
Reduction
=========
1. After the data is reduced, it is passed to you via a callback object. The message passed to the callback is of type CkReductionMsg . Unlike typed reductions, here we discuss callbacks that take CkReductionMsg* argument. The important members of CkReductionMsg are getSize() , which returns the number of bytes of reduction data; and getData() , which returns a ``void *'' to the actual reduced data. You may pass the client callback as an additional parameter to contribute .
```C++
    entry void myReductionEntry(CkReductionMsg* msg);    
    //In C
    double forces[2]=get_my_forces();
    CkCallback cb(CkIndex_myArrayType::myReductionEntry(NULL), thisProxy);
    contribute(2*sizeof(double), forces,CkReduction::sum_double, cb);
```   
```C++
    //For synchronisation purpose
    entry void myReductionEntry(CkReductionMsg* msg);    
    //In C
    CkCallback cb(CkIndex_myArrayType::myReductionEntry(NULL), thisProxy);
    contribute(cb);
```  
2. If no member passes a callback to contribute , the reduction will use the default callback. Programmers can set the default callback for an array or group using the **ckSetReductionClient(CkCallback*)** proxy call on **processor zero**, or by passing the callback to CkArrayOptions::setReductionClient() before creating the array. Again, a CkReductionMsg message will be passed to this callback, *which must delete the message when done*.
```C++
    CkCallback *cb = new CkCallback(CkIndex_Main::Result(NULL),  mainProxy); //Or
    CkCallback *cb = new CkCallback(CkReductionTarget(Main,done), thisProxy);// If Typed reduction
    cellProxy.ckSetReductionClient(cb);
```
3. As above, the client entry method of a reduction takes a single argument of type CkReductionMsg. However, by giving an entry method the reductiontarget attribute in the .ci file, you can instead use entry methods that take arguments of the same type as specified by the contribute call. When creating a callback to the reduction target, the entry method index is generated by CkReductionTarget(ChareClass, method_name) instead of CkIndex_ChareClass::method_name(...). 
```C++
    //In .ci
    entry [reductiontarget] void done(CkReductionMsg*);
    //In .C
    CkCallback cb(CkReductionTarget(mainChareClassName, entryMethod), mainProxy);   
    contribute(cb); // or
    contribute(sizeof(int),&myInt,CkReduction::sum_int, cb)
```
4. Sync reductions:
```C++
//In .ci
entry void done(CkReductionMsg* );
//In C
contribute(CkCallback(CkIndex_Main::done(NULL), mainproxy));
            OR
//In .ci
entry [reductiontarget] void barrierH();
//In C
contribute (CkCallback(CkReductionTarget(Worker,  barrierH), workerarray)); 
            OR
//In .ci
entry void resumeIter();
//In .C            
CkCallback cb(CkIndex_Main::resumeIter(), mainProxy);
contribute(0, NULL, CkReduction::sum_int, cb);
            OR
//In .ci            
entry void doStep() 
//In C            
contribute(0, 0, CkReduction::concat, CkCallback(CkIndex_Stencil::doStep(), thisProxy));
```
Quiescence Detection
==========================
```C++
//In .ci
    entry void Qdetect(CkReductionMsg*);
    entry [reductiontarget]void Qdetect2();
//In .C
    Main::Main(CkArgMsg* msg) {    
        //CkStartQD(CkIndex_Main::Qdetect(NULL), &thishandle); or
        //CkCallback cb = CkCallback(CkIndex_Main::Qdetect(NULL), thisProxy); or
        CkCallback cb = CkCallback(CkReductionTarget(Main, Qdetect2), thisProxy); 
        CkStartQD(cb);
    }
    void Qdetect(CkReductionMsg* msg) {
        CkPrintf("Quiescence detecetd\n");
        CkExit();
    }
    void Qdetect2() {
        CkPrintf("Quiescence2 detecetd\n");
        CkExit();
    }
```

Threaded Entry Methods
===========================
1. This is a way to have thread sync. Note that The place where the chares elements are going after the reduction is their own respective thisIndex.barrierH(), where they have they owned CthThread t to awaken. After calling contribute the threads suspend them self till all the thread call contribute when the reduction happen and barrierH is called and all are awakened.
```C++
class Worker: public CBase_Worker  {

  public:
   
    CthThread t;
   
    void barrier() {
      contribute (CkCallback(CkReductionTarget(Worker,  barrierH), workerarray));
      t = CthSelf();
      CthSuspend();
    } 

    void barrierH() {
      CthAwaken(t);
    } 
```
2. Sync methods should always   **return message**
3. If respond is a sync method, then the following recurcive calls will serialize them as the second sync call cannot proceed before the first returns. 
    ```C++
    myMsg* n1 = w1.respond(n-1);
    myMsg* n2 = w1.respond(n-2);
    ```
4. Any method that calls a sync method must be able to suspend : threaded method of a chare C Can suspend, without blocking the processor, Other chares can then be executed, Even other methods of chare C can be executed
5. You can suspend a thread and “awaken” it
    * CthThread CthSelf(): Returns the ID of the (calling) thread 
    * CthSuspend: wrap it up, and give control to the scheduler. This is what happens underneath a “blocking invocation” of a sync method
    * CthAwaken(threadID):Put this thread in the list of ready threads (and other method invocations). Scheduler will run it when it comes to the head of the queue
6. Threads are still a cooperative rather than pre-emptive multi-threading, and it is still true that only a single method is actually running at a time on a give chare; but it is now possible for multiple method invocations to be “active” with suspended threads.
7. Threaded methods are used in (relatively rare) situations when the blocking wait happens deep from nested function calls, since structured dagger notation requires such waiting to be lifted to the top level of the control flow. 
8. Structured dagger based methods have a slightly smaller overhead than threaded methods, don’t need allocation of a separate stack, and are typically perceived as clearer to understand by Charm++ programmers.
9. Futures need to be created from a threaded entry method.
10. Syntax
```C++
myMsg* m = (myMsg*)CkWaitFuture(f); // conversion from void*
```
 
Messages
==========
1. Messages passed to Charm belong to Charm – Deleted or reused by Charm after sending
2. Message delivered by Charm belongs to user – Must be reused or deleted; If you don’t delete or reuse, memory leaks happen
3. Priority

```C++
    MyVarsizeMsg *msg = new (10,7, 8*sizeof(int))  MyVarsizeMsg(<constructor args>);
    *(int*)CkPriorityPtr(msg) = prio; //set priority OR
    void CkSetQueueing(MsgType message, int queueingtype)
    int * prioMsg = CkPriorityPtr(msg); //get priority
    queueingType: CK_QUEUEING_XIFO, CK_QUEUEING_IXIFO, CK_QUEUEING_BXIFO where X = F or L 
    
    OR
    CkEntryOptions opts1, opts2;
    opts1.setQueueing(CK_QUEUEING_FIFO);
    opts1.setPriority(prio_t integerPrio);
    opts2.setQueueing(CK_QUEUEING_LIFO);
    opts2.setPriority(int prioBits,const prio_t *prioPtr);
    chare.entry_name(arg1, arg2, **opts1**);
    chare.entry_name(arg1, arg2, **opts2**);  
```

Tags
====
1. nokeep: User code should not free messages; 
    * Common usage: avoiding a copy for each chare on a PE during a broadcast
    * Also note: you cannot modify contents of nokeep messages


Group and NodeGroup
========================
1. Note that there can be several instances of each group type. In such a case, each instance has a unique group identifier, and its own set of branches.
2. This call returns a regular C++ pointer to the actual object (not a proxy) referred to by the proxy groupProxy. Once a proxy to the local branch of a group is obtained, that branch can be accessed as a regular C++ object. Its public methods can return values, and its public data is readily accessible.

```C++
    GroupType *g=groupProxy.ckLocalBranch();
```
3. If the mainchare wants to broadcast an entry method on a chare array and after they finishes they must all return back to a specific fun F.

```C++
    ckCallback cb = ckCallback(ckReductionTarget(Main, comaeBackAfterRegistration), mainProxy);
    workerarray.registerToNodeGroup(cb);
    
    Worker::registerToNodeGroup(ckCallback &cb) {
        groupProxy.ckLocalBranch()->registerMe();
        contribute(cb);
    }
    
    myGroup::registerMe {
        countOfCharesOnThisPE++;
    }

    myGroup::submitToMain() {
        if(membersContactedMe == countOfCharesOnThisPE) {
            contribute(..To Main .. );
        }
    }
```
4. When an entry method is invoked on a particular branch of a nodegroup, it may be executed by any PE in that logical node. Thus two invocations of a single entry method on a particular branch of a NodeGroup may be executed concurrently by two different PEs in the logical node.
5. If a method M of a nodegroup NG is marked exclusive, it means that while an instance of M is being executed by a PE within a logical node, no other PE within that logical node will execute any other exclusive methods. However, PEs in the logical node may still execute non-exclusive entry method invocations.
6. 

Migration
===========
```C++
    void pup(PUP::er &p){
      p|x;
      p|y;
      p|size;
      int isNull = (!arr);
      p|isNull;
      if(p.isUnpacking()) {
        if(isNull) {
          arr = NULL;
        } else {
          arr = new int[size]; // NOT int arr ... 
        }
      }
      p(arr, size); //Must be outside packing or unpacking
    }
    
    void pup(PUP::er &p) {
        CBase MyChare::pup(p);
        p | heapArraySize;
        if (p.isUnpacking()) {
            heapArray = new float[heapArraySize];
        }
        p(heapArray, heapArraySize);
        bool isNull = !pointer;
        p | isNull;
        if (!isNull) {
            if (p.isUnpacking()) {
                pointer = new   MyClass();
            }
            p | *pointer;
        }
```

To Dos
========
1. Quicense detection
2. Let e be an threaded entry method and we call e on an array of size 2 chares c0 and c1 and lets suppose there are scedules on the same core. Let the scheduler picks c0.e() and runs it. There will be  a thread t0 corresponding to the that entry method e. Now suppose that thread t0 call a sync method SM on c1. 
Is C1.SM a lead to a normal process or it will also generate a thread to run on the core?? 
Now t0 will suspend till it is awakened by the return of the sync method. 
c1.SM will be in the scheduler queue?? 
While t0 is suspended can a different entry method get scheduled??
If Yes, let c1.e gets scheduled and got suspended somehow...... then c1.SM gets shceduled...
++ppn what is that
CkLoop_Exit need to be called only on non_smp mode Also ckLoop_init(par to giv in non smp)
thishandle vs thisProxy
ResumeFromSync: entry method or not
bare threaf fib prgm: why respond is not threaded





1. Charm++ basics: entry methods etc.Principle of Persistence
2. Chare Arrays
3. SDAG
5. Grain Size



7. Quiescence detection ; [DONE]
10. Charm++ tools: LiveViz, Projections, CharmDebug, Load balancing / LB Strategies (Greedy, refine, etc..) / PUP / Object Migration

8. Threaded methods / Futures / Messages
Paper
13. Cannon's Algorithm / Parallel Prefix

14. ENtry method tags
Message
6. Collective Communication: Reduction, reduction managers, callback, broadcast
11. Array Sections / Multicast
12. SMP Mode/CkLoop  
9. Groups / Node groups