#!/usr/bin/env bash
# ------------------------------------------------------------------
# 跨发行版防混用守卫（lyrical / humble 都适用）。
#
# 放进 ~/.bashrc 里 source 一次即可（见 tools/bashrc_snippet.sh）：
#     [ -f ~/ros2_ws/tools/ros_guard.sh ] && . ~/ros2_ws/tools/ros_guard.sh
#
# 它解决什么问题：
#   build/<包>/CMakeCache.txt 里记着"上一次配置时用的 cmake"。
#   如果你换了 ROS 发行版却没删 build/install/log，CMake 会拿新发行版的
#   脚本去跑旧发行版的缓存，报出这些看着莫名其妙的错误：
#     - rosidl_write_generator_arguments() called with unused arguments
#     - CMakeCache.txt directory is different
#     - 各种 ament_cmake / rosidl 宏找不到
#
# 提供的命令：
#   roscheck            查看当前发行版，以及 build/ 属于哪个发行版
#   colcon build ...    构建前自动检测并清理跨发行版的旧缓存
#                       （colcon 的其它子命令原样透传）
# ------------------------------------------------------------------

_ros_cmake_dir() {
    local c
    c="$(command -v cmake 2>/dev/null)"
    [ -n "$c" ] || return 1
    dirname "$c"
}

_ros_build_cmake_dirs() {
    # 列出 build/*/CMakeCache.txt 里记录的 cmake 目录（去重）
    local cache dir
    for cache in build/*/CMakeCache.txt; do
        [ -e "$cache" ] || continue
        dir="$(sed -n 's/^CMAKE_COMMAND:INTERNAL=//p' "$cache" | head -n 1)"
        if [ -n "$dir" ]; then
            dirname "$dir"
        fi
    done | sort -u
}

roscheck() {
    local cur d
    cur="$(_ros_cmake_dir)"
    echo "ROS_DISTRO      : ${ROS_DISTRO:-<未 source 任何 ROS 环境>}"
    echo "当前 cmake      : ${cur:-未找到}"
    echo "build/ 里的缓存 :"
    if [ -z "$(_ros_build_cmake_dirs)" ]; then
        echo "  <无>"
        return 0
    fi
    while read -r d; do
        [ -n "$d" ] || continue
        if [ "$d" = "$cur" ]; then
            echo "  $d  OK 与当前一致"
        else
            echo "  $d  !! 与当前不一致（下次 colcon build 会自动清理）"
        fi
    done < <(_ros_build_cmake_dirs)
}

_ros_guard_build() {
    local cur d stale=""
    if [ -z "${ROS_DISTRO:-}" ]; then
        echo "[ros_guard] 警告：当前没有 source 任何 ROS 环境，colcon build 会找不到 ament_cmake。"
        echo "[ros_guard] 先执行： source tools/switch_ros.sh <lyrical|humble>"
    fi
    cur="$(_ros_cmake_dir)"
    [ -n "$cur" ] || return 0
    while read -r d; do
        [ -n "$d" ] || continue
        [ "$d" = "$cur" ] || stale="$stale $d"
    done < <(_ros_build_cmake_dirs)
    if [ -n "$stale" ]; then
        echo "[ros_guard] build/ 里存在其它发行版配置的缓存："
        for d in $stale; do
            echo "[ros_guard]   - $d"
        done
        echo "[ros_guard] 当前环境用的是：$cur"
        echo "[ros_guard] 自动删除 build/ install/ log/ 后继续（不删必然报缓存不匹配）"
        rm -rf build install log
    fi
}

# 包装 colcon：只在 build 前做检查，其它子命令原样透传
colcon() {
    if [ "${1:-}" = "build" ]; then
        _ros_guard_build
    fi
    command colcon "$@"
}
