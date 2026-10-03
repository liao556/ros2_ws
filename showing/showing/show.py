"""发布本机 CPU / 内存 / 网络状态到话题 showing，同时订阅并打印。"""

import platform

import psutil
import rclpy
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node

from status_interfaces.msg import Massage


class Writenode(Node):

    def __init__(self, name):
        # 注意：必须是两个下划线的 __init__
        super().__init__(name)
        self.get_logger().info('下面是实时主机信息')
        self.show_all = self.create_publisher(Massage, 'showing', 10)
        self.subscriber = self.create_subscription(
            Massage, 'showing', self.timer_callback_2, 10)
        # 定时器会被反复调用，不会只执行一次
        self.timer = self.create_timer(1.0, self.timer_callback)

    def timer_callback(self):
        msg = Massage()
        msg.stamp = self.get_clock().now().to_msg()
        msg.hostname = platform.node()
        # float32 字段必须显式 float()，否则可能触发 PyFloat_Check 崩溃
        msg.cpu_percent = float(psutil.cpu_percent())
        msg.memory_percent = float(psutil.virtual_memory().percent)
        msg.memory_total = float(psutil.virtual_memory().total)
        msg.memory_available = float(psutil.virtual_memory().available)
        msg.net_sent = float(psutil.net_io_counters().bytes_sent)
        msg.net_recv = float(psutil.net_io_counters().bytes_recv)
        self.get_logger().info(
            f'主机名: {msg.hostname}, CPU: {msg.cpu_percent}%, '
            f'内存: {msg.memory_percent}%'
        )
        self.show_all.publish(msg)

    def timer_callback_2(self, msg):
        self.get_logger().info(
            f'在{msg.stamp.sec}.{msg.stamp.nanosec}时'
            f'主机{msg.hostname}目前cpu占有率为{msg.cpu_percent}'
            f'内存占用率为{msg.memory_percent}'
            f'内存总量为{msg.memory_total}'
            f'还剩内存{msg.memory_available}'
            f'网络输入与输出分别为{msg.net_sent}和{msg.net_recv} '
        )


def main(args=None):
    rclpy.init(args=args)
    # 变量名 node 与节点名字符串 'publish_all_node' 区分开
    node = Writenode('publish_all_node')
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
