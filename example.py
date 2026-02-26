#!/usr/bin/env python3
import websocket
import json
import numpy as np
import threading
from time import sleep

# --- Xela General Hub ---
class XelaGeneralHub:
    def __init__(self, ip="127.0.0.1", port=5000):
        self.ip = ip
        self.port = port
        self.sensor_grids = {} # Format: {'1': np.array(4,6,3)}
        self.wsapp = None

    def on_message(self, wsapp, message):
        try:
            data = json.loads(message)
            if data.get("type") == "routine":
                # Dynamically detect sensors (keys '1', '2', etc.)
                current_sensors = [k for k in data.keys() if k.isdigit()]
                for s_id in current_sensors:
                    # Reshape 72 raw values into a 4x6x3 grid
                    flat = np.array(data[s_id]['calibrated'])
                    self.sensor_grids[s_id] = flat.reshape(4, 6, 3)
        except Exception:
            pass

    def run(self):
        self.wsapp = websocket.WebSocketApp(
            f"ws://{self.ip}:{self.port}", 
            on_message=self.on_message
        )
        self.wsapp.run_forever()

# --- Terminal Visualizer ---
def start_viz(hub):
    try:
        while True:
            print("\033c", end="") # Clear terminal
            print(f"=== XELA SENSOR MONITOR (Z-Axis) | Sensors: {len(hub.sensor_grids)} ===")
            if not hub.sensor_grids:
                print("Waiting for data...")
            else:
                sorted_ids = sorted(hub.sensor_grids.keys(), key=int)
                header = "".join([f"SENSOR {s_id} (4x6)".ljust(35) + " | " for s_id in sorted_ids])
                print(header + "\n" + "-" * len(header))
                for row_idx in range(4):
                    row_string = ""
                    for s_id in sorted_ids:
                        z_vals = hub.sensor_grids[s_id][row_idx, :, 2]
                        row_string += " ".join([f"{v:6.2f}" for v in z_vals]) + " | "
                    print(row_string)
            sleep(0.1)
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    hub = XelaGeneralHub()
    threading.Thread(target=hub.run, daemon=True).start()
    start_viz(hub)

# =================================================================
# ROS 1 Noetic Integration Example (Commented Out)
# =================================================================
# import rospy
# from std_msgs.msg import Float32MultiArray
#
# def main_ros1():
#     rospy.init_node('xela_publisher_ros1', anonymous=True)
#     hub = XelaGeneralHub()
#     threading.Thread(target=hub.run, daemon=True).start()
#     
#     publishers = {}
#     rate = rospy.Rate(20) # 20Hz
#
#     while not rospy.is_shutdown():
#         for s_id, grid in hub.sensor_grids.items():
#             if s_id not in publishers:
#                 publishers[s_id] = rospy.Publisher(f'xela/sensor_{s_id}', Float32MultiArray, queue_size=10)
#             
#             msg = Float32MultiArray()
#             msg.data = grid.flatten().tolist()
#             publishers[s_id].publish(msg)
#         rate.sleep()

# =================================================================
# ROS 2 Integration Example (Commented Out)
# =================================================================
# import rclpy
# from rclpy.node import Node
# from std_msgs.msg import Float32MultiArray
#
# class XelaRosPublisher(Node):
#      def __init__(self, hub):
#          super().__init__('xela_publisher')
#          self.hub = hub
#          self.publishers_ = {}
#          self.timer = self.create_timer(0.05, self.timer_callback) # 20Hz
#
#      def timer_callback(self):
#          for s_id, grid in self.hub.sensor_grids.items():
#              if s_id not in self.publishers_:
#                  self.publishers_[s_id] = self.create_publisher(
#                      Float32MultiArray, f'xela/sensor_{s_id}', 10)
#              
#              msg = Float32MultiArray()
#              msg.data = grid.flatten().tolist()
#              self.publishers_[s_id].publish(msg)
#
# def main_ros2():
#      rclpy.init()
#      hub = XelaGeneralHub()
#      threading.Thread(target=hub.run, daemon=True).start()
#      node = XelaRosPublisher(hub)
#      rclpy.spin(node)
