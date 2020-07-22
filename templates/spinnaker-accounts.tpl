if $HAL_COMMAND config provider kubernetes account get operations-production-eu-north-1-pet-cheetah; then
  PROVIDER_COMMAND='edit'
else
  PROVIDER_COMMAND='add'
fi

$HAL_COMMAND config provider kubernetes account $PROVIDER_COMMAND operations-production-eu-north-1-pet-cheetah --docker-registries dockerhub \
            --context operations-production-eu-north-1-pet-cheetah  \
            --kubeconfig-file /opt/kube/kubeconfig \
            --only-spinnaker-managed true \
            --omit-namespaces=kube-system,kube-public \
            --kinds=configmap \
            --provider-version v2
$HAL_COMMAND config deploy edit --account-name operations-production-eu-north-1-pet-cheetah --type distributed \
                       --location spinnaker
