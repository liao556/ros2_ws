#!/usr/bin/env bash
# ------------------------------------------------------------------
# 这个文件由 tools/switch_ros.sh 自动复制到
#   .humble-env/ros-humble/etc/conda/activate.d/
# 请改仓库里的这份，不要直接改 conda 环境里的副本。
#
# 作用：激活 RoboStack Humble 时，把其它 ROS 发行版（典型是
# ~/.bashrc 里 fishros 自动 source 的 /opt/ros/lyrical）从环境里剔除。
# 否则 CMAKE_PREFIX_PATH 会同时含两个发行版，colcon build 必然报
#   rosidl_write_generator_arguments() called with unused arguments
# 这类跨版本混用错误。
# ------------------------------------------------------------------

for _ros_var in PATH CMAKE_PREFIX_PATH AMENT_PREFIX_PATH COLCON_PREFIX_PATH \
                PYTHONPATH LD_LIBRARY_PATH PKG_CONFIG_PATH; do
    eval "_ros_val=\${$_ros_var:-}"
    if [ -n "$_ros_val" ]; then
        _ros_new="$(printf '%s' "$_ros_val" | tr ':' '\n' \
            | grep -v '^/opt/ros/' | paste -sd ':' -)"
        eval "$_ros_var=\"\$_ros_new\""
        export "$_ros_var"
    fi
done
unset _ros_var _ros_val _ros_new
