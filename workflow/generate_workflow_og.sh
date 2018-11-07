#!/bin/bash

# the analysis block number
# analysis 0 is ER8A data which is not analyzed
# analysis 1 is ER8B data and O1 data which contains GW150914
# O1 analysis starts with block number 1
n=""

# data type is either LOSC_4_V1 or LOSC_16_V1
DATA_TYPE="LOSC_16_V1"

# version of pycbc to use
PYCBC_TAG="latest"

# do not submit the workflow
NO_PLAN=""

# do not submit the workflow
NO_SUBMIT=""

# generate test workflow
TEST_WORKFLOW=""

GETOPT_CMD=`getopt -o a:d:p:thnN --long analysis-segment:,data-type:,pycbc-tag:,test-workflow,help,no-submit,no-plan -n 'generate_workflow.sh' -- "$@"`
eval set -- "$GETOPT_CMD"

while true ; do
  case "$1" in
    -a|--analysis-segment)
      case "$2" in
        "") shift 2 ;;
        *) n=$2 ; shift 2 ;;
      esac ;;
    -d|--data-type)
      case "$2" in
        "") shift 2 ;;
        *) DATA_TYPE=$2 ; shift 2 ;;
      esac ;;
    -p|--pycbc-tag)
      case "$2" in
        "") shift 2 ;;
        *) PYCBC_TAG=$2 ; shift 2 ;;
      esac ;;
    -t|--test-workflow) TEST_WORKFLOW='yes' ; shift ;;
    -n|--no-submit) NO_SUBMIT='--no-submit' ; shift ;;
    -N|--no-plan) NO_PLAN='yes' ; shift ;;
    -h|--help)
      echo "usage: ${0} [-h] [-n] (-a N|-t) [-d DATA_TYPE] [-p PYCBC_TAG] -g GITHUB_TOKEN"
      echo
      echo "either one of the follow two arguments must be given:"
      echo "  -a, --analysis-segment  analysis segment number to run [1-9]"
      echo "  -t, --test-workflow     generate a small test workflow"
      echo 
      echo "optional arguments:"
      echo "  -d, --data-type         type of data to analyze [LOSC_16_V1]"
      echo "  -p, --pycbc-tag         valid tag of PyCBC to use [latest]"
      echo "  -h, --help              show this help message and exit"
      echo "  -N, --no-plan           exit after generating the workflow"
      echo "  -n, --no-submit         exit after generating and planning the workflow"
      echo
      exit 0 ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

if [  "x${TEST_WORKFLOW}" == "xyes" ]; then
  if [ "x${n}" == "x" ]; then
    n="test"
  else
    echo "Error: cannot give both --analysis-segment and --test-workflow."
    echo "Use --help for options."
    exit 1
  fi
else
  if [ "x${n}" == "x" ]; then
    echo "Error: one of --analysis-segment or --test-workflow must"
    echo "be specified. Use --help for options."
    exit 1
  fi
fi

if [ "x${DATA_TYPE}" == "x" ]; then
  echo "Error: --data-type must be specified. Use --help for options."
  exit 1
fi

if [ "x${PYCBC_TAG}" == "x" ]; then
  echo "Error: --pycbc-tag must be specified. Use --help for options."
  exit 1
fi

echo "Generating workflow for analysis ${n} using ${DATA_TYPE} data and PyCBC ${PYCBC_TAG}"

# locations of analysis directory and results directory
UNIQUE_ID=`uuidgen`
PROJECT_PATH=${HOME}/projects/1-ogc/analysis/analysis-${n}/${UNIQUE_ID}
WEB_PATH=${HOME}/projects/1-ogc/results/analysis-${n}/${UNIQUE_ID}

set -e

# use PyCBC from CVMFS
source ${HOME}/pycbc-opengw/bin/activate

WORKFLOW_NAME=o1-analysis-${n}-${PYCBC_TAG}-${DATA_TYPE}
OUTPUT_PATH=${WEB_PATH}/${WORKFLOW_NAME}
WORKFLOW_TITLE="'O1 Analysis ${n} ${DATA_TYPE}'"
WORKFLOW_SUBTITLE="'PyCBC Open GW Analysis'"

if [ -d ${PROJECT_PATH}/$WORKFLOW_NAME ] ; then
  echo "${PROJECT_PATH}/$WORKFLOW_NAME already exists"
  echo "Do you want to remove this directory or skip to the next block? Type remove or skip"
  read RESPONSE
  if test x$RESPONSE == xremove ; then
    echo "Are you sure you want to remove ${WORKFLOW_NAME}?"
    echo "Type remove to delete ${PROJECT_PATH}/$WORKFLOW_NAME or anything else to exit"
    read REMOVE
    if test x$REMOVE == xremove ; then
      rm -rf ${PROJECT_PATH}/$WORKFLOW_NAME
    else
      echo "You did not type remove. Exiting"
      exit 1
    fi
  elif test x$RESPONSE == xskip ; then
    exit 0
  else
    echo "Error: unknown response $RESPONSE"
    exit 1
  fi
fi
mkdir -p ${PROJECT_PATH}/$WORKFLOW_NAME
pushd ${PROJECT_PATH}/$WORKFLOW_NAME

export LIGO_DATAFIND_SERVER=sugwg-condor.phy.syr.edu:80

if [ "x${TEST_WORKFLOW}" == "xyes" ] ; then
  CONFIG_OVERRIDES="workflow:start-time:1128466607 workflow:end-time:1128486607 workflow-tmpltbank:tmpltbank-pregenerated-bank:https://github.com/gwastro/1-ogc/raw/master/workflow/auxiliary_files/H1L1-WORKFLOW_TEST_BANK-1163174417-604800.xml.gz workflow-splittable-full_data:splittable-num-banks:2"
else
   CONFIG_OVERRIDES=""
fi

pycbc_make_coinc_search_workflow \
--workflow-name ${WORKFLOW_NAME} --output-dir output \
--config-files \
  https://github.com/gwastro/1-ogc/raw/master/workflow/configuration/analysis.ini \
  https://github.com/gwastro/1-ogc/raw/master/workflow/configuration/losc_data.ini \
  https://github.com/gwastro/1-ogc/raw/master/workflow/configuration/gps_times_O1_analysis_${n}.ini \
  https://github.com/gwastro/1-ogc/raw/master/workflow/configuration/executables.ini \
  https://github.com/gwastro/1-ogc/raw/master/workflow/configuration/plotting.ini \
--config-overrides ${CONFIG_OVERRIDES} \
  "results_page:output-path:${OUTPUT_PATH}" \
  "results_page:analysis-title:${WORKFLOW_TITLE}" \
  "results_page:analysis-subtitle:${WORKFLOW_SUBTITLE}" \
  "workflow-segments:segments-veto-definer-url:https://github.com/gwastro/1-ogc/raw/master/workflow/auxiliary_files/H1L1-DUMMY_O1_CBC_VDEF-1126051217-1220400.xml" \
  "coinc:statistic-files:http://stash.osgconnect.net/~dbrown/1-ogc/workflow/auxiliary_files/dtime-dphase-stat.hdf" \
  "pegasus_profile-inspiral:container|type:singularity" \
  "pegasus_profile-inspiral:container|image:file://localhost/cvmfs/singularity.opensciencegrid.org/pycbc/pycbc-el7:latest" \
  "pegasus_profile-inspiral:container|image_site:orangegrid" \
  "pegasus_profile-inspiral:container|mount:/cvmfs:/cvmfs:ro" \
  "pegasus_profile-inspiral:condor|request_memory:2400" \
  "pegasus_profile-inspiral:pycbc|site:orangegrid" \
  "pegasus_profile-inspiral:hints|execution.site:orangegrid" \
  "workflow-${WORKFLOW_NAME}-main:staging-site:orangegrid=local" \
  "optimal_snr:cores:24"

pushd output


if [ "x${NO_PLAN}" == "x" ] ; then
  pycbc_submit_dax \
    --dax ${WORKFLOW_NAME}.dax \
    --execution-sites orangegrid \
    --no-create-proxy \
    --local-staging-server gsiftp://`hostname -f` \
    --remote-staging-server gsiftp://`hostname -f` \
    --append-pegasus-property 'pegasus.transfer.bypass.input.staging=true' \
    --append-site-profile 'local:condor|requirements:((MY.JobUniverse == 7) || (MY.JobUniverse == 12) || (TARGET.CpuModelNumber == 44))' \
    --append-site-profile 'local:env|LAL_DATA_PATH:/cvmfs/oasis.opensciencegrid.org/ligo/sw/pycbc/lalsuite-extra/e02dab8c/share/lalsimulation' \
    --append-site-profile 'orangegrid:condor|requirements:(TARGET.vm_name is "ITS-C6-OSG-20160824") || (TARGET.vm_name is "its-u18-nfs-20181019")' \
    --append-site-profile 'orangegrid:condor|+vm_name:"its-u18-nfs-20181019"' \
    --append-site-profile 'orangegrid:env|LAL_DATA_PATH:/cvmfs/oasis.opensciencegrid.org/ligo/sw/pycbc/lalsuite-extra/e02dab8c/share/lalsimulation' \
    --force-no-accounting-group ${NO_SUBMIT}

fi

popd
popd

echo
echo "Workflow created in ${PROJECT_PATH}/${WORKFLOW_NAME}"
echo "Results will be availale in ${OUTPUT_PATH}"
echo
