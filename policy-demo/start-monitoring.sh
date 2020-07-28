azureArcClusterResourceId="/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/azure-arc-config-rg/providers/Microsoft.Kubernetes/connectedClusters/azure-arc-aks-engine"
kubeContext=azure-aks-engine
logAnalyticsWorkspaceResourceId="/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/azure-aks-engine-rg/providers/microsoft.operationalinsights/workspaces/azure-aks-engine-law"

bash ./enable-monitoring.sh \
    --resource-id $azureArcClusterResourceId \
    --kube-context $kubeContext \
    --workspace-id $logAnalyticsWorkspaceResourceId