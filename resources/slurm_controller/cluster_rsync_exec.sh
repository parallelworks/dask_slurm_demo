#!/bin/bash
jobdir=$(dirname $0)
cd ${jobdir}

# Initialize cancel script
echo '#!/bin/bash' > cancel.sh
chmod +x cancel.sh

source inputs.sh
source workflow-libs.sh

# Load or install conda environment
if [[ ${conda_install} == "true" ]]; then
    create_conda_env_from_yaml ${conda_dir} ${conda_env} conda_env.yaml
else
    eval ${load_env}
fi

# Get ports for dask dashboard
dashboard_port_pw=${resource_ports}
export dashboard_port_worker=$(findAvailablePort)

if [ -z "${dashboard_port_worker}" ]; then
    echo "ERROR: No available port was found for Dask's dashboard"
    exit 1
fi

# Start networking to display Dask dashboard in the PW platform
if sudo -n true 2>/dev/null; then
    # Need root access to forward dashboard to platform
    bash networking_wrapper.sh ${dashboard_port_pw} ${dashboard_port_worker}
else
    echo; echo "WARNING: DASHBOARD CANNOT CONNECT TO PW BECAUSE USER ${USER} DOES NOT HAVE SUDO PRIVILEGES"
fi

# Kill dask when job is canceled
cat >> cancel.sh <<HERE
kill $$
kill \$(ps -x | grep ${job_name}  | awk '{print \$1}')
rm /tmp/${dashboard_port_worker}.port.used
HERE

# Run Dask
python main.py --job_name ${job_name}

# Clean after job
./cancel.sh

