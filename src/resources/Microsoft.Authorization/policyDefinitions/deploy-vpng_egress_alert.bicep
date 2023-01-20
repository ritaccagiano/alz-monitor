// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'managementGroup'

param policyLocation string = 'centralus'
param deploymentRoleDefinitionIds array = [
    '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
]

@allowed([
    '0'
    '1'
    '2'
    '3'
    '4'
])
param parAlertSeverity string = '0'

@allowed([
    'PT1M'
    'PT5M'
    'PT15M'
    'PT30M'
    'PT1H'
    'PT6H'
    'PT12H'
    'P1D'
])
param parWindowSize string = 'PT5M'

@allowed([
    'PT1M'
    'PT5M'
    'PT15M'
    'PT30M'
    'PT1H'
])
param parEvaluationFrequency string = 'PT5M'

@allowed([
    'deployIfNotExists'
    'disabled'
])
param parPolicyEffect string = 'disabled'

param parThreshold string = '1'

module VpngEgressAlert '../../arm/Microsoft.Authorization/policyDefinitions/managementGroup/deploy.bicep' = {
    name: '${uniqueString(deployment().name)}-vpngtea-policyDefinitions'
    params: {
        name: 'Deploy_VPNGw_Egress_Alert'
        displayName: '[DINE] Deploy VPNG Egress Alert'
        description: 'DINE policy to audit/deploy VPN Gateway Egress Alert'
        location: policyLocation
        metadata: {
            version: '1.0.0'
            Category: 'Networking'
            source: 'https://github.com/Azure/ALZ-Monitor/'
        }
        parameters: {
            severity: {
                type: 'String'
                metadata: {
                    displayName: 'Severity'
                    description: 'Severity of the Alert'
                }
                allowedValues: [
                    '0'
                    '1'
                    '2'
                    '3'
                    '4'
                ]
                defaultValue: parAlertSeverity
            }
            windowSize: {
                type: 'String'
                metadata: {
                    displayName: 'Window Size'
                    description: 'Window size for the alert'
                }
                allowedValues: [
                    'PT1M'
                    'PT5M'
                    'PT15M'
                    'PT30M'
                    'PT1H'
                    'PT6H'
                    'PT12H'
                    'P1D'
                ]
                defaultValue: parWindowSize
            }
            evaluationFrequency: {
                type: 'String'
                metadata: {
                    displayName: 'Evaluation Frequency'
                    description: 'Evaluation frequency for the alert'
                }
                allowedValues: [
                    'PT1M'
                    'PT5M'
                    'PT15M'
                    'PT30M'
                    'PT1H'
                ]
                defaultValue: parEvaluationFrequency
            }
            threshold: {
                type: 'String'
                metadata: {
                    displayName: 'Threshold'
                    description: 'Threshold for the alert'
                }
                defaultValue: parThreshold
            }
            effect: {
                type: 'String'
                metadata: {
                    displayName: 'Effect'
                    description: 'Effect of the policy'
                }
                allowedValues: [
                    'deployIfNotExists'
                    'disabled'
                ]
                defaultValue: parPolicyEffect
            }
        }
        policyRule: {
            if: {
                allOf: [
                    {
                        field: 'type'
                        equals: 'microsoft.network/vpngateways'
                    }
                ]
            }
            then: {
                effect: '[parameters(\'effect\')]'
                details: {
                    roleDefinitionIds: deploymentRoleDefinitionIds
                    type: 'Microsoft.Insights/metricAlerts'
                    existenceCondition: {
                        allOf: [
                            {
                                field: 'Microsoft.Insights/metricAlerts/criteria.Microsoft-Azure-Monitor-SingleResourceMultipleMetricCriteria.allOf[*].metricNamespace'
                                equals: 'microsoft.network/vpngateways'
                            }
                            {
                                field: 'Microsoft.Insights/metricAlerts/criteria.Microsoft-Azure-Monitor-SingleResourceMultipleMetricCriteria.allOf[*].metricName'
                                equals: 'tunnelegressbytes'
                            }
                            {
                                field: 'Microsoft.Insights/metricalerts/scopes[*]'
                                equals: '[concat(subscription().id, \'/resourceGroups/\', resourceGroup().name, \'/providers/microsoft.network/vpngateways/\', field(\'fullName\'))]'
                            }
                        ]
                    }
                    deployment: {
                        properties: {
                            mode: 'incremental'
                            template: {
                                '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
                                contentVersion: '1.0.0.0'
                                parameters: {
                                    resourceName: {
                                        type: 'String'
                                        metadata: {
                                            displayName: 'resourceName'
                                            description: 'Name of the resource'
                                        }
                                    }
                                    resourceId: {
                                        type: 'String'
                                        metadata: {
                                            displayName: 'resourceId'
                                            description: 'Resource ID of the resource emitting the metric that will be used for the comparison'
                                        }
                                    }
                                    severity: {
                                        type: 'String'
                                    }
                                    windowSize: {
                                        type: 'String'
                                    }
                                    evaluationFrequency: {
                                        type: 'String'
                                    }
                                    threshold: {
                                        type: 'String'
                                    }
                                }
                                variables: {}
                                resources: [
                                    {
                                        type: 'Microsoft.Insights/metricAlerts'
                                        apiVersion: '2018-03-01'
                                        name: '[concat(parameters(\'resourceName\'), \'-TunnelEgressAlert\')]'
                                        location: 'global'
                                        properties: {
                                            description: 'Metric Alert for VPN Gateway tunnel egress bytes'
                                            severity: '[parameters(\'severity\')]'
                                            enabled: true
                                            scopes: [
                                                '[parameters(\'resourceId\')]'
                                            ]
                                            evaluationFrequency: '[parameters(\'evaluationFrequency\')]'
                                            windowSize: '[parameters(\'windowSize\')]'
                                            criteria: {
                                                allOf: [
                                                    {
                                                        name: 'tunnelegressbytes'
                                                        metricNamespace: 'microsoft.network/vpngateways'
                                                        metricName: 'tunnelegressbytes'
                                                        operator: 'LessThan'
                                                        threshold: '[parameters(\'threshold\')]'
                                                        timeAggregation: 'Total'
                                                        criterionType: 'StaticThresholdCriterion'
                                                    }
                                                ]
                                                'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
                                            }
                                            parameters: {
                                                severity: {
                                                    value: '[parameters(\'severity\')]'
                                                }
                                                windowSize: {
                                                    value: '[parameters(\'windowSize\')]'
                                                }
                                                evaluationFrequency: {
                                                    value: '[parameters(\'evaluationFrequency\')]'
                                                }
                                                threshold: {
                                                    value: '[parameters(\'threshold\')]'
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                            parameters: {
                                resourceName: {
                                    value: '[field(\'name\')]'
                                }
                                resourceId: {
                                    value: '[field(\'id\')]'
                                }
                                severity: {
                                    value: '[parameters(\'severity\')]'
                                }
                                windowSize: {
                                    value: '[parameters(\'windowSize\')]'
                                }
                                evaluationFrequency: {
                                    value: '[parameters(\'evaluationFrequency\')]'
                                }
                                threshold: {
                                    value: '[parameters(\'threshold\')]'
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
