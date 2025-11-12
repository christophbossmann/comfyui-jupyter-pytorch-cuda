#FROM nvcr.io/nvidia/pytorch:24.09-py3
FROM pytorch/pytorch:2.7.0-cuda12.8-cudnn9-runtime

# Install dependencies
RUN apt-get update && apt-get install -y \
    git wget ffmpeg libgl1 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Install ComfyUI in /app
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

#Install other packages
RUN apt update && apt install -y jq curl wget

# Install Jupyter (or JupyterLab)
RUN pip install jupyterlab  # or just 'jupyter' if you prefer the classic one

# Install Tailscale (for userspace mode)
RUN curl -fsSL https://tailscale.com/install.sh | sh

RUN pip install fastapi uvicorn python-multipart

COPY upload-image-api /app/upload-image-api

WORKDIR /

# Copy entrypoint script for dynamic customization
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY entrypoint_default.sh /entrypoint_default.sh
RUN chmod +x /entrypoint_default.sh

ENTRYPOINT ["/entrypoint.sh"]

# docker run -it --rm --gpus all -e JUPYTER_TOKEN=myfixedtoken -e TS_HOSTNAME=hostname -e TS_TAILNET=tailscale-email -e TS_APIKEY=tskey-api-XXXXXX -e TS_AUTHKEY=tailscale-authkey -p 8188:8188 -p 8888:8888 -p 3001:3001 comfyui-local