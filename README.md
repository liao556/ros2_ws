# ros2_ws — 主机状态监控示例（ROS 2）

一个 ROS 2 工作空间，演示自定义消息 + Python 发布/订阅节点：
`showing` 定时采集本机 CPU / 内存 / 网络状态并发布，`receive_all` 订阅并打印。

## 包说明

- `status_interfaces`：ament_cmake 接口包，定义自定义消息 `Massage.msg`
- `showing`：ament_python 包，发布者节点 `publish_all_node`
- `receive_all`：ament_python 包，订阅者节点 `receive_all_node`

### Massage.msg

```
builtin_interfaces/Time stamp
string hostname
float32 cpu_percent
float32 memory_percent
float32 memory_total
float32 memory_available
float32 net_sent
float32 net_recv
```

## 环境要求

- ROS 2（已在 `lyrical` 上验证，其他发行版一般同样可用）
- Python 依赖 `psutil`

```bash
sudo apt install python3-psutil
```

## 克隆与构建

```bash
# 方式一：克隆到自己的工作空间 src 下
mkdir -p ~/my_ws/src && cd ~/my_ws/src
git clone <仓库地址> ros2_ws_src
cd ~/my_ws

# 方式二：也可以直接把本仓库当作工作空间根目录使用
# cd <本仓库目录>

source /opt/ros/<distro>/setup.bash
colcon build
source install/setup.bash
```

## 运行

开两个终端（都先 source 环境）：

```bash
# 终端 1：发布主机状态
ros2 run showing publish_all_node

# 终端 2：订阅并打印
ros2 run receive_all receive_all_node
```

查看话题：

```bash
ros2 topic list
ros2 topic echo /showing
```
