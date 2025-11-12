#!/bin/bash


function provisioning_comfy_ui() {

	COMFYUI_DIR="/app/ComfyUI"
	
	NODES=(
		"https://github.com/christophbossmann/ComfyUI_essentials"
		"https://github.com/Fannovel16/comfyui_controlnet_aux"
		"https://github.com/risunobushi/comfyUI_FrequencySeparation_RGB-HSV"
		"https://github.com/cubiq/ComfyUI_IPAdapter_plus"
		"https://github.com/storyicon/comfyui_segment_anything"
		"https://github.com/TJ16th/comfyUI_TJ_NormalLighting"
		"https://github.com/ALatentPlace/ComfyUI_yanc"
		"https://github.com/sipherxyz/comfyui-art-venture"
		"https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
		"https://github.com/kijai/ComfyUI-IC-Light"
		"https://github.com/spacepxl/ComfyUI-Image-Filters"
		"https://github.com/ltdrdata/ComfyUI-Impact-Pack"
		"https://github.com/kijai/ComfyUI-KJNodes"
		"https://github.com/aria1th/ComfyUI-LogicUtils"
		"https://github.com/Smirnov75/ComfyUI-mxToolkit"
		"https://github.com/EllangoK/ComfyUI-post-processing-nodes"
		"https://github.com/807502278/ComfyUI-WJNodes"
		"https://github.com/palant/image-resize-comfyui"
		"https://github.com/rgthree/rgthree-comfy"
		"https://github.com/WASasquatch/was-node-suite-comfyui"
		"https://github.com/ltdrdata/ComfyUI-Manager"

	)

	WORKFLOWS=(

	)

	CHECKPOINT_MODELS=(
		"https://civitai.com/api/download/models/798204?type=Model&format=SafeTensor&size=full&fp=fp16"
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/checkpoints/absolutereality_v181.safetensors"
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/checkpoints/dreamshaper_8.safetensors"
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/checkpoints/epicrealism_naturalSinRC1VAE.safetensors"
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/checkpoints/juggernautXL_ragnarokBy.safetensors"
	)

	UNET_MODELS=(
	)

	LORA_MODELS=(
	)

	VAE_MODELS=(
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/vae/ae.safetensors"
	)

	ESRGAN_MODELS=(
	)

	CONTROLNET_MODELS=(
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/controlnet/control_v11f1p_sd15_depth_fp16.safetensors"
	)

	SAMS_MODELS=(
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/sams/sam_vit_l_0b3195.pth"
	)

	CLIP_MODELS=(
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/clip/clip_l.safetensors"
	)

	LAMA_MODELS=(
		"https://bytehaven.bossbach.christophbossmann.com/protected/comfyui/lama/big-lama.pt"
	)
	
	echo "######################################"
	echo "### Start provisioning for ComfyUI ###"
	echo "######################################"
    echo
	echo "Current time: $(date)"
	echo
	
	provisioning_get_nodes
    provisioning_git_clone \
        "${COMFYUI_DIR}/custom_nodes/ComfyUI_essentials/luts" \
        "https://github.com/bossbachcraftroom/comfyui_luts" \
        "${GITHUB_TOKEN}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/checkpoints" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/sams" \
        "${SAMS_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/clip" \
        "${CLIP_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/lama" \
        "${LAMA_MODELS[@]}"
    
	echo "#########################################"
	echo "### Provisioning finished for ComfyUI ###"
	echo "#########################################"
	echo
	echo "### Current time: $(date)"
	echo
	
}


function provisioning_get_nodes() {
    echo "Delete existing ComfyUI_essentials plugin.."
    rm -rf "${COMFYUI_DIR}/custom_nodes/ComfyUI_essentials"

    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                   pip install --no-cache-dir -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip install --no-cache-dir -r "${requirements}"
            fi
        fi
    done
}


function provisioning_git_clone() {
    local dest_path="$1"
    local repo_url="$2"
    local token="$3"

    printf "Syncing %s into %s...\n" "$repo_url" "$dest_path"

    # Remove non-git folder if it exists
    if [ -d "$dest_path" ] && [ ! -d "$dest_path/.git" ]; then
        echo "Existing non-git directory detected, removing..."
        rm -rf "$dest_path"
    fi

    mkdir -p "$dest_path" || {
        echo "Failed to create directory: $dest_path" >&2
        return 1
    }

    if [ -d "$dest_path/.git" ]; then
        printf "Already cloned, pulling latest changes...\n"
        git -C "$dest_path" pull --rebase
    else
        if [ -n "$token" ]; then
            echo "Using provided token for secure clone..."
            git -c credential.helper="!f() { echo username=git; echo password=$token; }; f" \
                clone "$repo_url" "$dest_path"
        else
            echo "No token provided, clone without authentication..."
            git clone "$repo_url" "$dest_path"
        fi
    fi
}


function provisioning_get_files() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    echo "Current time: $(date)"
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif 
        [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        auth_token="$CIVITAI_TOKEN"
    elif [[ -n $CUSTOM_TOKEN ]];then
        auth_token="$CUSTOM_TOKEN"
    fi
    echo "auth token: $auth_token"
    if [[ -n $auth_token ]];then
        echo "Provision Download WITH TOKEN"
        wget --header="Authorization: Bearer $auth_token" -nc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    else
        echo "Provision Download WITHOUT TOKEN"
        wget -nc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    fi
    echo "Current time: $(date)"
}

### start script ###

set -e

echo "********************************************"
echo "*** Running MY CUSTOM ENTRY POINT SCRIPT ***"
echo "********************************************"
echo

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

# Start jupiter
echo "[INFO] Starting Jupyter..."
cd /workspace
export JUPYTER_TOKEN="${MY_JUPYTER_TOKEN}"
#echo "Jupyter Token: $JUPYTER_TOKEN"
nohup jupyter lab --ip=0.0.0.0 --allow-root --no-browser --allow-root --notebook-dir=/ > /var/log/jupyter.log 2>&1 &
JUPYTER_PID=$!

provisioning_comfy_ui

# --- Start ComfyUI in background ---
echo "[INFO] Starting ComfyUI..."
cd /app/ComfyUI
nohup python3 main.py --listen 0.0.0.0 > /var/log/comfyui.log 2>&1 &
COMFYUI_PID=$!


echo "[INFO] Starting image-upload-api..."
cd /app/upload-image-api
exec python -m uvicorn app:app --host 0.0.0.0 --port 3001

# Start jupiter
#echo "[INFO] Starting Jupyter..."
#cd /workspace
#export JUPYTER_TOKEN="${MY_JUPYTER_TOKEN}"
#echo "Jupyter Token: $JUPYTER_TOKEN"
#exec jupyter lab --ip=0.0.0.0 --allow-root --no-browser --allow-root --notebook-dir=/
