#!/bin/bash
set -e

##DATE : 7th Oct 2018

module purge all
module load mvapich2

arch=x86_64
export PATH=$HOME/manual/sources/ring/$arch:$PATH
export PATH=$HOME/manual/install/neuron/$arch/bin:$PATH
export PYTHONPATH=$HOME/manual/sources/ring:$PYTHONPATH
export HOC_LIBRARY_PATH=$HOME/manual/sources/ring
export CORENEURONLIB=$HOME/manual/install/ring/lib/libcoreneuron.so
export OMP_NUM_THREADS=1

mkdir -p ring && cd ring

sim_time=100
network_params="-nring 8 -ncell 16 -branch 32 64"

# Running with NEURON
for nproc in 1 2 4 8; do
    mpirun -n $nproc special -python -mpi $HOME/manual/sources/ring/ringtest.py $network_params -tstop $sim_time -coredat coredat &> nrn.$nproc.log
    sortspike coredat/spk$nproc.std out.dat.nrn.$nproc
    sol_time=$(grep Solver nrn.$nproc.log | sed 's/Solver Time ://')
    echo "[NEURON] Running with $nproc rank took : $sol_time seconds"
done

# Running with CoreNEURON
for nproc in 1 2 4 8; do
    mpirun -n $nproc special -python -mpi $HOME/manual/sources/ring/ringtest.py $network_params -tstop $sim_time -runcn &> cnrn.$nproc.log
    sol_time=$(grep Solver cnrn.$nproc.log | sed 's/Solver Time ://')
    sortspike out.dat out.dat.cnrn.$nproc
    echo "[CoreNEURON] Running with $nproc rank took : $sol_time seconds"
done
