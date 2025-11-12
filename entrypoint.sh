#!/bin/bash
set -e

# Optional: verbose logging
echo "[INFO] Starting..."

DEFAULT_SCRIPT="/entrypoint_default.sh"
TMP_SCRIPT="/entrypoint_custom.sh"

# Check if ENTRYPOINT_URL is provided
if [[ -n "${ENTRYPOINT_URL:-}" ]]; then
  echo "[INFO] Custom entrypoint requested: $ENTRYPOINT_URL"

  # Try downloading with Bearer token if available
  if [[ -n "${ENTRYPOINT_BEARER_TOKEN:-}" ]]; then
    echo "[INFO] Using Bearer token..."
    curl -fsSL -H "Authorization: Bearer ${ENTRYPOINT_BEARER_TOKEN}" \
         -o "$TMP_SCRIPT" "$ENTRYPOINT_URL" || DOWNLOAD_FAILED=1
  else
    echo "[INFO] No token provided, trying public access..."
    curl -fsSL -o "$TMP_SCRIPT" "$ENTRYPOINT_URL" || DOWNLOAD_FAILED=1
  fi

  # If download succeeded and script is not empty
  if [[ -f "$TMP_SCRIPT" && -s "$TMP_SCRIPT" ]]; then
    echo "[INFO] Successfully downloaded custom entrypoint."
    chmod +x "$TMP_SCRIPT"
    echo "[INFO] Running CUSTOM ENTRYPOINT..."
    exec "$TMP_SCRIPT" "$@"
  else
    echo "[INFO] Download failed or script empty — using default."
  fi
  
else
  # Fallback to default entrypoint
  echo "[INFO] No ENTRYPOINT_URL provided. Fall back to running DEFAULT ENTRYPOINT..."
  exec "$DEFAULT_SCRIPT" "$@"
fi

