"""服务客户端：读取本机 CPU 占用率并请求 check_cpu 服务。"""

import psutil
import rclpy
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node

from status_interfaces.srv import Contact


class Writenode(Node):

    def __init__(self, name):
        # 注意：必须是两个下划线的 __init__
        super().__init__(name)
        self.check_client = self.create_client(Contact, 'check_cpu')
        # 用定时器反复请求，而不是只调用一次
        self.timer = self.create_timer(3.0, self.gain_send_cpu)

    def gain_send_cpu(self):
        if not self.check_client.service_is_ready():
            self.get_logger().info('服务不在线，等待 check_cpu 服务端启动')
            return
        # 请求对象是 Contact.Request()，不要拼错成 Resquest
        request = Contact.Request()
        request.cpu_percentage = float(psutil.cpu_percent())
        self.check_client.call_async(request).add_done_callback(self.callback)

    def callback(self, future):
        # 异步回调签名是 (self, future)，结果从 future.result() 取
        response = future.result()
        if not response.response:
            self.get_logger().info('你需要清洁你的电脑')
        else:
            self.get_logger().info('电脑很干净')


def main(args=None):
    rclpy.init(args=args)
    # 变量名 node 与节点名字符串 'check_cpu_node' 区分开
    node = Writenode('check_cpu_node')
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
