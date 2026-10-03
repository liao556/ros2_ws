"""服务端：提供 check_cpu 服务，根据 CPU 占用率判断是否需要清理电脑。"""

import rclpy
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node

from status_interfaces.srv import Contact


class Writenode(Node):

    def __init__(self, name):
        # 注意：必须是两个下划线的 __init__
        super().__init__(name)
        self.service = self.create_service(Contact, 'check_cpu', self.callback)

    def callback(self, request, response):
        # 服务端回调签名是 (self, request, response)，必须 return response
        if request.cpu_percentage >= 0.20:
            self.get_logger().info('空闲时cpu仍然很高，可能有后台进程')
            response.response = False
        else:
            self.get_logger().info('目前状况良好')
            response.response = True
        return response


def main(args=None):
    rclpy.init(args=args)
    # 变量名 node 与节点名字符串 'display_cpu_node' 区分开
    node = Writenode('display_cpu_node')
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
