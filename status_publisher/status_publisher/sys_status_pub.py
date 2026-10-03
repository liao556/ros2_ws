"""定时采集本机状态并发布到话题 /sys_status（消息类型 SystemStatus）。"""

import platform

import psutil
import rclpy
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node

from status_interfaces.msg import SystemStatus


class SysStatusPub(Node):

    def __init__(self, node_name):
        # 必须是两个下划线的 __init__
        super().__init__(node_name)
        self.get_logger().info('开始发布主机状态到 /sys_status')
        self.publisher_ = self.create_publisher(SystemStatus, 'sys_status', 10)
        # 定时器：每 1 秒回调一次，会被反复调用
        self.timer = self.create_timer(1.0, self.timer_callback)

    def timer_callback(self):
        msg = SystemStatus()
        msg.stamp = self.get_clock().now().to_msg()
        msg.hostname = platform.node()
        # float32 字段一律显式 float()，避免 PyFloat_Check 崩溃
        msg.cpu_percent = float(psutil.cpu_percent())
        msg.memory_percent = float(psutil.virtual_memory().percent)
        msg.memory_total = float(psutil.virtual_memory().total)
        msg.memory_available = float(psutil.virtual_memory().available)
        msg.net_sent = float(psutil.net_io_counters().bytes_sent)
        msg.net_recv = float(psutil.net_io_counters().bytes_recv)
        self.publisher_.publish(msg)
        self.get_logger().info(
            f'{msg.hostname} CPU {msg.cpu_percent}% '
            f'内存 {msg.memory_percent}%'
        )


def main(args=None):
    rclpy.init(args=args)
    # 变量名 node 与节点名字符串 'sys_status_pub' 区分开
    node = SysStatusPub('sys_status_pub')
    try:
        rclpy.spin(node)
    except (KeyboardInterrupt, ExternalShutdownException):
        pass
    finally:
        node.destroy_node()
        # shutdown 必须带括号；外部已经关闭时不要再关一次
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
