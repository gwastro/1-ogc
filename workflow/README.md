# Instructions for generating the 1-OGC catalog on the Open Science Grid

**Alexander H. Nitz<sup>1,2</sup>, Collin Capano<sup>1,2</sup>, Alex B. Nielsen<sup>1,2</sup>, Steven Reyes<sup>3</sup>, Rebecca White<sup>4,3</sup>, Duncan A. Brown<sup>3</sup>, Badri Krishnan<sup>1,2</sup>**

 <sub>1.[Albert-Einstein-Institut, Max-Planck-Institut for Gravitationsphysik, D-30167 Hannover, Germany](http://www.aei.mpg.de/obs-rel-cos)</sub>  
 <sub>2.Leibniz Universitat Hannover, D-30167 Hannover, Germany</sub>  
 <sub>3. Department of Physics, Syracuse University, Syracuse, NY 13244, USA</sub>  
 <sub>4. Fayetteville-Manlius High School, Manlius, NY 13104, USA</sub>  

This directory contains the scripts and configuration files necessary to reproduce the 1-OGC catalog using public data and code using the [Open Science Grid](). To use these instructions, you will need an [OSG Connect](https://support.opensciencegrid.org/support/solutions/articles/5000632072-registration-and-login-for-osg-connect) account.

## Set up environment

Once you have obtained an account on [OSG Connect](https://support.opensciencegrid.org/support/solutions/articles/5000632072-registration-and-login-for-osg-connect), you should log in to the machine `login.osgconnect.net`.

### StashCache

The workflow uses [StashCache](https://support.opensciencegrid.org/support/solutions/articles/12000002775-transferring-data-with-stashcache) to transfer data, so load the software into your environment with the command:
```sh
module load stashcache/5.1.2-py2.7
```
Note that StashCache uses [SciTokens](https://scitokens.org/) for authentication, so there is no need to obtain an X509 grid certificate to run the workflow.

### Python Virtual Environment

StashCache sets up your environment with the OSG Connect build of Python, so you will need to install the [pip](https://pip.pypa.io/en/stable/) and [virtualenv](https://virtualenv.pypa.io/en/latest/) packages to create a virtual environment to install [PyCBC](https://pycbc.org/).

First install pip with the commands
```sh
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py --user
SAVE_PATH=$PATH
SAVE_PYTHONPATH=$PYTHONPATH
export PATH=${HOME}/.local/bin:${PATH}
export PYTHONPATH=${HOME}/.local/lib/python2.7/site-packages:${PYTHONPATH}
```
We save the old valus of `PATH` and `PYTHONPATH` so that we can restore them after creating the virtual environment.

Next install virtualenv with the commands
```sh
pip install --user virtualenv
```

Finally, create a virtual environment to install PyCBC with the commands:
```sh
virtualenv ~/pycbc-opengw
PATH=${SAVE_PATH}
PYTHONPATH=${SAVE_PYTHONPATH}
source ~/pycbc-opengw/bin/activate
```

### PyCBC: 

Install PyCBC into the virtual environment by running the commands:
```sh
pip install -e git+https://github.com/gwastro/pycbc.git@refs/pull/2414/head#egg=PyCBC
pip install lalsuite==6.48.1.dev20180717
pip install -r ~/pycbc-opengw/src/pycbc/requirements.txt
```

###  Pegasus WMS

The workflow is planned by [Pegasus WMS](https://pegasus.isi.edu). You will need a pre-release version of Pegasus to use the new Singularity container features. Enable this by running the command:
```sh
export PATH=/stash/user/dbrown/public/pegasus-4.9.1dev/bin:${PATH}
```

## Create and plan the workflow

The script `generate_workflow_osgconnect.sh` can be used to create and plan the workflow. Analyze one of the nine analysis segments of data, run the script with the command with the number of the segment that you want to analyze, for example:
```sh
./generate_workflow_osgconnect.sh --analysis-segment 1
```
The workflow is created in the directory `/stash/user/${USER}/o1-open-catalog/analysis/analysis-N`, where `N` is the analysis segment number. The result pages will be created in `/stash/user/$USER/public/o1-open-catalog/results/analysis-N`.

This script performs several actions:
1. It creates directories for the workflow and result pages.
2. It runs [pycbc_make_coinc_search_workflow](http://pycbc.org/pycbc/latest/html/workflow/pycbc_make_coinc_search_workflow.html) to create the analysis workflow.
3. It runs ppycbc_submit_dax](http://pycbc.org/pycbc/latest/html/workflow/pycbc_make_coinc_search_workflow.html#planning-and-submitting-the-workflow) to plan the workflow using the [Pegasus WMS](https://pegasus.isi.edu).
4. It submits the planned workflow to [HTCondor](https://research.cs.wisc.edu/htcondor/) for execution.

When the workflow is planned and submitted, you will see a message like
```
2018.11.05 21:07:11.244 CST:   Your workflow has been started and is running in the base directory: 
2018.11.05 21:07:11.249 CST:    
2018.11.05 21:07:11.254 CST:     /local-scratch/dbrown/workflows/pycbc-tmp.PyyyqHqm3r/work 
2018.11.05 21:07:11.259 CST:    
2018.11.05 21:07:11.265 CST:   *** To monitor the workflow you can run *** 
2018.11.05 21:07:11.270 CST:    
2018.11.05 21:07:11.275 CST:     pegasus-status -l /local-scratch/dbrown/workflows/pycbc-tmp.PyyyqHqm3r/work 
2018.11.05 21:07:11.280 CST:    
2018.11.05 21:07:11.285 CST:   *** To remove your workflow run *** 
2018.11.05 21:07:11.291 CST:    
2018.11.05 21:07:11.296 CST:     pegasus-remove /local-scratch/dbrown/workflows/pycbc-tmp.PyyyqHqm3r/work 
2018.11.05 21:07:11.301 CST:    
2018.11.05 21:07:11.616 CST:   Time taken to execute is 11.379 seconds 

Querying Pegasus database for workflow stored in /local-scratch/dbrown/workflows/pycbc-tmp.PyyyqHqm3r/work
This may take up to 120 seconds. Please wait.................. Done.
Workflow submission completed successfully.

The Pegasus dashboard URL for this workflow is:
  https://login03.osgconnect.net/pegasus/u/dbrown/r/3/w?wf_uuid=eb5db678-9246-423d-8b1f-07ed145bed95

Note that it make take a while for the dashboard entry to appear while the workflow
is parsed by the dashboard. The delay can be on the order of one hour for very large
workflows.
```

Note that Pegasus Dashboard is not available on the OSG Connect head node, so the dashboard URL printed will not work. You can check the status of the workflow by running `pegasus-status` as shown by the messages printed when the job is submitted, e.g.
```sh
pegasus-status -l /local-scratch/dbrown/workflows/pycbc-tmp.PyyyqHqm3r/work 
```

## Acknowledgments ##
We thank Thomas Dent and Sumit Kumar for useful discussions and comments. We thank Stuart Anderson, Jonah Kannah, and Alan Weinstein for help accessing data from the Gravitational-Wave Open Science Center.  We acknowledge the Max Planck Gesellschaft for support and the Atlas cluster computing team at AEI Hannover. Computations were also supported by Syracuse University and NSF award OAC-1541396. DAB acknowledges NSF awards PHY-1707954, OAC-1443047, and OAC-1738962 for support. SR acknowledges NSF award PHY-1707954 and OAC-1443047 for support. RW acknowledges NSF award OAC-1823378 for support. 
This research has made use of data, software and/or web tools obtained from the Gravitational Wave Open Science Center (https://www.gw-openscience.org), a service of LIGO Laboratory, the LIGO Scientific Collaboration and the Virgo Collaboration. LIGO is funded by the U.S. National Science Foundation. Virgo is funded by the French Centre National de Recherche Scientifique (CNRS), the Italian Istituto Nazionale della Fisica Nucleare (INFN) and the Dutch Nikhef, with contributions by Polish and Hungarian institutes.
