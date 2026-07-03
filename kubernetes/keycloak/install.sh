#!/usr/bin/env bash

function install_keycloak() {
	NAMESPACE="keycloak"
	create_resources "keycloak.yml" $NAMESPACE

	wait_pod_running "keycloak"

	port_forward "8765" "8080" keycloak
	msg_ok "Keycloak installed successfully"
}
