#!/bin/bash
set -e

##DATE : 7th Oct 2018

module purge all
module load mvapich2

arch=x86_64
export PATH=$HOME/manual/sources/olfactory-bulb/sim/$arch:$PATH
export PATH=$HOME/manual/install/neuron/$arch/bin:$PATH
export HOC_LIBRARY_PATH=$HOME/manual/sources/olfactory-bulb/sim
export PYTHONPATH=$HOME/manual/sources/olfactory-bulb/sim:$PYTHONPATH
export OMP_NUM_THREADS=1

mkdir -p olfactory-bulb && cd olfactory-bulb

sim_time=2

# Running with NEURON
for nproc in 1 2 4 8; do
    rm -rf sim
    cp -r $HOME/manual/sources/olfactory-bulb/sim . && cd sim
    mpirun -n $nproc special -mpi -python $HOME/manual/sources/olfactory-bulb/sim/bulb3dtest.py -tstop $sim_time &> nrn.$nproc.log
    sol_time=$(grep Solver nrn.$nproc.log | sed 's/Solver Time ://')
    echo "[NEURON] Running with $nproc rank took : $sol_time seconds"
    cd ..
done
