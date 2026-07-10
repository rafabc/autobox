# Waits for a Kubernetes pod to reach the "Running" state.
# Usage: wait_pod_running <namespace> <pod_name>
# Arguments:
#   pod_name  - The name of the pod to wait for.
# The function polls the pod status and waits until it is "Running".
function wait_pod_running() {
    POD_NAME=$1
    msg "WAITING POD RUNNING" "$POD_NAME"
    
    local MAX_RETRIES=5
    local RETRY_DELAY=10
    local COUNT=0
    local POD=""

    while [ $COUNT -lt $MAX_RETRIES ]; do
        POD=$(kubectl get pods -o name | grep "^pod/$POD_NAME" | head -1)
        
        if [ -n "$POD" ]; then
            msg_info "POD FOUND" "$POD_NAME found as $POD after $COUNT attempts with delay of ${RETRY_DELAY}s redy to check status"
            break
        fi
        
        COUNT=$((COUNT + 1))
        if [ $COUNT -lt $MAX_RETRIES ]; then
            msg_info "Pod $POD_NAME no encontrado. Reintento $COUNT de $MAX_RETRIES (esperando ${RETRY_DELAY}s)..."
            sleep $RETRY_DELAY
        fi
    done

    if [ -z "$POD" ]; then
        msg_error "No pod found for $POD_NAME after $MAX_RETRIES attempts"
        return 1
    fi

    if [ "$VERBOSE" -eq 1 ]; then
        kubectl get "$POD"
    fi

    READY=$(kubectl get "$POD" -o jsonpath='{.status.conditions[?(@.type=="ContainersReady")].status}')

    if [ "$READY" = "True" ]; then
        msg_check_success "POD READY" "$POD_NAME is in ContainersReady=True state" 
        return 0
    fi

    # kubectl wait --for=condition=ContainersReady "$POD" --timeout=3m &
    # spinner $! "Waiting for condition container ready in pod $POD_NAME"
    # WAIT_RC=$?
    
    # READY=$(kubectl get "$POD" -o jsonpath='{.status.conditions[?(@.type=="ContainersReady")].status}')

    # if [ "$WAIT_RC" -eq 0 ] && [ "$READY" = "True" ]; then
    #     STATE=$(kubectl get "$POD" -o jsonpath='{range .status.containerStatuses[*]} {range .state.waiting}{.reason}{end} {range .state.running}Running{end} {range .state.terminated}{.reason}{end} {end}')
    #     msg_check_success "POD READY STATE ->" "$STATE" "$POD_NAME is in ContainersReady=True state"
    #     return 0
    # else
    #     msg_info "Pod $POD_NAME failed to reach ready state within timeout. Current status:"
    #     msg_info_idented "Current READY status: $READY y WAIT_RC: $WAIT_RC"
    #     msg_check_fail "POD NOT READY" "$POD failed to reach ready state"
    #     kubectl get "$POD"
    #     return 1
    # fi

    local MAX_WAIT_RETRIES=3
    local WAIT_COUNT=0
    local WAIT_RC=1

    while [ $WAIT_COUNT -lt $MAX_WAIT_RETRIES ]; do
        WAIT_COUNT=$((WAIT_COUNT + 1))
        
        # Lanzamos el wait en segundo plano para el spinner
        kubectl wait --for=condition=ContainersReady "$POD" --timeout=3m &
        spinner $! "Waiting for condition container ready in pod $POD_NAME (Intento $WAIT_COUNT de $MAX_WAIT_RETRIES)"
        WAIT_RC=$?
        
        # Verificamos el estado real tras el wait
        READY=$(kubectl get "$POD" -o jsonpath='{.status.conditions[?(@.type=="ContainersReady")].status}')
        
        # Si ha ido bien y está en True, salimos del bucle
        if [ "$WAIT_RC" -eq 0 ] && [ "$READY" = "True" ]; then
            break
        fi
        
        # --- NUEVO: Chequeo de descarga de imágenes ---
        # Extraemos las razones por las que los contenedores puedan estar esperando
        WAITING_REASONS=$(kubectl get "$POD" -o jsonpath='{.status.containerStatuses[*].state.waiting.reason}')
        
        if echo "$WAITING_REASONS" | grep -E -q "ContainerCreating|ErrImagePull|ImagePullBackOff"; then
            # Si el estado es alguno de estos, lo más probable es que siga descargando o negociando con el Registry
            msg_info "Nota: El pod sigue en creación o descargando la imagen (Estado: $WAITING_REASONS)."
        fi
        # ---------------------------------------------
        
        if [ $WAIT_COUNT -lt $MAX_WAIT_RETRIES ]; then
            msg_info "El pod $POD_NAME no llegó a Ready en el intento $WAIT_COUNT. Reintentando espera..."
            sleep 5 
        fi
    done

    # Evaluation final fuera del bucle
    if [ "$WAIT_RC" -eq 0 ] && [ "$READY" = "True" ]; then
        STATE=$(kubectl get "$POD" -o jsonpath='{range .status.containerStatuses[*]} {range .state.waiting}{.reason}{end} {range .state.running}Running{end} {range .state.terminated}{.reason}{end} {end}')
        msg_check_success "POD READY STATE ->" "$STATE" "$POD_NAME is in ContainersReady=True state"
        return 0
    else
        msg_info "Pod $POD_NAME failed to reach ready state after $MAX_WAIT_RETRIES attempts. Current status:"
        msg_info_idented "Current READY status: $READY y WAIT_RC del último intento: $WAIT_RC"
        msg_check_fail "POD NOT READY" "$POD failed to reach ready state"
        kubectl get "$POD"
        return 1
    fi
    
}