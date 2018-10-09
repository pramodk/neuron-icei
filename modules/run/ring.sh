#!/bin/bash
set -e

##DATE : 7th Oct 2018

module purge all
module load mvapich2 neuron/develop

# load profile or non-profiled versions
module load neuronmodels/ring$1

# profile format
export TAU_PROFILE_FORMAT=merged

mkdir -p ring && cd ring

sim_time=100
network_params="-nring 8 -ncell 16 -branch 32 64"
tau_file=tauprofile.xml

# Running with NEURON
for nproc in 1 2 4 8; do
    mpirun -n $nproc special -python -mpi $MODEL_DIR/ringtest.py $network_params -tstop $sim_time -coredat coredat &> nrn.$nproc.log
    sortspike coredat/spk$nproc.std out.dat.nrn.$nproc
    [[ -f $tau_file ]] && mv $tau_file tau.nrn.$nproc.xml
    sol_time=$(grep Solver nrn.$nproc.log | sed 's/Solver Time ://')
    echo "[NEURON] Running with $nproc took : $sol_time seconds"
done

# Running with CoreNEURON
for nproc in 1 2 4 8; do
    #export PROFILEDIR=cneuron.$nproc.tau
    mpirun -n $nproc special -python -mpi $MODEL_DIR/ringtest.py $network_params -tstop $sim_time -coredat coredat -runcn &> cnrn.$nproc.log
    sortspike out.dat out.dat.cnrn.$nproc
    [[ -f $tau_file ]] && mv $tau_file tau.cnrn.$nproc.xml
    sol_time=$(grep Solver cnrn.$nproc.log | sed 's/Solver Time ://')
    echo "[CoreNEURON] Running with $nproc took : $sol_time seconds"
done
