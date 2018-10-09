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
    libhdf5-serial-dev \
    numactl \
    python-minimal \
    libtool \
    libpciaccess-dev \
    libxml2-dev \
    tcl-dev \
    && rm -rf /var/lib/apt/lists/*

# default arguments
ARG username=kumbhar
ARG password=kumbhar123
ARG git_name="Pramod Kumbhar"
ARG git_email="pramod.s.kumbhar@gmail.com"

# username password
ENV USERNAME $username
ENV PASSWORD $password
ENV GIT_NAME $git_name
ENV GIT_EMAIL $git_email

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
ENV MODULES_DIR $HOME/modules
RUN mkdir -p $MODULES_DIR
WORKDIR $MODULES_DIR

# git config
RUN git config --global user.email "${GIT_EMAIL}"
RUN git config --global user.name "${GIT_NAME}"

# clone spack
RUN git clone https://github.com/BlueBrain/spack.git -b icei-2018-10
ENV SPACK_ROOT $MODULES_DIR/spack
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
RUN spack compiler find && spack compilers

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
RUN spack install autoconf automake bison cmake flex libtool ncurses pkg-config python

# install neuron models
RUN spack install mvapich2
RUN spack install tau~openmp
RUN spack install neuron
RUN spack install -n neuronmodels@ring neuronmodels@traub neuronmodels@coretest
RUN spack install -n neuronmodels@ring+profile^coreneuron+profile \
                     neuronmodels@traub+profile^coreneuron+profile \
                     neuronmodels@coretest+profile^coreneuron+profile

# installed packages
RUN spack find

# start in $HOME
WORKDIR $HOME

# copy install/benchmark script and install packages
ADD manual $HOME/manual
RUN sudo chown -R $USERNAME $HOME/manual
RUN cd $HOME/manual && bash -i installer.sh

# copy modules benchmark script
ADD modules $HOME/modules
RUN sudo chown -R $USERNAME $HOME/modules

# start as root
CMD ["/usr/sbin/sshd", "-D"]
