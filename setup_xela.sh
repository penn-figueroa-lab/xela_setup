#!/bin/bash

# 1. Force Sudo
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (use sudo ./setup_xela.sh)"
  exit
fi

# Configuration
VERSION="1.8.0-208601"
TAR_FILE="linux_${VERSION}.tar.xz"
INSTALL_DIR="/etc/xela"
DOWNLOAD_URL="https://xela.lat-d5.com/download.php?version=${VERSION}-linux"
TARGET_VID="0403"
TARGET_PID="6015"

echo "--- Starting Xela Sensor Setup ---"

# 2. Kill existing processes to reset the USB port
echo "Resetting interfaces and killing old processes..."
ip link set slcan0 down 2>/dev/null
pkill slcand 2>/dev/null
pkill xela_server 2>/dev/null
sleep 1

# 3. Check if Installation is already done
if [ -f "$INSTALL_DIR/xela_server" ]; then
    echo "Software already installed in $INSTALL_DIR. Skipping download/extract."
else
    echo "Installation not found. Proceeding with download and setup..."
    
    # Download if archive is missing
    if [ ! -f "$TAR_FILE" ]; then
        echo "Downloading Xela software..."
        wget -O "$TAR_FILE" "$DOWNLOAD_URL"
    fi

    # Extract and Move
    echo "Extracting and installing files to $INSTALL_DIR..."
    mkdir -p ./xela_temp_extract
    tar -xf "$TAR_FILE" -C ./xela_temp_extract
    
    SRC_DIR=$(find ./xela_temp_extract -name "xela_server" -printf '%h\n' | head -n 1)
    
    if [ -z "$SRC_DIR" ]; then
        echo "Error: Could not find software files in archive."
        exit 1
    fi

    mkdir -p $INSTALL_DIR
    chmod 777 $INSTALL_DIR
    cp -rn "$SRC_DIR"/* $INSTALL_DIR/
    rm -rf ./xela_temp_extract
fi

# 4. Hardware Detection
echo "Searching for Xela Bridge (ID $TARGET_VID:$TARGET_PID)..."
USB_DEV=$(ls -l /sys/bus/usb-serial/devices/ 2>/dev/null | grep "$TARGET_VID" | awk '{print $9}')

if [ -z "$USB_DEV" ]; then
    USB_DEV=$(basename $(ls /dev/ttyUSB* | head -n 1) 2>/dev/null)
fi

if [ -z "$USB_DEV" ]; then
    echo "Error: Sensor hardware not detected. Please re-plug."
    exit 1
fi

DEVICE_PATH="/dev/$USB_DEV"
echo "Found sensor at: $DEVICE_PATH"

# 5. Bring up CAN Interface
echo "Initializing slcan0..."
modprobe slcan 2>/dev/null
slcand -o -s8 -t hw -S 3000000 "$DEVICE_PATH"
sleep 2 
ifconfig slcan0 up
ifconfig slcan0 txqueuelen 1000 
sleep 1

# 6. Configuration & Startup
cd $INSTALL_DIR
# Only run config if xServ.ini is missing, or force it to ensure correct port
echo "Configuring sensors..."
echo "y" | ./xela_conf -d socketcan -c slcan0

echo "Starting Xela Server..."
nohup ./xela_server > xela_server_log.txt 2>&1 &
SERVER_PID=$!

echo "--- Setup Complete ---"
echo "Server Running (PID: $SERVER_PID). Ready for example.py."
