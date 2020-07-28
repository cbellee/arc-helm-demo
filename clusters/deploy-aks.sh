##############################################################
# pre-requisites
# 1. Create AKS Cluster
# 2. modify CLUSTER_RESOURCE_GROUP
# 3. modify CLUSTER_NAME

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
LOCATION=eastus
CLUSTER_RESOURCE_GROUP=azure-aks-rg
CLUSTER_NAME=azure-aks-aks
APP_ID=$(az aks show -g $CLUSTER_RESOURCE_GROUP -n $CLUSTER_NAME --query identityProfile.kubeletidentity.clientId -o tsv)
ARC_RESOURCE_GROUP=azure-arc-config-rg
ARC_CLUSTER_NAME=azure-arc-aks
NAMESPACE=arc-k8s-demo

################################
# register preview extensions
echo -e "\x1B[96m register preview extensions \x1B[0m"
az extension add --name connectedk8s
az extension add --name k8sconfiguration
    
echo -e "\x1B[96m register preview providers \x1B[0m"
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.PolicyInsights

echo -e "\x1B[96m display registration state \x1B[0m"
az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table

###########################
# create resource groups
echo -e "\x1B[96m create resource group to hold AKS-Engine cluster \x1B[0m"
az group create --location $LOCATION --name $CLUSTER_RESOURCE_GROUP

echo -e "\x1B[96m create resource group to hold arc configuration \x1B[0m"
az group create --location $LOCATION --name $ARC_RESOURCE_GROUP

###########################
# on-board cluster to arc
echo -e "\x1B[96m copy kubeconfig \x1B[0m"
az aks get-credentials -g $CLUSTER_RESOURCE_GROUP -n $CLUSTER_NAME --admin

echo -e "\x1B[96m connect cluster to Azure Arc \x1B[0m"
az connectedk8s connect --name $ARC_CLUSTER_NAME --resource-group $ARC_RESOURCE_GROUP

echo -e "\x1B[96m verify cluster connecion \x1B[0m"
az connectedk8s list -g $ARC_RESOURCE_GROUP -o table

###########################
# install NGINX controller
echo -e "\x1B[96m install NGINX ingress controller \x1B[0m"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install arc-demo ingress-nginx/ingress-nginx -n $NAMESPACE

###########################
# create gitops config
echo -e "\x1B[96m create gitops workload configuration \x1B[0m"
az k8sconfiguration create \
    --name azure-voting-app \
    --resource-group $CLUSTER_RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --operator-instance-name flux \
    --operator-namespace $NAMESPACE \
    --operator-params='--git-readonly --git-path=releases/aks' \
    --enable-helm-operator true \
    --helm-operator-version='0.6.0' \
    --helm-operator-params='--set helm.versions=v3' \
    --repository-url https://github.com/cbellee/arc-helm-demo.git  \
    --scope namespace \
    --cluster-type managedClusters # || connectedClusters for non-AKS

echo -e "\x1B[96m validate source control configuration \x1B[0m"
az k8sconfiguration show \
    --resource-group $CLUSTER_RESOURCE_GROUP \
    --name azure-voting-app \
    --cluster-name $CLUSTER_NAME \
    --cluster-type managedClusters

###########################
# verify ingress
echo -e "\x1B[96m test voting app \x1B[0m"
curl http://vote-app-aks.kainiindustries.net

###########################
# configure Azure policy
echo -e "\x1B[96m assign 'Policy Insights Data Writer (Preview)' role to cluster service principal \x1B[0m"
az role assignment create \
  --assignee $APP_ID \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}" \
  --role "Policy Insights Data Writer (Preview)"

echo -e "\x1B[96m install azure-policy add-on \x1B[0m"
helm repo add azure-policy https://raw.githubusercontent.com/Azure/azure-policy/master/extensions/policy-addon-kubernetes/helm-charts
helm install azure-policy-addon azure-policy/azure-policy-addon-aks-engine \
  --set azurepolicy.env.resourceid="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}"

echo -e "\x1B[96m azure-policy pod is installed in kube-system namespace \x1B[0m"
kubectl get pods -n kube-system

echo -e "\x1B[96m gatekeeper pod is installed in gatekeeper-system namespace \x1B[0m"
kubectl get pods -n gatekeeper-system

