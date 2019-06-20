SECRET_NAMESPACE="${SECRET_NAMESPACE:-secrets}"
SECRET_LABEL="${SECRET_LABEL:-rumored}"
SECRET_ANNOTATION="${SECRET_ANNOTATION:-rumors/namespaces}"
SECRET_PATCH_LABEL="${SECRET_PATCH_LABEL:-patch_secret}"

function common::run_hook() {

  if [[ ${1} == "--config" ]] ; then
    hook::config
  else
    hook::trigger
  fi

}

function kubectl::replace_or_create() {

  local object=$(cat)

  if ! kubectl get -f - <<< "${object}" >/dev/null 2>/dev/null; then
    kubectl create -f - <<< "${object}" >/dev/null
  else
    kubectl replace --force -f - <<< "${object}" >/dev/null
  fi

}

function secret::get_destination_namespaces() {

  local secret=${1}
  echo $(kubectl -n ${SECRET_NAMESPACE} get ${secret} -o json | jq -r ".metadata.annotations.\"${SECRET_ANNOTATION}\"" | tr ',' '\n')

}

function secret::replicate() {

  local secret=${1}; shift
  local namespace=${1}

  if $(kubectl get ns ${namespace} &>/dev/null); then

      kubectl -n ${SECRET_NAMESPACE} get ${secret} -o json | \
        jq -r "if .metadata.labels[\"${SECRET_PATCH_LABEL}\"] == \"pem\" then
                .data += {\"tls.pem\": ((.data[\"tls.crt\"] | @base64d )+(.data[\"tls.key\"]|@base64d)|@base64)}
               else
                .
               end | .metadata.namespace=\"${namespace}\" |
               .metadata |= with_entries(select([.key] | inside([\"name\", \"namespace\", \"labels\"])))" | kubectl::replace_or_create
  fi

}

function secret::sync_to_namespace() {

  local namespace=${1}
  for secret in $(kubectl -n ${SECRET_NAMESPACE} get secret -l ${SECRET_LABEL} -o name); do
      namespaces=$(secret::get_destination_namespaces ${secret})
      if [[ "${namespaces}" =~ ${namespace} ]]; then
        secret::replicate ${secret} ${namespace}
      fi
  done

}

function secret::sync_all() {

  for namespace in $(kubectl get ns -o name); do
    if [[ "${namespace##*/}" != "${SECRET_NAMESPACE}" ]]; then
        secret::sync_to_namespace ${namespace##*/}
    fi
  done

}
