#!/bin/bash
set -e

echo  "[INFO] Running default entry point logic" 

# Optional: GPU info check
python3 - <<'EOF'
import torch
if torch.cuda.is_available():
    print(f"GPU available: True, device: {torch.cuda.get_device_name(0)}")
else:
    print("GPU available: False, using CPU")
EOF


# --- Optional: Remove existing device with same hostname before start tailscale ---
if [[ -n "$TS_APIKEY" && -n "$TS_TAILNET" && -n "$TS_HOSTNAME" ]]; then
    echo "[INFO] Checking for existing Tailscale device '$TS_HOSTNAME'..."
    DEVICES_JSON=$(curl -s -H "Authorization: Bearer $TS_APIKEY" \
        "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/devices")
    #echo "DEVICES JSON: ${DEVICES_JSON}"

    DEVICE_ID=$(echo "$DEVICES_JSON" | jq -r --arg h "$TS_HOSTNAME" '.devices[] | select(.hostname == $h) | .id')
    echo "DEVICE ID: ${DEVICE_ID}"

    if [[ -n "$DEVICE_ID" ]]; then
        echo "[INFO] Removing existing Tailscale device with ID $DEVICE_ID..."
        curl -s -X DELETE -H "Authorization: Bearer $TS_APIKEY" \
            "https://api.tailscale.com/api/v2/device/$DEVICE_ID"
        sleep 3
    else
        echo "[INFO] No existing device with hostname '$TS_HOSTNAME' found."
    fi
else "[INFO] TS_APIKEY, TS_TAILNET or TS_HOSTNAME not provided, skip check for existing devices in tailscale network."
fi

# --- Optional: Start Tailscale in userspace mode ---
if [[ -n "$TS_AUTHKEY" && -n "$TS_HOSTNAME" ]]; then
    echo "[INFO] Starting Tailscale in userspace mode..."
    mkdir -p /var/lib/tailscale
    mkdir -p /tmp/tailscale

    tailscaled --state=/var/lib/tailscale/tailscaled.state \
               --socket=/tmp/tailscaled.sock \
               --tun=userspace-networking &
    sleep 2

    echo "[INFO] Logging into Tailscale network as '$TS_HOSTNAME'..."
    tailscale --socket=/tmp/tailscaled.sock up \
        --authkey="${TS_AUTHKEY}" \
        --hostname="${TS_HOSTNAME}" \
        --ssh --accept-routes --accept-dns=false

    echo "[INFO] Tailscale IPs:"
    tailscale --socket=/tmp/tailscaled.sock ip -4 || true
else
    echo "[INFO] Skipping Tailscale — no auth key or hostname provided."
fi

# --- Start ComfyUI in background ---
echo "[INFO] Starting ComfyUI..."
cd /app/ComfyUI
nohup python3 main.py --listen 0.0.0.0 > /var/log/comfyui.log 2>&1 &
COMFYUI_PID=$!

# Start jupiter
echo "[INFO] Starting Jupyter..."
cd /workspace
export JUPYTER_TOKEN="${MY_JUPYTER_TOKEN}"
echo "Jupyter Token: $JUPYTER_TOKEN"
nohup jupyter lab --ip=0.0.0.0 --allow-root --no-browser --allow-root --notebook-dir=/ > /var/log/jupyter.log 2>&1 &
JUPYTER_PID=$!

echo "[INFO] Starting image-upload-api..."
cd /app/upload-image-api
exec python -m uvicorn app:app --host 0.0.0.0 --port 3001

# Start jupiter
#echo "[INFO] Starting Jupyter..."
#cd /workspace
#export JUPYTER_TOKEN="${MY_JUPYTER_TOKEN}"
#echo "Jupyter Token: $JUPYTER_TOKEN"
#exec jupyter lab --ip=0.0.0.0 --allow-root --no-browser --allow-root --notebook-dir=/
