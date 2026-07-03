#!/bin/bash

function install_solace() {

    NAMESPACE="solace"
    create_resources "solace.yml" $NAMESPACE
    
    msg "Waiting for Solace pods to be running..."
    wait_pod_running "solace"
    msg "Waiting for Solace Discovery Agent pod to be running..."
    wait_pod_running "solace-discovery-agent"


    #Port forwarding SOLACE
    port_forward "8088" "8080" solace
    port_forward "8008" "8008" solace
    port_forward "9000" "9000" solace
    port_forward "1443" "1443" solace
    port_forward "5555" "55555" solace
    msg_ok "Solace broker installed successfully"
    sleep 2


    #INSTALL SOLACE SCHEMA REGISTRY
    # cd solace-schema-registry
    # create_resources "solace-schema-registry.yml" $NAMESPACE
    # msg "Waiting for Solace Schema Registry pods to be running..."
    # wait_pod_running "solace-schema-registry"

    # #Port forwarding SOLACE SCHEMA REGISTRY
    # port_forward "8080" "8080" schema-registry-ui
    # port_forward "8081" "8081" schema-registry
    # port_forward "3000" "3000" idp
    # msg_ok "Solace schema registry installed successfully"
    # sleep 2

    #INSTALL SOLACE PUBSUB MONITOR
    cd solace-pubsub-monitor
    create_resources "solace-pubsub-monitor.yml" $NAMESPACE
    msg "Waiting for Solace PubSub Monitor pods to be running..."
    wait_pod_running "solace-pubsub-monitor"

    port_forward "8068" "8068" solace-pubsub-monitor
    port_forward "8080" "8080" solace-pubsub-monitor
    port_forward "4178" "4178" solace-pubsub-monitor
    port_forward "9102" "9102" solace-pubsub-monitor
    port_forward "7271" "7271" solace-pubsub-monitor


    msg_ok "Solace installed successfully"

}
