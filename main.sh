#!/bin/bash

# Use the resource wrapper
source /etc/profile.d/parallelworks.sh
source /etc/profile.d/parallelworks-env.sh
source /pw/.miniconda3/etc/profile.d/conda.sh
conda activate
python3 /swift-pw-bin/utils/input_form_resource_wrapper.py 

# Load useful functions
source workflow-libs.sh

# Load resource inputs
source resources/slurm_controller/inputs.sh
# Port for dask dashboard
sed -i "s|.*PORT.*|    \"PORT\": \"${resource_ports}\",|" service.json
sed -i "s/.*JOB_STATUS.*/    \"JOB_STATUS\": \"Running\",/" service.json


# Run job on remote resource
cluster_rsync_exec