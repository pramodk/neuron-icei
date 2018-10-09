#!/bin/bash
set -e

##DATE : 7th Oct 2018

module purge all
module load mvapich2
export CC=gcc
export CXX=g++
export MPICC=mpicc
export MPICXX=mpicxx

NEURON_FLAGS="-O2 -g"
CORENEURON_FLAGS="-O2 -g"
arch=x86_64

package_names=(neuron ring traub)

#DIRECTORY UNDER WHICH ALL SOFTWARES WILL BE DOWNLOADED AND INSTALLED
export BASE_DIR=`pwd`/$softdir
export INSTALL_DIR=$BASE_DIR/install
export SOURCE_DIR=$BASE_DIR/sources

#SOURCE DIRECTORY
mkdir -p $SOURCE_DIR
mkdir -p $INSTALL_DIR

cd $SOURCE_DIR

# DOWNLOAD SIMULATION SOURCE CODE
if [ ! -d neuron ]; then
    cd $SOURCE_DIR
    git clone https://github.com/nrnhines/nrn.git neuron
    cd neuron && git checkout 83fc576725e00
    # hh compatibility between compute engines
    sed -i -e 's/GLOBAL minf/RANGE minf/g' src/nrnoc/hh.mod
    sed -i -e 's/TABLE minf/:TABLE minf/g' src/nrnoc/hh.mod
    ./build.sh
    cd $SOURCE_DIR
    git clone --recursive https://github.com/BlueBrain/CoreNeuron.git coreneuron
    cd coreneuron && git checkout ba64cfac3c719777
fi

cd $SOURCE_DIR

#INSTALL ALL DEPENDENCIES
for package in ${package_names[*]}
do
    cd $SOURCE_DIR
    echo "Installing package ${package^^} under ${INSTALL_DIR}"

    case "$package" in

        neuron)
            mkdir -p $SOURCE_DIR/nrnmpi && cd $SOURCE_DIR/nrnmpi
            $SOURCE_DIR/neuron/configure --prefix=$INSTALL_DIR/neuron --without-iv --with-paranrn --with-nrnpython=`which python` CFLAGS="$NEURON_FLAGS"  CXXFLAGS="$NEURON_FLAGS" --disable-rx3d linux_nrnmech=no
            make -j VERBOSE=1
            make install
            ;;

        ring)
            cd $SOURCE_DIR
            if [ ! -d "ring" ]; then
                git clone https://github.com/pramodk/ringtest.git ring
            fi
            cd ring
            mkdir -p build && cd build
            cmake $SOURCE_DIR/coreneuron -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/ring -DADDITIONAL_MECHPATH=`pwd`/../mod -DCMAKE_C_FLAGS="$CORENEURON_FLAGS" -DCMAKE_CXX_FLAGS="$CORENEURON_FLAGS" -DCMAKE_BUILD_TYPE=MY_CUSTOM -DCORENEURON_OPENMP=OFF -DUNIT_TESTS=OFF -DCOMPILE_LIBRARY_TYPE=SHARED -DUNIT_TESTS=OFF
            make VERBOSE=1 -j install
            cd ..
            $INSTALL_DIR/neuron/$arch/bin/nrnivmodl mod
            ;;

        traub)
            cd $SOURCE_DIR
            if [ ! -d "traub" ]; then
                git clone https://github.com/pramodk/nrntraub.git traub -b icei
            fi
            cd traub
            mkdir -p build && cd build
            cmake $SOURCE_DIR/coreneuron -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/traub -DADDITIONAL_MECHPATH=`pwd`/../mod -DCMAKE_C_FLAGS="$CORENEURON_FLAGS" -DCMAKE_CXX_FLAGS="$CORENEURON_FLAGS" -DCMAKE_BUILD_TYPE=MY_CUSTOM -DCORENEURON_OPENMP=OFF -DUNIT_TESTS=OFF -DCOMPILE_LIBRARY_TYPE=SHARED -DUNIT_TESTS=OFF
            make VERBOSE=1 -j install
            cd ..
            $INSTALL_DIR/neuron/$arch/bin/nrnivmodl mod
            ;;
    esac
done
