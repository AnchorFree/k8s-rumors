k8s-rumors
============

### Description

`k8s-rumors` is a docker container with a simple bash script to 
watch for a k8s secret in a certain namespace, and upon changes, propagate these changes to a predefined set of namespaces.
It also watches namespace creation events, and when a new namespace gets created, and happens to be in the set of predefined
destination namespaces, the secret will be replicated to the new namespace.

`k8s-rumors` entrypoint, when started without arguments, will start a namespace watch loop.
To start a secret watch loop, you should run another `k8s-rumors` container, configured to pass
`secret` argument to the entrypoint. Here is a sample abstract for a helm chart:

```
containers:

- name: k8s-rumors-ns-watcher
  image: {{ .Values.image }}
...
- name: k8s-rumors-secret-watcher
  image: {{ .Values.image }}
  command:
  - /usr/local/bin/entrypoint.sh 
  - secret
...

```

### Configuration

Configuration is done via environment variables:

* **SECRET**  
The name of the secret to replicate.

* **ORIGIN_NAMESPACE**  
The name of the namespace where the secret lives

* **DEST_NAMESPACES**  
Space separated names of the namespaces where the secret should be propagated to.

* **PEM_PATCH**
If set to any value, `k8s-rumors` will patch the secret when replicating:
if there is no **tls.pem** field in the secret data, it will concatenate **tls.crt** and
**tls.key** fields, and put the result into **tls.pem** field.
