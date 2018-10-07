FROM ubuntu:18.04
MAINTAINER Pramod Kumbhar <pramod.s.kumbhar@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

# default software required
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages install \
    aptitude \
    cmake \
    build-essential \
    git \
    software-properties-common \
    sudo \
    vim \
    zlib1g-dev \
    libbz2-dev \
    curl \
    gfortran \
    unzip \
    bison \
    flex \
    pkg-config \
    autoconf \
    automake \
    make \
    python2.7-dev \
    libncurses-dev \
    openssh-server \
    libopenmpi-dev \
    libhdf5-serial-dev \
    python-minimal \
    libtool \
    tcl-dev \
    && rm -rf /var/lib/apt/lists/*

# default arguments
ARG username=kumbhar
ARG password=kumbhar123

# username password
ENV USERNAME $username
ENV PASSWORD $password

# user setup (ssh login fix, otherwise user is kicked off after login)
RUN mkdir /var/run/sshd \
    && echo 'root:${USERNAME}' | chpasswd \
    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# add USER
RUN useradd -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME}:${PASSWORD}" | chpasswd \
    && adduser --disabled-password --gecos "" ${USERNAME} sudo \
    && echo ${USERNAME}' ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# expose ssh port
EXPOSE 22

# install rest of packages as normal user
USER $USERNAME

# create directories
ENV HOME /home/$USERNAME
ENV SOFTDIR $HOME/softs
RUN mkdir -p $SOFTDIR
WORKDIR $SOFTDIR

# clone spack
RUN git clone https://github.com/BlueBrain/spack.git -b icei-2018-10
ENV SPACK_ROOT $SOFTDIR/spack
ENV PATH $SPACK_ROOT/bin:$PATH

# setup spack variables
RUN echo "" >> $HOME/.bashrc
RUN echo "#Setup SPACK path" >> $HOME/.bashrc
RUN echo "export SPACK_ROOT=${SPACK_ROOT}" >> $HOME/.bashrc
RUN echo "export PATH=\$SPACK_ROOT/bin:\$PATH" >> $HOME/.bashrc
RUN echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> $HOME/.bashrc

# see this: http://stackoverflow.com/questions/20635472/using-the-run-instruction-in-a-dockerfile-with-source-does-not-work
RUN sudo rm /bin/sh && sudo ln -s /bin/bash /bin/sh
RUN . $SPACK_ROOT/share/spack/setup-env.sh

# check compilers
RUN spack compiler find
RUN spack compilers

# copy spack config
RUN mkdir -p $HOME/.spack/linux
ADD packages.yaml $HOME/.spack/linux/
ADD modules.yaml $HOME/.spack/linux/
ADD config.yaml $HOME/.spack/linux/

# install module
RUN spack bootstrap
RUN echo "#Setup MODULE path" >> $HOME/.bashrc
RUN echo "MODULES_HOME=`spack location -i environment-modules`" >> $HOME/.bashrc
RUN echo "source \$MODULES_HOME/Modules/init/bash" >> $HOME/.bashrc

# make ssh dir and add your private key (don't publish!)
ADD config $HOME/.ssh/config
RUN sudo chown -R $USERNAME $HOME/.ssh
RUN ssh-keyscan github.com >> $HOME/.ssh/known_hosts

# register external packages
RUN spack install autoconf automake bison cmake flex libtool ncurses openmpi pkg-config python

# install neuron models
RUN spack spec -I -l neuron neuronmodels@ring
RUN spack install neuron
RUN spack install tau
RUN spack install -n neuronmodels@ring
RUN spack spec neuronmodels@ring ^coreneuron+profile
RUN spack install -n neuronmodels@ring ^coreneuron+profile

# check available modules
RUN spack find

# add test example
ADD test/hello.c $HOME/test/hello.c
RUN sudo chown -R $USERNAME $HOME/test
RUN mpicc $HOME/test/hello.c -o $HOME/test/hello

# start in $HOME
WORKDIR $HOME

# start as root
USER root
CMD ["/usr/sbin/sshd", "-D"]
