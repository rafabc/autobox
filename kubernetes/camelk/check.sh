#!/bin/bash


function check_camelk() {

    clear
    NAMESPACE="camel-k"

    msg_task "Checking $NAMESPACE Status"
    echo

    POD_NAME="camel-k-operator"
    # SERVICE_NAME="active-mq"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    # check_svc_status $NAMESPACE $SERVICE_NAME
    # echo


    msg "Check Integration Platforms status"
    integration_platforms=$(kubectl get integrationplatforms -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    for platform in $integration_platforms; do
        STATUS=$(kubectl get integrationplatform $platform -n $NAMESPACE -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Ready" ]; then
            msg_check_success "La plataforma de integracion $platform esta lista y en estado: $STATUS"
        else
            msg_check_fail "La plataforma de integracion $platform no esta lista. Estado actual: $STATUS"
        fi
    done

    msg "Check Integration Kits status"
    integration_kits=$(kubectl get ik -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    for kit in $integration_kits; do
        STATUS=$(kubectl get integrationkit $kit -n $NAMESPACE -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Ready" ]; then
            msg_check_success "El Integrationkit $kit esta lista y en estado: $STATUS"
        fi
        if [ "$STATUS" == "Build Running" ]; then
            msg_info "El Integrationkit $kit esta en estado: $STATUS"
        fi
        if [ "$STATUS" == "Build Submitted" ]; then
            msg_info "El Integrationkit $kit esta en estado: $STATUS"
        fi
        if [ "$STATUS" == "Error" ]; then
            msg_check_fail "El Integrationkit $kit no esta lista. Estado actual: $STATUS"
            XERROR=$(kubectl get integrationkit $kit -n $NAMESPACE -o jsonpath='{.status.failure.reason}')
            msg_info_idented "$XERROR"
            msg_info_idented "Check error with this command: kubectl get integrationkit $kit -n $NAMESPACE -o json"

            if [[ $XERROR == *"$failure while building project"* ]]; then

                CAMELOPERATOR=$(kubectl get pods | grep camel-k-operator | awk '{print $1}')
                LOG=$(kubectl logs $CAMELOPERATOR | grep "camel-k.maven.build" | grep -A60 $kit | grep -m1 -A6 "BUILD FAILURE" | sed -E 's/(\\")//g' | tr -d '\n' | sed 's/\\//g') #  | jq 'del(.stacktrace)' | sed -E 's/(\\")//g' | sed 's/\\//g'  #| sed -E 's/("msg":")([^"]*)(")/\1\2\3/g'
                if [ "$VERBOSE" = true ]; then
                    msg_info_idented "log info"
                    echo
                    echo "$LOG" | jq -r .msg
                fi
            fi
        fi
    done

    msg "Check Integrations status"
    integrations=$(kubectl get integrations -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    for int in $integrations; do
        STATUS=$(kubectl get integration $int -n $NAMESPACE -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "La integracion $int esta lista y en estado: $STATUS"
        else
            if [ "$STATUS" == "Building Kit" ]; then
                msg_info "Integracion $int en fase de construccion"
            fi
            if [ "$STATUS" == "Deploying" ]; then
                msg_info "Integracion $int en fase de despliegue"
            fi
            if [ "$STATUS" == "Error" ]; then
                msg_check_fail "La integracion $int ha fallado. Estado actual: $STATUS"
                msg_info_idented "Checking conditions"
                conditions=$(kubectl get integrations $int -n $NAMESPACE -o jsonpath='{.status.conditions}')

                num_elements=$(echo "$conditions" | jq length)

                for ((i = 1; i <= num_elements; i++)); do
                    condition=$(echo "$conditions" | jq ".[$i-1]")
                    status=$(echo "$condition" | jq -r '.status')
                    type=$(echo "$condition" | jq -r '.type')
                    message=$(echo "$condition" | jq -r '.message')

                    if [ "$status" == "True" ]; then
                        msg_check_success_idented "Condition $type OK"
                    else
                        msg_check_fail_idented "Condition $type KO $status $message"
                    fi

                done
            fi
            if [ "$STATUS" != "Deploying" ] && [ "$STATUS" != "Error" ] && [ "$STATUS" != "Building Kit" ]; then
                msg_info "Estado no analizado: $STATUS"
            fi
        fi
    done

    

}   