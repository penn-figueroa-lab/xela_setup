# Xela Tactile Sensor Linux Setup & API

This repository provides an automated installation and data visualization suite for **Xela Robotics** tactile sensors (optimized for the **uSPa46 4x6** series) on Ubuntu. 

---

## 🛠 Features

* **Full Auto-Install:** Handles software download, extraction, and `/etc/xela` setup.
* **Smart Device Resolution:** Distinguishes between Xela Sensors and other FTDI devices (like Grippers) by remembering their hardware serial numbers.
* **Self-Healing Reset:** Forcefully clears "Busy" USB ports and increases CAN transmit queues to prevent "No buffer space available" errors.
* **Generalizable API:** Python hub scales to any number of sensors and reshapes raw data into 4x6 grids.

---

## 🚀 Quick Start

### 1. Run Installation
Execute the script with `sudo`. If multiple identical USB IDs are found, the script will prompt you to select the correct one and remember it for next time.

```bash
chmod +x setup_xela.sh
sudo ./setup_xela.sh
```

### 2. Run Visualization
```bash
python3 example.py
```

---

## 📊 Data Mapping (uSPa46)
The API transforms data into a `(4, 6, 3)` NumPy array representing the physical layout:



* **Axis 0:** X (Shear)
* **Axis 1:** Y (Shear)
* **Axis 2:** Z (Normal Force / Pressure)

---

## 🤖 Robot Operating System (ROS) Integration
`example.py` includes a ROS 2 template. To publish tactile data:
1. Ensure `rclpy` is installed: `pip install rclpy`.
2. Uncomment the ROS section at the bottom of `example.py`.
3. Data is published as `Float32MultiArray` on `/xela/sensor_1`, `/xela/sensor_2`, etc.

---

## 📋 Dependencies
* **System:** `sudo apt install can-utils`
* **Python:** `pip install numpy websocket-client`

---

## 🔍 Troubleshooting: Sensor vs Gripper
Since both Xela and many grippers share the same USB ID (`0403:6015`), the script saves your choice in `/etc/xela/xela_serial.conf`. 

If you accidentally select the wrong device:
`sudo rm /etc/xela/xela_serial.conf`
Then run `sudo ./setup_xela.sh` again to re-select.
