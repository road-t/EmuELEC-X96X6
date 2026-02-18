#!/bin/bash
# Deploy VFD scripts to X96X6 over SSH without rebuilding image
#
# Usage: ./DEPLOY_VFD_SCRIPTS.sh root@192.168.1.XXX

if [ -z "$1" ]; then
    echo "Usage: $0 root@IP_ADDRESS"
    exit 1
fi

HOST="$1"
DEVICE_PATH="/storage/.vfd-scripts"
SRC_DIR="projects/Rockchip/devices/X96X6/filesystem/usr/lib"
BIN_DIR="projects/Rockchip/devices/X96X6/filesystem/usr/bin"
SERVICE_DIR="projects/Rockchip/devices/X96X6/filesystem/usr/lib/systemd/system"
SPLASH_SRC="packages/sx05re/emuelec/bin/show_splash.sh"

echo "=== Copying scripts to ${HOST}:${DEVICE_PATH} ==="
ssh "$HOST" "mkdir -p ${DEVICE_PATH}"
scp -r "${SRC_DIR}/emuelec/vfd-"*.sh "${HOST}:${DEVICE_PATH}/"
scp "${BIN_DIR}/vfd-send" "${HOST}:${DEVICE_PATH}/"
scp "${SPLASH_SRC}" "${HOST}:${DEVICE_PATH}/show_splash.sh"
ssh "$HOST" "chmod 755 ${DEVICE_PATH}/*.sh ${DEVICE_PATH}/vfd-send"
ssh "$HOST" "mkdir -p /storage/.config/system.d"
scp "${SERVICE_DIR}/vfd-"*.service "${HOST}:/storage/.config/system.d/"

echo ""
echo "=== Creating bind mounts over readonly filesystem ==="
ssh "$HOST" <<'REMOTE_SCRIPT'
set -e

# Bind mount scripts over readonly /usr/lib/emuelec/
for script in vfd-service.sh vfd-clock-updater.sh vfd-state-monitor.sh vfd-fd628.sh vfd-boot-anim.sh vfd-bye.sh vfd-timezone-setup.sh; do
    if [ -f "/storage/.vfd-scripts/$script" ]; then
        echo "Mounting /storage/.vfd-scripts/$script -> /usr/lib/emuelec/$script"
        mount --bind "/storage/.vfd-scripts/$script" "/usr/lib/emuelec/$script" 2>/dev/null || \
            { cp "/storage/.vfd-scripts/$script" "/usr/lib/emuelec/$script"; }
        chmod 755 "/usr/lib/emuelec/$script"
    fi
done

# Bind mount vfd-send command
if [ -f "/storage/.vfd-scripts/vfd-send" ]; then
    echo "Mounting vfd-send"
    mount --bind "/storage/.vfd-scripts/vfd-send" "/usr/bin/vfd-send" 2>/dev/null || \
        { cp "/storage/.vfd-scripts/vfd-send" "/usr/bin/vfd-send"; chmod 755 /usr/bin/vfd-send; }
fi

# Bind mount show_splash.sh
if [ -f "/storage/.vfd-scripts/show_splash.sh" ]; then
    echo "Mounting show_splash.sh"
    mount --bind "/storage/.vfd-scripts/show_splash.sh" "/usr/bin/show_splash.sh" 2>/dev/null || \
        { cp "/storage/.vfd-scripts/show_splash.sh" "/usr/bin/show_splash.sh"; chmod 755 /usr/bin/show_splash.sh; }
fi

# Bind mount service files over readonly /usr/lib/systemd/system/
for svc in vfd-x96x6.service; do
    if [ -f "/storage/.config/system.d/$svc" ]; then
        echo "Mounting /storage/.config/system.d/$svc -> /usr/lib/systemd/system/$svc"
        mount --bind "/storage/.config/system.d/$svc" "/usr/lib/systemd/system/$svc"
    fi
done

echo ""
echo "=== Restarting VFD services ==="
systemctl daemon-reload
systemctl stop vfd-x96x6.service 2>/dev/null || true
sleep 1
systemctl start vfd-x96x6.service

echo ""
echo "=== Status ==="
systemctl status vfd-x96x6.service --no-pager -l

echo ""
echo "=== Done! ==="
echo "Scripts are now running from /storage/.vfd-scripts/"
echo "Bind mounts will persist until reboot."
echo ""
echo "To make permanent: rebuild image and flash"
REMOTE_SCRIPT

echo ""
echo "=== Deploy complete ==="
echo "To undo bind mounts: ssh $HOST 'systemctl stop vfd-x96x6; reboot'"
