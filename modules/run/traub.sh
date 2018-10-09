#!/bin/bash
set -e

##DATE : 7th Oct 2018


module purge all
module load mvapich2 neuron/develop

# load profile or non-profiled versions
module load neuronmodels/traub$1

# profile format
export TAU_PROFILE_FORMAT=merged

mkdir -p traub && cd traub

sim_time=5

# Running with NEURON
for nproc in 1 2 4 8; do
    mpirun -n $nproc special -mpi -c mytstop=$sim_time -c coreneuron=0 $HOME/manual/sources/traub/run.hoc &> nrn.$nproc.log
    sortspike out$nproc.dat out.dat.nrn.$nproc
    [[ -f $tau_file ]] && mv $tau_file tau.nrn.$nproc.xml
    sol_time=$(grep Solver nrn.$nproc.log | sed 's/Solver Time ://')
    echo "[NEURON] Running with $nproc took : $sol_time seconds"
done

# Running with CoreNEURON
for nproc in 1 2 4 8; do
    mpirun -n $nproc special -mpi -c mytstop=$sim_time -c coreneuron=1 $HOME/manual/sources/traub/run.hoc &> cnrn.$nproc.log
    sortspike out.dat out.dat.cnrn.$nproc
    [[ -f $tau_file ]] && mv $tau_file tau.cnrn.$nproc.xml
    sol_time=$(grep Solver cnrn.$nproc.log | sed 's/Solver Time ://')
    echo "[CoreNEURON] Running with $nproc took : $sol_time seconds"
done
