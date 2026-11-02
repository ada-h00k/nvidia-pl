#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only
# Installs the nvidia-pl systemd service.
# Usage: sudo ./install.sh [-p WATTS] [-h]
set -euo pipefail

POWER_LIMIT=160
SERVICE_NAME="nvidia-pl.service"
SERVICE_DEST="/etc/systemd/system/${SERVICE_NAME}"
CONFIG_DEST="/etc/default/nvidia-pl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<USAGE
Usage: sudo $0 [-p WATTS]

  -p WATTS   Power limit in watts (default: ${POWER_LIMIT})
  -h         Show this help
USAGE
}

while getopts ":p:h" opt; do
    case "$opt" in
        p) POWER_LIMIT="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "Error: please run as root (e.g. sudo $0)" >&2
    exit 1
fi

if ! [[ "$POWER_LIMIT" =~ ^[0-9]+$ ]]; then
    echo "Error: power limit must be a positive integer (watts)" >&2
    exit 1
fi

NVIDIA_SMI="$(command -v nvidia-smi || true)"
if [[ -z "$NVIDIA_SMI" ]]; then
    echo "Error: nvidia-smi not found. Is the NVIDIA driver installed?" >&2
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "Error: systemctl not found. This installer requires systemd." >&2
    exit 1
fi

echo "==> Using nvidia-smi at: ${NVIDIA_SMI}"
echo "==> Installing ${SERVICE_DEST}"
sed "s|@NVIDIA_SMI@|${NVIDIA_SMI}|g" "${SCRIPT_DIR}/nvidia-pl.service" > "$SERVICE_DEST"
chmod 644 "$SERVICE_DEST"

echo "==> Writing ${CONFIG_DEST} (POWER_LIMIT=${POWER_LIMIT})"
cat > "$CONFIG_DEST" <<CONF
# Power limit in watts, applied by nvidia-pl.service at boot
POWER_LIMIT=${POWER_LIMIT}
CONF
chmod 644 "$CONFIG_DEST"

echo "==> Enabling and starting ${SERVICE_NAME}"
systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

echo
echo "Done. Current status:"
systemctl --no-pager --lines=0 status "$SERVICE_NAME" || true
echo
"$NVIDIA_SMI" -q -d POWER | grep -i "power limit" || true
