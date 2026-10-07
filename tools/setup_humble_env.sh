#!/usr/bin/env bash
# ------------------------------------------------------------------
# 在非 Ubuntu 22.04 的机器上，用 RoboStack 从零搭一个 ROS 2 Humble
# 环境（含 C++ 编译链），放到 <仓库>/.humble-env/ 下。
#
#   用法： bash tools/setup_humble_env.sh
#
# 之所以不用官方 apt 包：Humble 只支持 Ubuntu 22.04，本机是 26.04。
# 之所以不用 docker：本机没装容器运行时。
#
# 注意：ros-humble-rclcpp 是 C++ 节点（c_make 包）必需的，
#       漏装它会出现 "Could not find a package configuration file
#       provided by rclcpp" —— 这个脚本已经带上了。
# ------------------------------------------------------------------
set -e

_ws="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_env="$_ws/.humble-env"

mkdir -p "$_env/tools"
if [ ! -x "$_env/tools/bin/micromamba" ]; then
    echo "[setup] 下载 micromamba ..."
    curl -sSL -o "$_env/tools/mm.tar.bz2" \
        https://micro.mamba.pm/api/micromamba/linux-64/latest
    tar -xjf "$_env/tools/mm.tar.bz2" -C "$_env/tools"
fi

export MAMBA_ROOT_PREFIX="$_env/mamba"

echo "[setup] 创建 ROS 2 Humble（RoboStack）环境，约 2-3 GB，需要联网 ..."
"$_env/tools/bin/micromamba" create -y -p "$_env/ros-humble" \
    -c https://conda.anaconda.org/robostack-humble \
    -c conda-forge \
    ros-humble-rclpy \
    ros-humble-rclcpp \
    ros-humble-rosidl-default-generators \
    ros-humble-rosidl-default-runtime \
    ros-humble-ament-cmake \
    ros-humble-ament-cmake-python \
    ros-humble-ament-lint-auto \
    ros-humble-ament-lint-common \
    ros-humble-builtin-interfaces \
    ros-humble-ros2cli \
    ros-humble-ros2run \
    ros-humble-ros2topic \
    ros-humble-ros2service \
    ros-humble-ros2interface \
    ros-humble-ros2pkg \
    ros-humble-ros2node \
    colcon-common-extensions \
    cxx-compiler \
    cmake \
    ninja \
    make \
    psutil \
    tk

# 让 colcon 不去扫描这个目录（里面全是 conda 包，会被误当成工作空间成员）
touch "$_env/COLCON_IGNORE"

# 激活时自动剔除其它 ROS 发行版，防止跨版本混用
mkdir -p "$_env/ros-humble/etc/conda/activate.d"
cp "$_ws/tools/conda_activate.d/zz-purge-foreign-ros.sh" \
   "$_env/ros-humble/etc/conda/activate.d/"
chmod +x "$_env/ros-humble/etc/conda/activate.d/zz-purge-foreign-ros.sh"

echo "[setup] 完成。接下来："
echo "    cd $_ws && source tools/switch_ros.sh humble"
