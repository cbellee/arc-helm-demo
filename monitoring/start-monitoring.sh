SUBSCRIPTION_ID=$(az account show --query id -o tsv)
ARC_RESOURCE_GROUP="azure-arc-config-rg"
ARC_CLUSTER_NAME="azure-arc-aks-engine"
WORKSPACE_NAME="azure-aks-engine-law"
KUBE_CONTEXT="azure-aks-engine"

ARC_CLUSTER_RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${ARC_RESOURCE_GROUP}/providers/Microsoft.Kubernetes/connectedClusters/${ARC_CLUSTER_NAME}"
LOG_ANALYTICS_RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourcegroups/${ARC_RESOURCE_GROUP}/providers/microsoft.operationalinsights/workspaces/${WORKSPACE_NAME}"

bash ./enable-monitoring.sh \
    --resource-id $ARC_CLUSTER_RESOURCE_ID \
    --kube-context $KUBE_CONTEXT \
    --workspace-id $LOG_ANALYTICS_RESOURCE_ID
