# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

module load gcc/4.8.2
#For meld to work
#module load python/2.7.3-x86_64
module load matlab/R2015a

export SVN_EDITOR=vim
export LIBFFI_HOME=/home/sdasgup3/Documents/libffi.inst
export LLVM_HOME=$HOME/Documents/llvm/llvm.inst
export LLVM_2_9_HOME=$HOME/llvm/llvm-2.9/
export ZESTI_HOME=$HOME/Documents/klee-zesti/zesti.obj/Release+Asserts/bin/
export KLEE_HOME=$HOME/Work/klee.3.4/Release+Asserts/
export FLEX_HOME=$HOME/Install/flex.install
export BISON_HOME=$HOME/Install/bison.install
#export M4_HOME=$HOME/Install/m4.install
export M4_HOME=
export GRAPHAL_HOME=$HOME/Install/graphal-1.0.1/build/ 
export MAIL_HOME=$HOME/Install/
export CMAKE_HOME=$HOME/Install/cmake-3.3.2
export SELF_HOME=$HOME/Install/self.install
export SMALLTALK_HOME=$HOME/Install/pharo4.0/
export GDB_HOME=$HOME/Install/gdb-7.10
export QT_HOME=$HOME/Qt/5.5/gcc_64/ 
export GRI_HOME=$HOME/GRI/source

export PATH=$QT_HOME/bin:$MAIL_HOME:$BISON_HOME/bin/:$M4_HOME/bin/:$FLEX_HOME/bin/:$LLVM_HOME/bin:$ZESTI_HOME:$KLEE_HOME/bin/:$CMAKE_HOME/bin/:$SELF_HOME/vm:$SMALLTALK_HOME/:$GDB_HOME/gdb/:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LIBFFI_HOME/lib64:$GRAPHAL_HOME/libgraphal/:$FLEX_HOME/lib/:$GRI_HOME/build/lib/

if [ -f ~/.aliases ]; then
  . ~/.aliases
fi

# Some commands
#tail -n 20  ~/commands.txt
git config --global user.name "Sandeep Dasgupta"
git config --global user.email "sdasgup3@illinois.edu"
