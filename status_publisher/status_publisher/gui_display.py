"""tkinter 显示窗口：订阅 /sys_status 并实时刷新界面。

rclpy.spin 跑在后台线程，tkinter 只能在主线程更新界面，
因此回调里只缓存消息，界面用 root.after 定时刷新。
"""

import threading
import tkinter as tk

import rclpy
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node

from status_interfaces.msg import SystemStatus


class GuiDisplay(Node):

    def __init__(self, node_name, root):
        # 必须是两个下划线的 __init__
        super().__init__(node_name)
        self.root = root
        self.last_msg = None
        self.first_msg_logged = False
        self.labels = {}

        root.title('主机状态显示')
        rows = [
            ('hostname', '主机名'),
            ('cpu_percent', 'CPU 占用 %'),
            ('memory_percent', '内存占用 %'),
            ('memory_total', '内存总量 B'),
            ('memory_available', '可用内存 B'),
            ('net_sent', '网络发送 B'),
            ('net_recv', '网络接收 B'),
        ]
        for index, (key, caption) in enumerate(rows):
            tk.Label(root, text=caption, anchor='w', width=12).grid(
                row=index, column=0, sticky='w', padx=8, pady=2)
            value = tk.Label(root, text='--', anchor='w', width=24)
            value.grid(row=index, column=1, sticky='w', padx=8, pady=2)
            self.labels[key] = value

        self.subscription = self.create_subscription(
            SystemStatus, 'sys_status', self.callback, 10)
        self.get_logger().info('显示窗口已启动，等待 /sys_status 数据')
        self.refresh()

    def callback(self, msg):
        # 回调在 spin 线程执行，只缓存，不动界面
        self.last_msg = msg

    def refresh(self):
        msg = self.last_msg
        if msg is not None:
            self.labels['hostname'].config(text=str(msg.hostname))
            self.labels['cpu_percent'].config(text=f'{msg.cpu_percent:.1f}')
            self.labels['memory_percent'].config(text=f'{msg.memory_percent:.1f}')
            self.labels['memory_total'].config(text=f'{msg.memory_total:.0f}')
            self.labels['memory_available'].config(
                text=f'{msg.memory_available:.0f}')
            self.labels['net_sent'].config(text=f'{msg.net_sent:.0f}')
            self.labels['net_recv'].config(text=f'{msg.net_recv:.0f}')
            if not self.first_msg_logged:
                self.first_msg_logged = True
                # 把窗口里真实渲染出来的文字读回来，证明界面确实刷新了
                self.get_logger().info(
                    '窗口已刷新 -> 主机名=%s CPU=%s%% 内存=%s%% 可用内存=%sB' % (
                        self.labels['hostname'].cget('text'),
                        self.labels['cpu_percent'].cget('text'),
                        self.labels['memory_percent'].cget('text'),
                        self.labels['memory_available'].cget('text'),
                    ))
        self.root.after(200, self.refresh)


def _spin(node):
    # spin 在后台线程里跑，外部关闭（Ctrl+C / kill）时会抛异常，这里吞掉
    try:
        rclpy.spin(node)
    except (KeyboardInterrupt, ExternalShutdownException):
        pass


def main(args=None):
    rclpy.init(args=args)
    root = tk.Tk()
    # 变量名 node 与节点名字符串 'gui_display' 区分开
    node = GuiDisplay('gui_display', root)
    spin_thread = threading.Thread(target=_spin, args=(node,), daemon=True)
    spin_thread.start()
    try:
        root.mainloop()
    except (KeyboardInterrupt, tk.TclError):
        pass
    finally:
        node.destroy_node()
        # shutdown 必须带括号；外部已经关闭时不要再关一次
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
