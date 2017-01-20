#Provisioner for k8s objects:

##Capabilities
a) generic type  
⋅ designed for objects which are declarative and kubernetes can run rolling update on them  
⋅ run kubectl apply on changed objects  
⋅ ideal for deployments  
⋅ ideal for "one time creation" objects like svc  

b)  secrets type  
⋅ designed for secrets  
⋅ after secret change, secret is recreated and kubectl patch is triggered on deployments which are using them. this triggers rolling update on these deployments  
⋅ secrets are not recreated after startup to avoid unnecessary rolling updates  

c) configmap type  
⋅ designed for configmaps  
⋅ after configmaps change, configmap is recreated and pods which are using this configmap are deleted  
⋅ configmap are not recreated after startup to avoid unnecessary rolling updates  

d) quota type  
⋅ designed for creating namespaces nad quotas  
⋅ after namespace/quota change kubectl apply is executed on changed file, to ensure proper state  


##Configuration:
###example definition is in deploy directory of this repository  
Configuration is i believe self explanatory  
- you need to create with wich you can checkout objects repository  
- provisioner types are:
    -  generic
    -  secrets  
    -  configmap
    -  quota



