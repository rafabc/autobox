#!/bin/bash


function check_activemq() {

    clear
    NAMESPACE="active-mq"

    msg_task "Checking $NAMESPACE Status"
    echo

    POD_NAME="active-mq"
    SERVICE_NAME="active-mq"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    check_svc_status $NAMESPACE $SERVICE_NAME
    echo
    

}   