# nvidia-pl

A tiny systemd service that enables NVIDIA persistence mode and applies a GPU power limit on every boot.

It replaces the manual commands:

```bash
sudo nvidia-smi -pm ENABLED
sudo nvidia-smi -pl 160
```

Limiting the power draw of a GPU is a popular way to reduce heat, noise, and energy consumption at a small performance cost.

## Requirements

- Linux with systemd
- NVIDIA proprietary driver (`nvidia-smi` must be available)
- Root privileges for installation

## Installation

```bash
git clone https://github.com/<your-username>/nvidia-pl.git
cd nvidia-pl
sudo ./install.sh
```

To use a different power limit (in watts):

```bash
sudo ./install.sh -p 200
```

The installer will:

1. Locate `nvidia-smi` on your system
2. Install the service to `/etc/systemd/system/nvidia-pl.service`
3. Write the power limit to `/etc/default/nvidia-pl`
4. Enable the service and start it immediately

## Configuration

The power limit is stored in `/etc/default/nvidia-pl`:

```ini
POWER_LIMIT=160
```

To change it later:

```bash
sudo nano /etc/default/nvidia-pl
sudo systemctl restart nvidia-pl.service
```

Check the allowed range for your GPU with:

```bash
nvidia-smi -q -d POWER | grep -i "power limit"
```

Values outside the min/max range supported by your card will be rejected by the driver.

## Verify

```bash
systemctl status nvidia-pl.service
nvidia-smi -q -d POWER | grep -i "power limit"
```

## Multiple GPUs

By default the commands apply to all GPUs. To target a specific one, edit `/etc/systemd/system/nvidia-pl.service` and add `-i <index>` to the `nvidia-smi` calls, for example:

```ini
ExecStart=/usr/bin/nvidia-smi -i 0 -pl ${POWER_LIMIT}
```

Then run `sudo systemctl daemon-reload && sudo systemctl restart nvidia-pl.service`.

## Notes

- **Persistence mode:** If `nvidia-persistenced` already manages persistence mode on your system, the `-pm` command may print a warning. The service ignores this failure on purpose.
- **Suspend/hibernate:** The power limit can be reset after resuming from suspend or hibernate. If you notice this, re-run `sudo systemctl restart nvidia-pl.service` after resume, or add a systemd sleep hook.

## Uninstallation

```bash
sudo ./uninstall.sh
```

This removes the service and its config file. The currently active power limit remains until the next reboot.

## License

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0-only).
