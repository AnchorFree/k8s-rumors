k8s-rumors
============

### Description

`k8s-rumors` is a k8s operator to watch secrets in the `${SECRET_NAMESPACE}` which have `${SECRET_LABEL}`. 
Whenever such a secret is created or updated, `k8s-rumors` replicate the secret to the namespaces defined
in `${SECRET_ANNOTATION}` annotation of the secret. When the secret is deleted from the `${SECRET_NAMESPACE}`,
k8s-rumors deletes it from every namespace it has been replicated to.

`k8s-rumors` is based on [shell-operator](https://github.com/AnchorFree/shell-operator).

### Configuration

Configuration is done via environment variables:

* **SECRET_NAMESPACE**  
The namespace to watch for secret modifications. Default is **secrets**.

* **SECRET_LABEL**  
The label that a secret must have to be replicated. The label must be present,
but its' value is not important. Default is **rumored**.

* **SECRET_ANNOTATION**  
The annotation that defines destination namespaces. The value must be a string with comma separated
namespace names. Default is **rumors/namespaces**.

* **SECRET_PATCH_LABEL**  
If this label is present and its' value is set to "pem", than `k8s-rumors`
assumes that the secret is a SSL certificate with two data fields, `tls.crt` and `tls.key`,
and will patch the secret during replication to have another data field, `tls.pem`, which is
concatenation of the `tls.crt` and `tls.key` fields. Default is **patch_secret**.

### Getting started

* Create secrets namespace: `kubectl create ns secrets`
* Install `k8s-rumors` via [helm chart](helm/k8s-rumors) with default values.
* Create `ns1` namespace: `kubectl create ns ns1`
* Create a secret in the `secrets` namespace:
```
apiVersion: v1
metadata:
  name: sample-secret
  namespace: secrets
  annotations:
    rumors/namespaces: "ns1,ns2"
  labels:
    rumoured: "yes"
type: Opaque
kind: Secret
data:
  not-really-a-secret.txt: Uk1TIHdhcyByaWdodCEK
```
* Wait a couple of seconds and check that it was replicated to the `ns1`: `kubectl -n ns1 get secret sample-secret -o json`
* Create `ns2` namespace and check that the secret was replicated again: `kubectl create namespace ns2 && sleep 3 && kubectl -n ns2 get secret sample-secret -o json`

