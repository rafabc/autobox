#!/bin/bash

function install_karavan() {

    NAMESPACE="karavan"

    create_resources "karavan.yml" $NAMESPACE
    msg "Waiting for Karavan pods to be running..."
    wait_pod_running "karavan"

   # port_forward "8899" "80" karavan
	msg_ok "Karavan installed successfully running on http://localhost:30777"

}
