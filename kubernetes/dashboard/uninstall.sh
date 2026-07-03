#!/bin/bash


function uninstall_kubernetes_dashboard() {

    NAMESPACE="kubernetes-dashboard"
    delete_resources $NAMESPACE kubernetes-dashboard.yml
    echo
    delete_namespace $NAMESPACE || echo "Namespace finalizer process not found"

    delete_port_forward kubernetes-dashboard
    echo
    msg_ok "Kubernetes Dashboard uninstalled successfully"

}
