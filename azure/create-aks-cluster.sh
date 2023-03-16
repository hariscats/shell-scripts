#!/bin/bash
# create-aks-vnet-acr.sh

# Get details of subscription
az account show -o table

# Get list of subscriptions for logged in account
az account list -o table

# Set a subscription to be the current active subscription.
az account set -s 'REPLACE_WITH_SUBSCRIPTION_NAME'
 
# Set values for variables
rgName='aks-demos' #'aks-solution'
aksName='hcats-cluster'
location='EastUS'
vmSku='Standard_D2_v3'

# Create a resource group
az group create -l $location -n $rgName #--subscription $appSubId
 
# Azure Container Registry
# set this to the name of your Azure Container Registry.  It must be globally unique
acrName=hcatsben #name is global
# Note: acr in enterprise rg in Enterprise subscription
az acr create --name $acrName --resource-group $rgName -l $location --sku Basic
acrResourceId=$(az acr show --name $acrName --resource-group $rgName --query "id" --output tsv)
az acr update -n $acrName --admin-enabled true
acr_userName=$(az acr credential show -n $acrName --query="username" -o tsv)
acr_pwd=$(az acr credential show -n $acrName --query="passwords[0].value" -o tsv)
echo $acr_userName $acr_pwd
 
# Create vnet and subnet
az network vnet create -g $rgName -n aksVnet  -l $location --address-prefix 10.1.0.0/24 \
    --subnet-name akssubnet --subnet-prefix 10.1.0.0/25
subnetId=$(az network vnet subnet show --resource-group $rgName --vnet-name aksVnet --name akssubnet --query id -o tsv)
echo $subnetId
 
# Existing subnets
az network vnet subnet list --resource-group $rgName --vnet-name aksVnet -o tsv
subnetId=$(az network vnet subnet show --resource-group $rgName --vnet-name aksVnet --name akssubnet --query id -o tsv)
# VM SKUS 
az vm list-skus --location $location -o table
# versions
az aks get-versions --location $location --output table

# Provision cluster
az aks create --resource-group $rgName --name $aksName \
    --kubernetes-version 1.25.5 \
    --location $location \
    --node-vm-size $vmSku \
    --vm-set-type VirtualMachineScaleSets \
    --node-osdisk-size 30 \
    --node-count 1 --max-pods 30 \
    --network-plugin azure \
    --vnet-subnet-id $subnetId \
    --load-balancer-sku Basic \
    --generate-ssh-keys \
    --enable-cluster-autoscaler --min-count 1 --max-count 5 \
    --enable-aad \
    --enable-managed-identity \
    --attach-acr $acrResourceId
    #--enable-addons monitoring --workspace-resource-id $logWorkspaceResourceId 
 
# Side Notes
# Standard_D2_v3 2vCpu 8GB Ram, not premium storage
# Networking config options: --service-cidr 10.2.0.0/24 --dns-service-ip 10.2.0.10 --docker-bridge-address 172.17.0.1/16 \

# Obtain credentials for kubectl
az aks get-credentials -n $aksName -g $rgName
 
 # Verify cluster is running
az aks show  -n $aksName -g $rgName

# Stop an aks cluster
az aks stop -n $aksName -g $rgName
