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
SERIAL_CONF="$INSTALL_DIR/xela_serial.conf"

echo "--- Starting Xela Sensor Setup ---"

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
    
    # Locate the folder containing the binary
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

# 4. Multi-Device Hardware Detection (Serial Number Logic)
echo "Searching for devices with ID $TARGET_VID:$TARGET_PID..."
DEVICES=()
# Map TTY to Serial numbers using sysfs
for dev in /sys/bus/usb-serial/devices/*; do
    USB_PATH=$(readlink -f "$dev/../..")
    VID=$(cat "$USB_PATH/idVendor" 2>/dev/null)
    PID=$(cat "$USB_PATH/idProduct" 2>/dev/null)
    
    if [[ "$VID" == *"$TARGET_VID"* ]] && [[ "$PID" == *"$TARGET_PID"* ]]; then
        SERIAL=$(cat "$USB_PATH/serial" 2>/dev/null)
        TTY=$(basename "$dev")
        DEVICES+=("$TTY|$SERIAL")
    fi
done

USB_DEV=""
if [ ${#DEVICES[@]} -eq 0 ]; then
    echo "Error: No Xela hardware (0403:6015) found. Check connections."
    exit 1
elif [ ${#DEVICES[@]} -eq 1 ]; then
    USB_DEV=$(echo "${DEVICES[0]}" | cut -d'|' -f1)
    echo "One device found: $USB_DEV. Using it."
else
    echo "Multiple FTDI Bridges detected (Sensor vs Gripper Conflict)!"
    
    # Check if we have a saved preference
    if [ -f "$SERIAL_CONF" ]; then
        SAVED_SERIAL=$(cat "$SERIAL_CONF")
        for entry in "${DEVICES[@]}"; do
            if [[ "$entry" == *"$SAVED_SERIAL"* ]]; then
                USB_DEV=$(echo "$entry" | cut -d'|' -f1)
                echo "Matched saved Serial $SAVED_SERIAL to $USB_DEV."
                break
            fi
        done
    fi

    # Manual Selection if no saved preference matches
    if [ -z "$USB_DEV" ]; then
        echo "------------------------------------------------"
        echo "Please identify which device is the XELA SENSOR:"
        PS3="Select the index for Xela: "
        select choice in "${DEVICES[@]}"; do
            if [ -n "$choice" ]; then
                USB_DEV=$(echo "$choice" | cut -d'|' -f1)
                SELECTED_SERIAL=$(echo "$choice" | cut -d'|' -f2)
                echo "$SELECTED_SERIAL" > "$SERIAL_CONF"
                echo "Choice saved to $SERIAL_CONF."
                break
            else
                echo "Invalid selection."
            fi
        done
    fi
fi

DEVICE_PATH="/dev/$USB_DEV"
echo "Initializing Xela on: $DEVICE_PATH"

# 5. Bring up CAN Interface
echo "Initializing slcan0..."
modprobe slcan 2>/dev/null
slcand -o -s8 -t hw -S 3000000 "$DEVICE_PATH"
sleep 2 
ifconfig slcan0 up
# Fix for Error 105 (Buffer space)
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
echo "Server Running (PID: $SERVER_PID). Use example.py to read data."
