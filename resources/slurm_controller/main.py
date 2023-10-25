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
)

# scheduler_options= {
#        'dashboard_address': '0.0.0.0:' + os.environ['dashboard_port_local']
#    }

# Scale the cluster to a desired number of workers
cluster.adapt(
    minimum = int(form_inputs['minimum_jobs']), 
    maximum = int(form_inputs['maximum_jobs'])
)

# Connect a Dask client to the cluster
client = Client(cluster)
# Generate a large random Dask array
shape = (1000000, 1000000)  # Large shape for a slow computation
chunks = (1000, 1000)     # Chunk size for parallelism
x = da.random.random(size=shape, chunks=chunks)

# Calculate the mean of the array
mean = x.mean()

# Compute the result and wait for it to finish
result = mean.compute()

# Print the result
print(f"Mean: {result}")

# Close the Dask client and cluster when done
client.close()
cluster.close()
