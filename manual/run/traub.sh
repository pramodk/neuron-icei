#!/bin/bash
set -e

##DATE : 7th Oct 2018

module purge all
module load mvapich2

arch=x86_64
export PATH=$HOME/manual/sources/traub/$arch:$PATH
export PATH=$HOME/manual/install/neuron/$arch/bin:$PATH
export HOC_LIBRARY_PATH=$HOME/manual/sources/traub
export HOC_LIBRARY_PATH=$HOME/manual/sources/traub/hoc:$HOC_LIBRARY_PATH
export PYTHONPATH=$HOME/manual/sources/traub:$PYTHONPATH
export CORENEURONLIB=$HOME/manual/install/traub/lib/libcoreneuron.so

mkdir -p traub && cd traub

sim_time=5

# Running with NEURON
for nproc in 1 2 4 8; do
    mpirun -n $nproc special -mpi -c mytstop=$sim_time -c coreneuron=0 $HOME/manual/sources/traub/run.hoc &> nrn.$nproc.log
    sortspike out$nproc.dat out.dat.nrn.$nproc
    sol_time=$(grep Solver nrn.$nproc.log | sed 's/Solver Time ://')
    echo "[NEURON] Running with $nproc took : $sol_time seconds"
done

# Running with CoreNEURON
for nproc in 1 2 4 8; do
    mpirun -n $nproc special -mpi -c mytstop=$sim_time -c coreneuron=1 $HOME/manual/sources/traub/run.hoc &> cnrn.$nproc.log
    sortspike out.dat out.dat.cnrn.$nproc
    sol_time=$(grep Solver cnrn.$nproc.log | sed 's/Solver Time ://')
    echo "[CoreNEURON] Running with $nproc took : $sol_time seconds"
done
