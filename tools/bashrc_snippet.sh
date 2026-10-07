# >>> ros2_ws 跨发行版防混用（由 Codex 添加，原 ~/.bashrc 已备份）>>>
# 作用：给 colcon 套一层守卫，构建前自动清理另一个 ROS 发行版的旧缓存。
# 避免出现 rosidl_write_generator_arguments() called with unused arguments
# 这类跨发行版混用的报错。详见 ros2_ws/tools/ros_guard.sh
if [ -f "$HOME/ros2_ws/tools/ros_guard.sh" ]; then
    . "$HOME/ros2_ws/tools/ros_guard.sh"
fi
# <<< ros2_ws 跨发行版防混用 <<<
