#!/bin/bash

function install_kubernetes_dashboard() {

    NAMESPACE="kubernetes-dashboard"
    create_resources "kubernetes-dashboard.yml" $NAMESPACE
    
    msg "Waiting for kubernetes-dashboard pods to be running..."
    wait_pod_running "kubernetes-dashboard"

    port_forward "9090" "9090" kubernetes-dashboard & disown

    msg_ok "Kubernetes Dashboard installed successfully"

}
