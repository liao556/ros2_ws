from status_interfaces.srv import Contact
import rclpy
from rclpy.node import Node
import platform, psutil

class Writenode(Node):
    def __init__(self,name):
        super().__init__(name)
        self.check_client=self.create_client(Contact,"check_cpu")
    def gain_send_cpu(self):
        while not self.check_client.wait_for_service(1.0):
            self.get_logger.info('服务不在线')
        request=Contact.Request()
        request.cpu_percentage= float(psutil.cpu_percent())
        self.check_client.call_async(request).add_done_callback(self.callback)

    def callback(self,future):
        result=future.result()
        if not result.response:
            self.get_logger().info('你需要清洁你的电脑')
        else:self.get_logger().info('电脑很干净')
        


def main(args=None):
    rclpy.init(args=args)
    check_cpu=Writenode('check_cpu_node')
    check_cpu.gain_send_cpu()
    rclpy.spin(check_cpu)
    rclpy.shutdown