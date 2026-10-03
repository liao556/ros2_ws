from status_interfaces.srv import Contact
import rclpy
from rclpy.node import Node
import platform, psutil

class Writenode(Node):
    def __init__(self,name):
        super().__init__(name)
        self.service=self.create_service(Contact,"check_cpu",self.callback )


    def callback(self,request,response):
         if request.cpu_percentage>=0.20:
             self.get_logger().info("空闲时cpu仍然很高，可能有后台进程")
             response.response=False
         else:
             self.get_logger().info('目前状况良好')
             response.response=True
         return response


def main(args=None):
    rclpy.init(args=args)
    display_cpu=Writenode('display_cpu_node')
    rclpy.spin(display_cpu)
    rclpy.shutdown
