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
tunnel_pid=$(ps -x | grep ssh | grep ${dashboard_port_local} | awk '{print $1}')
rm-f /tmp/${dashboard_port_local}.port.used

# Create tunnel cancel script
echo '#!/bin/bash' > cancel.sh

cat >> ${session_sh} <<HERE
kill ${tunnel_pid}
kill $$
kill \$(ps -x | grep ${job_name}  | awk '{print \$1}')
HERE

chmod +x cancel.sh

# Run Dask
python main.py --job_name ${job_name}

# Clean tunnel
kill ${tunnel_pid}

