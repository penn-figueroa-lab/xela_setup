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
XELA_SERIAL="D30BL366" # Embedded serial for your Xela Sensor

echo "--- Starting Xela Sensor Setup (Target Serial: $XELA_SERIAL) ---"

# 2. Reset existing interfaces and kill old processes
echo "Resetting interfaces and killing old processes..."
ip link set slcan0 down 2>/dev/null
pkill slcand 2>/dev/null
pkill xela_server 2>/dev/null
sleep 1

# 3. Installation Logic (Download/Extract/Move)
if [ -f "$INSTALL_DIR/xela_server" ]; then
    echo "Software already installed in $INSTALL_DIR. Skipping download."
else
    echo "Installation not found. Proceeding with download..."
    if [ ! -f "$TAR_FILE" ]; then
        echo "Downloading Xela software..."
        wget -O "$TAR_FILE" "$DOWNLOAD_URL"
    fi

    echo "Extracting and installing files to $INSTALL_DIR..."
    mkdir -p ./xela_temp_extract
    tar -xf "$TAR_FILE" -C ./xela_temp_extract
    
    SRC_DIR=$(find ./xela_temp_extract -name "xela_server" -printf '%h\n' | head -n 1)
    
    if [ -z "$SRC_DIR" ]; then
        echo "Error: Could not find software files in archive."
        exit 1
    fi

    mkdir -p "$INSTALL_DIR"
    chmod 777 "$INSTALL_DIR"
    cp -rn "$SRC_DIR"/* "$INSTALL_DIR/"
    rm -rf ./xela_temp_extract
    echo "Software installed to $INSTALL_DIR."
fi

# 4. Hardware Detection (Hardcoded Serial Logic)
echo "Searching for Xela Sensor with Serial: $XELA_SERIAL..."
USB_DEV=""

# Loop through USB serial devices to find the matching serial number
for dev in /sys/bus/usb-serial/devices/*; do
    USB_PATH=$(readlink -f "$dev/../..")
    FOUND_SERIAL=$(cat "$USB_PATH/serial" 2>/dev/null)
    
    if [ "$FOUND_SERIAL" == "$XELA_SERIAL" ]; then
        USB_DEV=$(basename "$dev")
        echo "Match found! Sensor $XELA_SERIAL is at /dev/$USB_DEV"
        break
    fi
done

if [ -z "$USB_DEV" ]; then
    echo "Error: Sensor $XELA_SERIAL not detected. Is it plugged in?"
    echo "Current connected FTDI devices:"
    lsusb -d 0403:6015
    exit 1
fi

DEVICE_PATH="/dev/$USB_DEV"

# 5. Bring up CAN Interface
echo "Initializing slcan0 on $DEVICE_PATH..."
modprobe slcan 2>/dev/null
slcand -o -s8 -t hw -S 3000000 "$DEVICE_PATH"
sleep 2 
ifconfig slcan0 up
ifconfig slcan0 txqueuelen 1000 
sleep 1

# 6. Configuration & Startup
cd "$INSTALL_DIR"
echo "Configuring sensors..."
echo "y" | ./xela_conf -d socketcan -c slcan0

echo "Starting Xela Server..."
nohup ./xela_server > xela_server_log.txt 2>&1 &
SERVER_PID=$!

echo "--- Setup Complete ---"
echo "Server Running (PID: $SERVER_PID). Ready for example.py."
