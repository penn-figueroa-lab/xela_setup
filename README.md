# Xela Tactile Sensor Linux Setup & API

This repository provides an automated installation and data visualization suite for **Xela Robotics** tactile sensors (optimized for the **uSPa46 4x6** series) on Ubuntu.

---

## 🛠 Features

* **Zero-Config Install:** Handles software extraction and directory placement in `/etc/xela` automatically.
* **Serial-Locked Detection:** Uses unique hardware serials (e.g., `D30BL366`) to distinguish the sensor from other FTDI devices like grippers.
* **Self-Healing Reset:** Forcefully clears busy USB ports and increases CAN transmit queues to prevent buffer overflow (Error 105).
* **Multi-Gen ROS Support:** Includes templates for both **ROS 1 Noetic** and **ROS 2**.

---

## 🚀 Quick Start

### 1. Hardware Setup
Connect your Xela tactile sensor via USB. The `setup_xela.sh` script is configured to prioritize the sensor's hardware serial number.

### 2. Run Installation
Execute the setup script with `sudo` privileges. This installs the server and brings up the `slcan0` interface.

```bash
chmod +x setup_xela.sh
sudo ./setup_xela.sh
```

### 3. Run Visualization
Monitor your sensor data (Z-axis pressure) in real-time:
```bash
python3 example.py
```

---

## 📊 Data Mapping (uSPa46)
The API transforms raw data into a structured **NumPy array** `(4, 6, 3)`:



* **Axis 0:** X (Shear Force)
* **Axis 1:** Y (Shear Force)
* **Axis 2:** Z (Normal Pressure)

---

## 🤖 Robot Operating System (ROS) Integration
`example.py` contains commented templates for both versions of ROS.

### For ROS 1 Noetic:
1. Ensure `rospy` is installed and your workspace is sourced.
2. Uncomment the `main_ros1()` function and call it in `__main__`.
3. Data is published as `Float32MultiArray` to `/xela/sensor_1`.

### For ROS 2:
1. Ensure `rclpy` is installed.
2. Uncomment the `main_ros2()` function and the `XelaRosPublisher` class.

---

## 📋 Dependencies
* **System:** `sudo apt install can-utils`
* **Python:** `pip install numpy websocket-client`

---

## 🔍 Troubleshooting
* **Sensor Not Found:** Check your serial number by running: `lsusb -v -d 0403:6015 | grep iSerial`. Ensure this matches the `XELA_SERIAL` variable in your setup script.
* **Permission Denied:** Always run `setup_xela.sh` with `sudo` as it requires permission to modify network interfaces and `/etc/` directories.
