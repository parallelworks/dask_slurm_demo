#!/bin/bash
source workflow-libs.sh

# Service port in the platform
service_port_pw=$1
# Service port in the worker node
service_port_worker=$2

#######################
# START NGINX WRAPPER #
#######################

nginx_port=$(findAvailablePort)
if [ -z "${nginx_port}" ]; then
    echo "ERROR: No available port was found for nginx wrapper"
    exit 1
fi

# Write config file
cat >> conf.d <<HERE
server {
 listen ${nginx_port};
 server_name _;
 index index.html index.htm index.php;
 add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
 add_header 'Access-Control-Allow-Headers' 'Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Mx-ReqToken,Keep-Alive,X-Requested-With,If-Modified-Since';
 add_header X-Frame-Options "ALLOWALL";
 location / {
     proxy_pass http://127.0.0.1:${service_port_worker}/me/${service_port_pw}/;
     proxy_http_version 1.1;
       proxy_set_header Upgrade \$http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_set_header X-Real-IP \$remote_addr;
       proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
       proxy_set_header Host \$http_host;
       proxy_set_header X-NginX-Proxy true;
 }
}
HERE


container_name="nginx-${nginx_port}"
# Remove container when job is canceled
echo "sudo docker stop ${container_name}" >> cancel.sh
# Start container
sudo docker run  -d --name ${container_name}  -v $PWD/conf:/etc/nginx/conf.d --network=host nginx
# This is a placeholder file to reserve the port before it is used
rm /tmp/${nginx_port}.port.used


#####################
# CREATE SSH TUNNEL #
#####################

ssh_cmd="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
${ssh_cmd} -fN -R 0.0.0.0:${service_port_pw}:localhost:${nginx_port} usercontainer
# Remove tunnel when job is canceled
tunnel_pid=$(ps -x | grep ssh | grep ${service_port_worker} | awk '{print $1}')
echo "kill ${tunnel_pid}" >> cancel.sh

