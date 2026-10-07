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

# 从某个 PATH 型变量里删掉匹配 $2 的条目（第二道防线，防止两个发行版叠加）
_ros_drop_paths() {
    local var="$1" pat="$2" val new
    eval "val=\${$var:-}"
    [ -n "$val" ] || return 0
    new="$(printf '%s' "$val" | tr ':' '\n' | grep -v -E "$pat" | paste -sd ':' -)"
    eval "$var=\"\$new\""
    export "$var"
}

_ros_purge_foreign() {
    local v
    for v in PATH CMAKE_PREFIX_PATH AMENT_PREFIX_PATH COLCON_PREFIX_PATH \
             PYTHONPATH LD_LIBRARY_PATH PKG_CONFIG_PATH; do
        _ros_drop_paths "$v" "$1"
    done
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
        # 万一之前激活过 RoboStack 的 humble，把它的路径清掉
        _ros_purge_foreign '\.humble-env/ros-humble'
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
        # 装上 activate.d 钩子：以后不管怎么激活这个 conda 环境，都会自动
        # 剔除其它发行版的路径（防止在 fishros 终端里手动 activate 造成混用）
        _hook_src="$_ws/tools/conda_activate.d/zz-purge-foreign-ros.sh"
        _hook_dst="$_ws/.humble-env/ros-humble/etc/conda/activate.d/zz-purge-foreign-ros.sh"
        if [ -f "$_hook_src" ] && ! cmp -s "$_hook_src" "$_hook_dst" 2>/dev/null; then
            cp "$_hook_src" "$_hook_dst" 2>/dev/null \
                && chmod +x "$_hook_dst" \
                && echo "[switch_ros] 已安装 Humble 激活钩子（自动清除其它发行版路径）"
        fi
        # 第二道防线：即使 ~/.bashrc 已经 source 了 lyrical，也不允许它留在环境里
        _ros_purge_foreign '^/opt/ros/'
        echo "[switch_ros] 使用 .humble-env 里的 ROS 2 Humble（RoboStack）"
    else
        echo "[switch_ros] 没有可用的 Humble："
        echo "   - Ubuntu 22.04：sudo apt install ros-humble-desktop"
        echo "   - 其它系统：docker run -it --rm -v $_ws:/ws ros:humble"
        return 1 2>/dev/null || exit 1
    fi
fi

echo "[switch_ros] ROS_DISTRO=$ROS_DISTRO  python=$(python3 -V 2>&1)"

# 自检：环境里不能再出现另一个发行版的痕迹
_ros_leftover=""
for _p in ${CMAKE_PREFIX_PATH//:/ } ${AMENT_PREFIX_PATH//:/ }; do
    case "$_distro" in
        humble)  case "$_p" in /opt/ros/*) _ros_leftover="$_ros_leftover $_p" ;; esac ;;
        lyrical) case "$_p" in */.humble-env/ros-humble*) _ros_leftover="$_ros_leftover $_p" ;; esac ;;
    esac
done
if [ -n "$_ros_leftover" ]; then
    echo "[switch_ros] 警告：环境里仍有其它发行版路径：$_ros_leftover"
else
    echo "[switch_ros] 环境自检通过：只包含 $_distro 一个发行版"
fi

# --- 4. 重新编译（build/install/log 跨发行版不能复用） ---
cd "$_ws" || return 1 2>/dev/null
rm -rf build install log
colcon build --symlink-install
# shellcheck disable=SC1091
. install/setup.bash

echo "[switch_ros] 已切到 $_distro：ros2 run / ros2 topic echo 现在都用这个发行版"

# 装上 colcon 守卫：以后即使忘了删 build/ 也不会再出现跨版本缓存错误
if [ -f "$_ws/tools/ros_guard.sh" ]; then
    # shellcheck disable=SC1091
    . "$_ws/tools/ros_guard.sh"
    echo "[switch_ros] 已启用 colcon 守卫（colcon build 前自动检查缓存发行版）"
fi
