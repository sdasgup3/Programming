###Cheatsheet
- To expand all variables and prints the full commands before output of the command.
```
#!/bin/bash
set -x #start teh expansion  
cmd ..
cmd ..
set +x #end 

or

$bash -x script.sh
```


```
To compile all the files like
a/b/c.bc
z.bc
to
a/b/c.ll
z.ll
for f in `find . -name "*linked.bc"`; do b=$(echo $f | sed 's/\.bc//g'); llvm-dis $b.bc -o $b.ll;  done
```

```
To autofill command from the  command histofry` add the  following line in ~/.inputrc

# Key bindings, up/down arrow searches through history
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOA": history-search-backward
"\eOB": history-search-forward
```

###Misc Commands
```
LLVM_PATH=$(<./LLVM_PATH.linux) _Setting an ev var from a file_

```