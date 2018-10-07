### Spack Based Docker Image for NEURON Simulations


- Clone repository

    ```
    https://github.com/pramodk/neuron-icei.git
    cd neuron-icei
    ```

- Build image

    ```
    docker build --build-arg username=kumbhar --build-arg password=kumbhar123  -t neuron-icei .
    ```
This will build neuron based simulation toolchain and prepare test simulation.


- To run a simulation within a container:

    ```
    docker run -i -t cellular:latest /bin/bash
    cd sim/build/circuitBuilding_1000neurons/
    module load neurodamus/master
    mpiexec -n 6 --allow-run-as-root special $HOC_LIBRARY_PATH/init.hoc -mpi
    ```
- To run a simulation by launching a container:

    ```
    docker run -i -t cellular:latest /bin/bash -c 'cd $HOME/sim/build/circuitBuilding_1000neurons && . $SPACK_ROOT/share/spack/setup-env.sh && module load neurodamus/master && mpiexec -n 6 --allow-run-as-root special $HOC_LIBRARY_PATH/init.hoc -mpi'
    ```

- To run on multiple docker containers:
	- Update `docker-compose.yml` specification with appropriate number of compute nodes (`scale` parameter in `node` service)
	- Launch containers with `docker-compose`
	- Run simulation on the running containers

	    ```
	    # start cluster
	    $ docker-compose up -d

	    # check cluster running
	    $ docker ps
		CONTAINER ID        IMAGE               COMMAND               CREATED             STATUS              PORTS                   NAMES
		0b2b5386ce12        cellular:latest     "/usr/sbin/sshd -D"   8 minutes ago       Up 3 minutes        0.0.0.0:32770->22/tcp   neurondockerspack_login_1
		1643c10a96af        cellular:latest     "/usr/sbin/sshd -D"   8 minutes ago       Up 3 minutes        22/tcp                  neurondockerspack_node_1
		7ac4b751c574        cellular:latest     "/usr/sbin/sshd -D"   8 minutes ago       Up 3 minutes        22/tcp                  neurondockerspack_node_3
		60ec8d0e7052        cellular:latest     "/usr/sbin/sshd -D"   8 minutes ago       Up 3 minutes        22/tcp                  neurondockerspack_node_2

		# make sure nodes are connected (username used inside container)
		$ USERNAME=kumbhar
		$ docker-compose exec --user $USERNAME --privileged login /bin/bash -c 'mpiexec -n 6  --host node_1:2,node_2:2,node_3:2 $HOME/test/hello'
		Hello world from processor 1643c10a96af, rank 0 out of 6 processors
		Hello world from processor 1643c10a96af, rank 1 out of 6 processors
		Hello world from processor 60ec8d0e7052, rank 2 out of 6 processors
		Hello world from processor 60ec8d0e7052, rank 3 out of 6 processors
		Hello world from processor 7ac4b751c574, rank 4 out of 6 processors
		Hello world from processor 7ac4b751c574, rank 5 out of 6 processors

		# run simulation using multiple containers
		$ docker-compose exec --user $USERNAME --privileged login /bin/bash -c 'cd $HOME/sim/build/circuitBuilding_1000neurons && . $SPACK_ROOT/share/spack/setup-env.sh && module load neurodamus/master && mpiexec -x HOC_LIBRARY_PATH -n 6 --host node_1:2,node_2:2,node_3:2 `which special` ${HOC_LIBRARY_PATH}/init.hoc -mpi'
		....
		numprocs=6
		NEURON -- VERSION + master (9f36b13+) 2018-08-28
		Duke, Yale, and the BlueBrain Project -- Copyright 1984-2018
		See http://neuron.yale.edu/neuron/credits
		Additional mechanisms from files
		....
		create file ./out.dat
					  Event Label  Node  MinTime  Node  MaxTime
		accum                    Synapse init     4     0.00     5     0.04
		accum                       file read     0     0.00     0     0.00
		accum                     Replay init     0     0.00     0     0.00
		accum                         stdinit     2     0.13     4     0.18
		accum                          psolve     4     9.79     3     9.82
		 memusage node 0 according to nrn_mallinfo:
			 59.289062MB

		# remove containers
		$ docker-compose stop && docker-compose down
	    ```

- Notes :
    * Do not push the image
    * Remove ssh key from server once the image is built
    * Todo : need to squash all layes
