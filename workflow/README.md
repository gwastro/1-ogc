# Instructions for generating the 1-OGC catalog on the Open Science Grid

**Alexander H. Nitz<sup>1,2</sup>, Collin Capano<sup>1,2</sup>, Alex B. Nielsen<sup>1,2</sup>, Steven Reyes<sup>3</sup>, Rebecca White<sup>4,3</sup>, Duncan A. Brown<sup>3</sup>, Badri Krishnan<sup>1,2</sup>**

 <sub>1. [Albert-Einstein-Institut, Max-Planck-Institut for Gravitationsphysik, D-30167 Hannover, Germany](http://www.aei.mpg.de/obs-rel-cos)</sub>  
 <sub>2. Leibniz Universitat Hannover, D-30167 Hannover, Germany</sub>  
 <sub>3. Department of Physics, Syracuse University, Syracuse, NY 13244, USA</sub>  
 <sub>4. Fayetteville-Manlius High School, Manlius, NY 13104, USA</sub>  

This directory contains the scripts and configuration files necessary to reproduce the 1-OGC catalog using public data and code using the [Open Science Grid]().

The contents of this directory are:

 1. [A script for generating, planning, and running the workflow on the Open Science Grid](https://github.com/gwastro/1-ogc/blob/master/workflow/generate_workflow_osgconnect.sh)
 2. [A script for generating, planning, and running the workflow on Syracuse University's Orange Grid](https://github.com/gwastro/1-ogc/blob/master/workflow/generate_workflow_og.sh)
 3. [A script for generating, planning, and running the workflow on the AEI Atlas cluster](https://github.com/gwastro/1-ogc/blob/master/workflow/generate_workflow_atlas.sh)

The contents of the sub-directories are:

 1. A [veto definer file](https://github.com/gwastro/1-ogc/blob/master/workflow/auxiliary_files/H1L1-DUMMY_O1_CBC_VDEF-1126051217-1220400.xml) needed for the pipeline to process data quality information from LOSC].
 2. The [script](https://github.com/gwastro/1-ogc/blob/master/workflow/auxiliary_files/make-dtime-dphase-stat.sh) used to generate the data needed to incorporate the [time delay, and coalescence phase into the ranking of candidate events](https://arxiv.org/abs/1705.01513). You do not need to run this script as the [HDF5 file it generates](http://stash.osgconnect.net/~dbrown/1-ogc/workflow/auxiliary_files/dtime-dphase-stat.hdf) is available from online and is directly downloaded by the pipeline. This script is provided for reference.
 3. A [small template bank](https://github.com/gwastro/1-ogc/blob/master/workflow/auxiliary_files/H1L1-WORKFLOW_TEST_BANK-1163174417-604800.xml.gz) that can be used to test the workflow.
 4. A directory containing the [configuration files](https://github.com/gwastro/1-ogc/tree/master/workflow/configuration) used by the analysis.

## Obtain an OSG Connect account

To use these instructions, you will need to follow the [OSG Connect registration instructions](https://support.opensciencegrid.org/support/solutions/articles/5000632072-registration-and-login-for-osg-connect) to get an account. Once you are set up with an account, you can [set up your account for ssh access](https://support.opensciencegrid.org/support/solutions/articles/12000027675-generate-ssh-key-pair-and-add-the-public-key-to-your-account) so you can log into the submit host `login.osgconnect.net`. If you are not familiar with  may want to explore some of the tutorials in the [quickstart guide](https://support.opensciencegrid.org/support/solutions/articles/5000633410-osg-connect-quickstart) and [pegasus introduction](https://support.opensciencegrid.org/support/solutions/articles/5000639789-pegasus) before attempting to run this workflow.

## Obtain a grid certificate

You will need to obtain an X509 grid certificate to run this workflow. To do this, visit the [CILogon certificate service](https://cilogon.org/) and log in with your institutional identity. CILogon will generate a certificate file called `usercred.p12`, which you should download and copy to `login.osgconnect.net`. One you have the file there, place it in the appropriate directory with the commands:
```sh
mkdir -p ~/.globus
mv usercred.p12 ~/.globus
chmod 600 ~/.globus/usercred.p12
```
You should now be able to run the command
```sh
grid-proxy-init
```
to create an X509 proxy certificate that the workflow will use. Create this proxy certificate before continuing.


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
pip install pycbc==1.13.0
pip install lalsuite==6.48.1.dev20180717
pip install -r https://raw.githubusercontent.com/gwastro/pycbc/v1.13.0/requirements.txt
```

###  Pegasus WMS

The workflow is planned by [Pegasus WMS](https://pegasus.isi.edu). You will need a pre-release version of Pegasus to use the new Singularity container features. Enable this by running the command:
```sh
export PATH=/stash/user/dbrown/public/pegasus-4.9.1dev/bin:${PATH}
```

## Clone this repository

Clone this repository into your home directory (or another suitable location) on `login.osgconnect.org`. This can be any directory you like, *except* for directories under the PyCBC virtual environment you created. Use git to clone the respository and then change to the directory containing the clone with the commands
```sh
git clone https://github.com/gwastro/1-ogc.git
cd 1-ogc
```

## Create and plan the workflow

The script `generate_workflow_osgconnect.sh` can be used to create and plan the workflow. Analyze one of the nine analysis segments of data, run the script with the command with the number of the segment that you want to analyze, for example:
```sh
./workflow/generate_workflow_osgconnect.sh --analysis-segment 1
```
The workflow is created in the directory `/stash/user/${USER}/o1-open-catalog/analysis/analysis-N-UUID`, where `N` is the analysis segment number and `UUID` is a unique ID assigned by the workflow generation script. The result pages will be created in `/stash/user/$USER/public/o1-open-catalog/results/analysis-N-UUID`.

This script performs several actions:
1. It creates directories for the workflow and result pages.
2. It runs [pycbc_make_coinc_search_workflow](http://pycbc.org/pycbc/latest/html/workflow/pycbc_make_coinc_search_workflow.html) to create the analysis workflow.
3. It runs ppycbc_submit_dax](http://pycbc.org/pycbc/latest/html/workflow/pycbc_make_coinc_search_workflow.html#planning-and-submitting-the-workflow) to plan the workflow using the [Pegasus WMS](https://pegasus.isi.edu).
4. It submits the planned workflow to [HTCondor](https://research.cs.wisc.edu/htcondor/) for execution.

When the workflow is planned and submitted, you will see a message like
```
2018.11.07 17:08:28.529 CST:   Submitting to condor o1-analysis-1-v1_13_0-LOSC_16_V1-0.dag.condor.sub 
2018.11.07 17:08:31.231 CST:   Submitting job(s). 
2018.11.07 17:08:31.236 CST:   1 job(s) submitted to cluster 1037652. 
2018.11.07 17:08:31.241 CST:    
2018.11.07 17:08:31.247 CST:   Your workflow has been started and is running in the base directory: 
2018.11.07 17:08:31.252 CST:    
2018.11.07 17:08:31.257 CST:     /local-scratch/dbrown/workflows/pycbc-tmp.MF4haFwcCE/work 
2018.11.07 17:08:31.262 CST:    
2018.11.07 17:08:31.267 CST:   *** To monitor the workflow you can run *** 
2018.11.07 17:08:31.273 CST:    
2018.11.07 17:08:31.278 CST:     pegasus-status -l /local-scratch/dbrown/workflows/pycbc-tmp.MF4haFwcCE/work 
2018.11.07 17:08:31.283 CST:    
2018.11.07 17:08:31.289 CST:   *** To remove your workflow run *** 
2018.11.07 17:08:31.294 CST:    
2018.11.07 17:08:31.299 CST:     pegasus-remove /local-scratch/dbrown/workflows/pycbc-tmp.MF4haFwcCE/work 
2018.11.07 17:08:31.304 CST:    
2018.11.07 17:08:31.555 CST:   Time taken to execute is 38.112 seconds 

Querying Pegasus database for workflow stored in /local-scratch/dbrown/workflows/pycbc-tmp.MF4haFwcCE/work
This may take up to 120 seconds. Please wait........................ Done.
Workflow submission completed successfully.

The Pegasus dashboard URL for this workflow is:
  https://login03.osgconnect.net/pegasus/u/dbrown/r/16/w?wf_uuid=b0baeba1-625d-417a-b0ba-770802a33d07

Note that it make take a while for the dashboard entry to appear while the workflow
is parsed by the dashboard. The delay can be on the order of one hour for very large
workflows.

/stash/user/dbrown/1-ogc/analysis/analysis-1-ea19e064-7e57-4d18-9248-293c8bbc1132/o1-analysis-1-v1.13.0-LOSC_16_V1 ~/1-ogc
~/1-ogc

Workflow created in /stash/user/dbrown/1-ogc/analysis/analysis-1-ea19e064-7e57-4d18-9248-293c8bbc1132/o1-analysis-1-v1.13.0-LOSC_16_V1
Results will be availale in /stash/user/dbrown/public/1-ogc/results/analysis-1-ea19e064-7e57-4d18-9248-293c8bbc1132/o1-analysis-1-v1.13.0-LOSC_16_V1
```

Note that Pegasus Dashboard is not available on the OSG Connect head node, so the dashboard URL printed will not work. You can check the status of the workflow by running `pegasus-status` as shown by the messages printed when the job is submitted, e.g.
```sh
pegasus-status -l /local-scratch/dbrown/workflows/pycbc-tmp.MF4haFwcCE/work 
```

## Acknowledgments ##

We thank Brian Bockelman, Mike Brady, Edgar Fajardo Hernandez, Larne Pekowsky, Mats Rynge, Eric Sedore, Todd Tannenbaum, Karan Vahi, and Derek Weitzel for help with cyberinfrastructure. We thank Stuart Anderson, Jonah Kannah, and Alan Weinstein for help accessing data from the Gravitational-Wave Open Science Center. We thank Thomas Dent for helpful comments. This work is supported by NSF awards PHY-1707954, OAC-1443047, OAC-1541396, OAC-1738962, and OAC-1823378 and by the Max Planck Gesellschaft.

