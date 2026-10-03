"""订阅话题 showing 并打印主机状态。"""

import rclpy
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node

from status_interfaces.msg import Massage


class Writenode(Node):

    def __init__(self, name):
        # 注意：必须是两个下划线的 __init__
        super().__init__(name)
        self.get_logger().info('开始接收主机状态')
        self.subscriber = self.create_subscription(
            Massage, 'showing', self.timer_callback_2, 10)

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
    # 变量名 node 与节点名字符串 'receive_all_node' 区分开
    node = Writenode('receive_all_node')
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
