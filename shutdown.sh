#!/bin/bash

RESGROUP=AuktionsHusetRG
GATEWAYNAME=goauctionsAppGateway

az container stop --name auktionsHusetServicesGroup --resource-group $RESGROUP
az container stop --name auktionsHusetBackendGroup --resource-group $RESGROUP
az container stop --name auktionsHusetDevOpsGroup --resource-group $RESGROUP
az network application-gateway stop -g $RESGROUP -n $GATEWAYNAME
