# Xela Tactile Sensor Linux Setup & API

This repository provides an automated installation and data visualization suite for **Xela Robotics** tactile sensors (optimized for the **uSPa46 4x6** series) on Ubuntu. It handles hardware driver initialization, server management, and provides a generalizable Python API.

---

## 🛠 Features

* **Zero-Config Install:** Automatically handles software extraction and directory placement in `/etc/xela`.
* **Serial-Locked Detection:** Uses the unique hardware serial number (`D30BL366`) to distinguish the Xela sensor from other identical FTDI bridges (like robotic grippers).
* **Self-Healing Reset:** Forcefully clears "Busy" USB ports and increases CAN transmit queues to prevent "No buffer space available" errors (Error 105).
* **Generalizable Data Hub:** The Python API automatically detects and scales to support any number of connected sensors.
* **Grid-Mapped Output:** Transforms raw 1D data lists into physical `[Row, Col, Axis]` arrays matching the sensor layout.

---

## 🚀 Quick Start

### 1. Hardware Setup
Connect your Xela tactile sensor via USB. The script is pre-configured to target the specific hardware serial **D30BL366**.

### 2. Run Installation
Execute the setup script with `sudo` privileges. This script installs the software, resets the CAN interface, and starts the Xela server.

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
* **Sensor Not Detected:** If you replace the physical sensor, you must update the `XELA_SERIAL` variable at the top of `setup_xela.sh` with the new ID. To find your serial number, run:
  ```bash
  lsusb -v -d 0403:6015 | grep iSerial
  ```
* **Device Busy:** If the script fails to bind to `slcan0`, ensure no other serial monitors (like Arduino IDE or Screen) are accessing the sensor's USB port.
