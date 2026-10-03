#!/usr/bin/env bash
# ------------------------------------------------------------------
# 在同一个工作空间里安全切换 ROS 2 版本，避免两个版本互相污染。
#
#   用法（必须 source，否则环境变量不会留在当前终端）：
#       source tools/switch_ros.sh lyrical
#       source tools/switch_ros.sh humble
#
# 做了四件事：
#   1. 清掉上一条 ROS 环境残留的变量（这是版本紊乱的根源）
#   2. 切到对应 git 分支（lyrical / humble），保证代码与版本匹配
#   3. 删掉 build/ install/ log/，避免 CMakeCache 指向另一个发行版
#   4. source 对应发行版环境，重新编译并 source install/setup.bash
# ------------------------------------------------------------------

_ws="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_distro="${1:-}"

_usage() {
    echo "用法: source tools/switch_ros.sh <lyrical|humble>"
}

# 清掉上一条 ROS 环境的残留（关键：不清就会两个发行版串在一起）
_clean_ros_env() {
    unset ROS_DISTRO ROS_VERSION ROS_PYTHON_VERSION
    unset AMENT_PREFIX_PATH CMAKE_PREFIX_PATH COLCON_PREFIX_PATH
    unset ROS_PACKAGE_PATH PYTHONPATH LD_LIBRARY_PATH PKG_CONFIG_PATH
    unset AMENT_CURRENT_PREFIX COLCON_CURRENT_PREFIX
    # 清掉 pip/conda 之外可能残留的 ROS 可执行路径
    PATH="$(echo "$PATH" | tr ':' '\n' \
        | grep -v -E '/opt/ros/|/\.humble-env/' | paste -sd ':' -)"
    export PATH
}

if [ "$_distro" != "lyrical" ] && [ "$_distro" != "humble" ]; then
    _usage
    return 1 2>/dev/null || exit 1
fi

# --- 1. 切分支（有未提交改动会直接报错，不会悄悄丢东西） ---
if ! git -C "$_ws" rev-parse --verify "$_distro" >/dev/null 2>&1; then
    echo "找不到分支 $_distro，先创建它"
    return 1 2>/dev/null || exit 1
fi
git -C "$_ws" checkout "$_distro" || { echo "git 切换失败（可能有未提交的改动）"; return 1 2>/dev/null || exit 1; }

# --- 2. 清环境 ---
_clean_ros_env

# --- 3. source 对应发行版 ---
if [ "$_distro" = "lyrical" ]; then
    if [ -f /opt/ros/lyrical/setup.bash ]; then
        # shellcheck disable=SC1091
        . /opt/ros/lyrical/setup.bash
        echo "[switch_ros] 使用系统安装的 ROS 2 Lyrical"
    else
        echo "[switch_ros] 没找到 /opt/ros/lyrical，请先安装 Lyrical"
        return 1 2>/dev/null || exit 1
    fi
else
    if [ -f /opt/ros/humble/setup.bash ]; then
        # shellcheck disable=SC1091
        . /opt/ros/humble/setup.bash
        echo "[switch_ros] 使用系统安装的 ROS 2 Humble"
    elif [ -x "$_ws/.humble-env/tools/bin/micromamba" ] \
        && [ -d "$_ws/.humble-env/ros-humble" ]; then
        export MAMBA_ROOT_PREFIX="$_ws/.humble-env/mamba"
        eval "$("$_ws/.humble-env/tools/bin/micromamba" shell hook -s bash)"
        micromamba activate "$_ws/.humble-env/ros-humble" >/dev/null 2>&1
        echo "[switch_ros] 使用 .humble-env 里的 ROS 2 Humble（RoboStack）"
    else
        echo "[switch_ros] 没有可用的 Humble："
        echo "   - Ubuntu 22.04：sudo apt install ros-humble-desktop"
        echo "   - 其它系统：docker run -it --rm -v $_ws:/ws ros:humble"
        return 1 2>/dev/null || exit 1
    fi
fi

echo "[switch_ros] ROS_DISTRO=$ROS_DISTRO  python=$(python3 -V 2>&1)"

# --- 4. 重新编译（build/install/log 跨发行版不能复用） ---
cd "$_ws" || return 1 2>/dev/null
rm -rf build install log
colcon build --symlink-install
# shellcheck disable=SC1091
. install/setup.bash

echo "[switch_ros] 已切到 $_distro：ros2 run / ros2 topic echo 现在都用这个发行版"
