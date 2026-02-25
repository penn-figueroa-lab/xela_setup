# Xela Tactile Sensor Linux Setup & API

This repository provides an automated installation and data visualization suite for **Xela Robotics** tactile sensors (optimized for the **uSPa46 4x6** series) on Ubuntu. It handles hardware driver initialization, server management, and provides a generalizable Python API.

---

## 🛠 Features

* **Zero-Config Install:** Automatically handles software extraction and directory placement in `/etc/xela`.
* **Self-Healing Reset:** Forcefully clears "Busy" USB ports and resets `slcan` interfaces to prevent "No buffer space available" errors (Error 105).
* **Intelligent Installation:** Detects existing files in `/etc/xela` to skip redundant downloads and extractions.
* **Generalizable Data Hub:** The Python API automatically detects and scales to support any number of connected sensors.
* **Grid-Mapped Output:** Transforms raw 1D data lists into physical `[Row, Col, Axis]` arrays matching the sensor layout.

---

## 🚀 Quick Start

### 1. Hardware Setup
Connect your Xela tactile sensor via USB. The script specifically targets the FTDI Bridge (Hardware ID `0403:6015`).

### 2. Run Installation
Execute the setup script with `sudo` privileges. This script installs the software to `/etc/xela`, resets the CAN interface, and starts the Xela server.

```bash
chmod +x setup_xela.sh
sudo ./setup_xela.sh
```

### 3. Run Visualization
Monitor your sensor data in real-time with the provided Python example:
```bash
python3 example.py
```

---

## 📊 Data Mapping (uSPa46)
The `example.py` script transforms the raw WebSocket stream into a structured **NumPy array** with dimensions `(4, 6, 3)` for each sensor:



* **Grid Dimensions:** 4 Rows x 6 Columns.
* **Axes Mapping:**
    * `[..., 0]`: **X-axis** (Shear Force)
    * `[..., 1]`: **Y-axis** (Shear Force)
    * `[..., 2]`: **Z-axis** (Normal Force / Pressure)

---

## 🤖 Robot Operating System (ROS) Integration
`example.py` includes a commented-out **ROS 2** template at the bottom of the file. To use it:

1. **Dependencies:** Ensure `rclpy` is installed: `pip install rclpy`.
2. **Enable Code:** Uncomment the ROS section in `example.py`.
3. **Topics:** The node will dynamically create and publish each sensor's data as a `Float32MultiArray` to topics:
    * `/xela/sensor_1`
    * `/xela/sensor_2`
    * ... (automatically scales for any number of sensors)

---

## 📋 Dependencies
* **Operating System:** Ubuntu 20.04 / 22.04+
* **System Drivers:** `sudo apt install can-utils`
* **Python Libraries:** `pip install numpy websocket-client`

---

## 🔍 Troubleshooting
* **Error Code 105:** If the server log shows "No buffer space available," the setup script automatically attempts to fix this by increasing the `txqueuelen` of `slcan0`.
* **Device Not Found:** Ensure no other serial monitors are open. The setup script will attempt to `pkill` conflicting processes, but a physical re-plug may be necessary if the hardware is locked at the kernel level.
