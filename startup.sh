#!/bin/bash

RESGROUP=AuktionsHusetRG
GATEWAYNAME=goauctionsAppGateway

echo "Starting Azure container groups ..."

az container start --name auktionsHusetServicesGroup --resource-group $RESGROUP
az container start --name auktionsHusetBackendGroup --resource-group $RESGROUP
az container start --name auktionsHusetDevOpsGroup --resource-group $RESGROUP

echo "Starting Azure Application Gateway ..."

az network application-gateway start -g $RESGROUP -n $GATEWAYNAME
