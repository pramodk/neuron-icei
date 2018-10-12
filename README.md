### Docker Image With NEURON models [installer + benchmark scripts]


- Clone repository

    ```
    git clone https://github.com/pramodk/neuron-icei.git
    cd neuron-icei
    ```

- Build image

    ```
    → docker build --build-arg username=kumbhar --build-arg password=kumbhar123  -t neuron-icei .
    ```

This will build neuron/coreneuron simulation toolchain with following models:
	- Ring network of branching cells
	- A single column thalamocortical network model


- To run small test within a container:

	 For ring test

    ```
    → docker run -i -t neuron-icei:latest /bin/bash -i -c 'cd $HOME/manual/run && bash ring.sh'
		[NEURON] Running with 1 took :  1.230000 seconds
		[NEURON] Running with 2 took :  0.650000 seconds
		[NEURON] Running with 4 took :  0.330000 seconds
		[NEURON] Running with 8 took :  0.180000 seconds
		[CoreNEURON] Running with 1 took :  1.08796 seconds
		[CoreNEURON] Running with 2 took :  0.616106 seconds
		[CoreNEURON] Running with 4 took :  0.311387 seconds
		[CoreNEURON] Running with 8 took :  0.158982 seconds
    ```

    For traub test

    ```
    → docker run -i -t neuron-icei:latest /bin/bash -i -c 'cd $HOME/manual/run && bash traub.sh'
		[NEURON] Running with 1 took :  8.780000 seconds
		[NEURON] Running with 2 took :  4.950000 seconds
		[NEURON] Running with 4 took :  2.790000 seconds
		[NEURON] Running with 8 took :  1.860000 seconds
		[CoreNEURON] Running with 1 took :  7.57756 seconds
		[CoreNEURON] Running with 2 took :  3.84595 seconds
		[CoreNEURON] Running with 4 took :  2.26981 seconds
		[CoreNEURON] Running with 8 took :  1.50669 seconds
    ```

    For olfactory bulb test:

    ```
    → docker run -i -t neuron-icei:latest /bin/bash -i -c 'cd $HOME/manual/run && bash olfactory-bulb.sh'
        [NEURON] Running with 1 rank took :  13.950000 seconds
        [NEURON] Running with 2 rank took :  6.910000 seconds
        [NEURON] Running with 4 rank took :  3.660000 seconds
        [NEURON] Running with 8 rank took :  2.080000 seconds
    ```

- To run via modules installed using Spack:
	Following modules are generated as part of build:

	```
	→ docker run -u kumbhar -it neuron-icei bash
	$ module av

		------------ /home/kumbhar/modules/spack/share/spack/modules/linux-ubuntu18.04-x86_64 ------------
		mvapich2/2.3                  neuronmodels/coretest         neuronmodels/ring-profile     tau/2.27.1
		neuron/develop                neuronmodels/coretest-profile neuronmodels/traub
		neuron/develop-profile        neuronmodels/ring             neuronmodels/traub-profile
	```

	You can run the tests as:

	```
	→ docker run -i -t neuron-icei:latest /bin/bash -i -c 'cd $HOME/modules/run && bash ring.sh'
	→ docker run -i -t neuron-icei:latest /bin/bash -i -c 'cd $HOME/modules/run && bash traub.sh'
	```

- To run TAU instrumented versions and generate profile, do:

	```
	→ docker run -i -t neuron-icei:latest /bin/bash -i -c 'cd $HOME/modules/run && bash ring.sh -profile'
	→ docker run -i -t neuron-icei:latest /bin/bash -i -c 'cd $HOME/modules/run && bash traub.sh -profile'
	```

	The tau profiles will be genrated inside `$HOME/modules/run`. For example,

	```
	→ docker run -i -t neuron-icei:latest bash
	→ cd $HOME/modules/run
	→ bash ring.sh -profile
	→ ls ring/*.xml
		ring/tau.cnrn.1.xml  ring/tau.cnrn.4.xml  ring/tau.nrn.1.xml  ring/tau.nrn.4.xml
		ring/tau.cnrn.2.xml  ring/tau.cnrn.8.xml  ring/tau.nrn.2.xml  ring/tau.nrn.8.xml
	```

- Todos:
	-  	Add information about optimized builds [e.g. Intel/Cray/PGI compiler is required for vectorisation of CoreNEURON kernels)
	-  Add information about model parameters for production run
	-  Add information about validation of results
	-  Add information about PGI+OpenACC build of CoreNEURON (add current constraints / WIP)
