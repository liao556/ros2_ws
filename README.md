# ros2_ws — 主机状态监控示例（ROS 2）

一个 ROS 2 工作空间，包含两套示例程序：

1. **话题通信**：`showing` 定时采集本机 CPU / 内存 / 网络状态并发布，`receive_all` 订阅并打印。
2. **服务通信**：`check_cpu` 作为客户端请求 CPU 使用率，`display_cpu` 作为服务端判断电脑是否需要清理。

## 包说明

- `status_interfaces`：ament_cmake 接口包，定义自定义消息 `Massage.msg` 与服务 `Contact.srv`
- `showing`：ament_python 包，话题发布者节点 `publish_all_node`
- `receive_all`：ament_python 包，话题订阅者节点 `receive_all_node`
- `display_cpu`：ament_python 包，服务端节点 `display_cpu_node`（服务名 `check_cpu`）
- `check_cpu`：ament_python 包，客户端节点 `check_cpu_node`（调用服务 `check_cpu`）

### 接口定义

`status_interfaces/msg/Massage.msg`

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

`status_interfaces/srv/Contact.srv`

```
float32 cpu_percentage
---
bool response
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
git clone https://github.com/liao556/ros2_ws.git ros2_ws
cd ~/my_ws

# 方式二：也可以直接把本仓库当作工作空间根目录使用
# cd <本仓库目录>

source /opt/ros/<distro>/setup.bash
colcon build
source install/setup.bash
```

## 运行

### 话题示例（发布 / 订阅）

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

### 服务示例（客户端 / 服务端）

先启动服务端，再启动客户端：

```bash
# 终端 1：服务端，判断 CPU 是否需要清理
ros2 run display_cpu display_cpu_node

# 终端 2：客户端，读取本机 CPU 占用并请求服务
ros2 run check_cpu check_cpu_node
```

调用服务：

```bash
ros2 service list
ros2 service call /check_cpu status_interfaces/srv/Contact "{cpu_percentage: 0.5}"
```
