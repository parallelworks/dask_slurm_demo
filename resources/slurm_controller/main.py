import os, json

import dask.array as da  # Import Dask
from dask.distributed import Client
from dask_jobqueue import SLURMCluster

with open('inputs.json') as inputs_json:
    form_inputs = json.load(inputs_json)

     
# Define SLURM cluster configuration
cluster = SLURMCluster(
    queue = form_inputs['partition'],
    cores = int(form_inputs['cores_per_job']),  # Number of CPU cores per job
    memory = form_inputs['memory_per_job'],  # Memory per job
    header_skip = ['--mem'], # Adding this argument allows Dask to ignore the memory parameter
    scheduler_options= {
        'dashboard_address': ':' + os.environ['dashboard_port_local']
    }
)

# Scale the cluster to a desired number of workers
cluster.adapt(
    minimum = int(form_inputs['minimum_jobs']), 
    maximum = int(form_inputs['maximum_jobs'])
)

# Connect a Dask client to the cluster
client = Client(cluster)

# Define a simple Dask computation (e.g., parallelized addition)
def add(a, b):
    return a + b

# Create Dask arrays for your computation
x = da.ones(100000000, chunks=10000)
y = da.ones(100000000, chunks=10000)

# Perform the computation using Dask
result = add(x, y).sum()

# Compute the result and retrieve the value
result_value = result.compute()

# Print the result
print("Result:", result_value)

# Close the Dask client and cluster when done
client.close()
cluster.close()
