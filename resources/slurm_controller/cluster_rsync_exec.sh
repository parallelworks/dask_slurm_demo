#!/bin/bash
jobdir=$(dirname $0)
cd ${jobdir}

source inputs.sh
source workflow-libs.sh

# Load or install conda environment
if [[ ${conda_install} == "true" ]]; then
    create_conda_env_from_yaml ${conda_dir} ${conda_env} conda_env.yaml
else
    eval ${load_env}
fi

# Create tunnnel for dask dashboard
dashboard_port_pw=${resource_ports}
export dashboard_port_local=$(findAvailablePort)

if [ -z "${dashboard_port_local}" ]; then
    echo "ERROR: No available port was found for Dask's dashboard"
    exit 1
fi

ssh_cmd="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
set -x
${ssh_cmd} -fN -R 0.0.0.0:${dashboard_port_pw}:localhost:${dashboard_port_local} usercontainer

# Run Dask
python main.py

