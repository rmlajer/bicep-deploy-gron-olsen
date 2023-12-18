#!/bin/bash

az login
az account set --subscription 69871a8a-fe89-416a-aa8e-e2bd525fd3ce

ResourceGroup=AuktionsHusetRG

az group create --name $ResourceGroup --location eastus

az deployment group create --resource-group $ResourceGroup --template-file auctionsGO.bicep --verbose
az resource list --resource-group $ResourceGroup

