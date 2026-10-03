# ros2_ws — 主机状态监控示例（ROS 2 Humble 版）

> 这个仓库有两个分支，代码按发行版分开存放，互不干扰：
>
> - **`humble` 分支（你正在看的这个）**：面向 ROS 2 Humble / Ubuntu 22.04 / Python 3.10 迁移后的版本
> - **`lyrical` 分支**：原来的 ROS 2 Lyrical 版本，内容保持原样
> - `main` 分支与 `lyrical` 相同
>
> 切换方式见文末「两个版本之间安全切换」。

## 包含的包

| 包名 | 类型 | 节点 / 入口 | 说明 |
| --- | --- | --- | --- |
| `status_interfaces` | ament_cmake | msg `SystemStatus`、`Massage`，srv `Contact` | 自定义接口 |
| `status_publisher` | ament_python | `sys_status_pub`、`gui_display` | 发布 `/sys_status` + tkinter 显示窗口 |
| `showing` | ament_python | `publish_all_node` | 发布 `/showing`，并在终端打印 |
| `receive_all` | ament_python | `receive_all_node` | 订阅 `/showing` 并打印 |
| `display_cpu` | ament_python | `display_cpu_node` | **服务端**，提供 `/check_cpu` |
| `check_cpu` | ament_python | `check_cpu_node` | **客户端**，读取 CPU 后调用 `/check_cpu` |

## 接口定义

`status_interfaces/msg/SystemStatus.msg`（`Massage.msg` 字段完全相同，保留给旧节点用）

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

## 依赖

```bash
sudo apt install python3-psutil python3-tk
```

`python3-tk` 只有 `gui_display` 用得到，跑纯终端节点时可以不装。

## 编译

```bash
cd ~/ros2_ws
rm -rf build install log
source /opt/ros/humble/setup.bash
colcon build --symlink-install
source install/setup.bash
```

如果 `rosdep install --from-paths src --ignore-src -y` 报找不到依赖，先按 `package.xml`
里的名字在 Humble 中确认包名（本仓库用的是 `rclpy`、`status_interfaces`、
`python3-psutil`、`python3-tk`、`ament_cmake`、`rosidl_default_generators` 等标准键）。

## 运行与验证

开多个终端，每个都先 `source /opt/ros/humble/setup.bash && source install/setup.bash`。

```bash
# 0. 看接口
ros2 interface show status_interfaces/msg/SystemStatus
ros2 interface show status_interfaces/srv/Contact

# 终端 1：发布者
ros2 run status_publisher sys_status_pub

# 终端 2：显示窗口（tkinter）
ros2 run status_publisher gui_display

# 终端 3：查看话题
ros2 topic echo /sys_status

# 终端 4：服务端
ros2 run display_cpu display_cpu_node

# 终端 5：调用服务（>=0.20 返回 False，其余返回 True）
ros2 service call /check_cpu status_interfaces/srv/Contact "{cpu_percentage: 0.3}"

# 终端 6：客户端节点，自动读取本机 CPU 占用后请求服务
ros2 run check_cpu check_cpu_node

# 话题示例的另一对节点
ros2 run showing publish_all_node
ros2 run receive_all receive_all_node
```

> 注意命名：本仓库里 `display_cpu` 是服务端、`check_cpu` 是客户端，
> 和部分教程里两个名字的角色相反，跑的时候别搞混。

## 两个版本之间安全切换

`build/` `install/` `log/` 不能跨发行版复用（会出现
`CMakeCache.txt directory is different` 之类的报错），所以仓库提供了一个脚本，
一次做完「清环境 → 切分支 → 删构建目录 → 编译」：

```bash
cd ~/ros2_ws
source tools/switch_ros.sh lyrical     # 切回 Lyrical
source tools/switch_ros.sh humble      # 切到 Humble
```

必须用 `source` 执行，因为环境变量要留在当前终端里。脚本会按顺序尝试：
系统 `/opt/ros/<distro>`，没有 Humble 时再退回仓库内 `.humble-env` 里的
RoboStack Humble 环境。

不想动本机环境时，用官方镜像最省事：

```bash
docker run -it --rm -v ~/ros2_ws:/ws -w /ws ros:humble \
  bash -lc "apt update && apt install -y python3-psutil python3-tk && colcon build --symlink-install"
```

## Python 3.10 兼容性注意事项

代码里所有 `float32` 字段赋值都写成 `float(...)`，避免 `PyFloat_Check failed`；
每个 `main()` 都是 `try / finally`，退出时 `destroy_node()` + `rclpy.shutdown()`；
`shutdown()` 前判断 `rclpy.ok()`，避免被 Ctrl+C 或 `kill` 之后重复关闭报
`rcl_shutdown already called`。
