import rclpy
from rclpy.node import Node
from status_interfaces.msg import Massage
from builtin_interfaces.msg import Time
import platform, psutil


class Writenode(Node):
    def __init__(self,name):
        super().__init__(name)
        self.get_logger().info("下面是实时主机信息")
        self.show_all=self.create_publisher(Massage,'showing',10)
        self.timer=self.create_timer(5,self.timer_callback)
        self.subscriber=self.create_subscription(Massage,"showing",self.timer_callback_2,10)
    def timer_callback(self):
        msg=Massage()
        msg.stamp= self.get_clock().now().to_msg()
        msg.hostname=platform.node()
        msg.cpu_percent= float(psutil.cpu_percent())
        msg.memory_percent=float(psutil.virtual_memory().percent)
        msg.memory_total=float(psutil.virtual_memory().total)
        msg.memory_available=float(psutil.virtual_memory().available)
        msg.net_sent=float(psutil.net_io_counters().bytes_sent)
        msg.net_recv=float(psutil.net_io_counters().bytes_recv)
        self.get_logger().info(
            f'主机名: {msg.hostname}, CPU: {msg.cpu_percent}%, '
            f'内存: {msg.memory_percent}%'
        )
        self.show_all.publish(msg)
    def timer_callback_2(self,msg):
         self.get_logger().info(
              f"在{msg.stamp.sec}.{msg.stamp.nanosec}时"
              f"主机{msg.hostname}目前cpu占有率为{msg.cpu_percent}"
              f"内存占用率为{msg.memory_percent}"
              f"内存总量为{msg.memory_total}"
              f"还剩内存{msg.memory_available}"
              f"网络输入与输出分别为{msg.net_sent}和{msg.net_recv} "    
)
         
         
    
        
def main(args=None):
        rclpy.init(args=args)
        name_2=Writenode("publish_all_node")
        rclpy.spin(name_2)
        rclpy.shutdown()


        

       
