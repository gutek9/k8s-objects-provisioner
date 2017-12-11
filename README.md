# Provisioner for k8s objects:

## Prerequisities:

⋅ kubectl has to be mounted as volume into the path > /usr/bin/kubectl (no kubectl inside this image itself)

## Capabilities
  
⋅ provisions namespaces, deployments, secrets, configmaps
⋅ after secret or configmap change, object is recreated and kubectl patch is triggered on deployments which are using them. this triggers rolling update on these deployments  
⋅ secrets are not recreated after startup to avoid unnecessary rolling updates  
⋅ configmap are not recreated after startup to avoid unnecessary rolling updates  

## TBD

force-update
⋅ create all objects from repository

## Configuration:

### example definition is in deploy directory of this repository  

Configuration is I believe self explanatory  

- you need to create secret bb wich contains key id-rsa with wich you can checkout objects repository  
