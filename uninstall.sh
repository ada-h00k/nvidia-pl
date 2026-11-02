#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only
# Removes the nvidia-pl systemd service.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: please run as root (e.g. sudo $0)" >&2
    exit 1
fi

systemctl disable --now nvidia-pl.service 2>/dev/null || true
rm -f /etc/systemd/system/nvidia-pl.service /etc/default/nvidia-pl
systemctl daemon-reload

echo "nvidia-pl removed. The GPU power limit stays active until the next reboot or until you change it manually."
