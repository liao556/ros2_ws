cmake_minimum_required(VERSION 3.14.4)
project(c_topic)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
# 关键：用了自定义消息就必须 find_package 接口包。
# 少了这一句，status_interfaces_INCLUDE_DIRS 不会被导出，
# 编译时就会报 fatal error: status_interfaces/msg/test.hpp: No such file or directory
find_package(status_interfaces REQUIRED)

add_executable(test_topic_node src/c_topic.cpp)

# 链接依赖：
#   rclcpp::rclcpp 提供 rclcpp 本体
#   status_interfaces::status_interfaces__rosidl_typesupport_cpp 提供消息代码，
#   并且它内置了 include 路径 INTERFACE_INCLUDE_DIRECTORIES =
#   <prefix>/include/status_interfaces，所以头文件也能找到。
#   不能写成 rclcpp::rclcpp${status_interfaces_TARGETS}（少空格会拼成一个不存在的名字）
target_link_libraries(test_topic_node
  rclcpp::rclcpp
  ${status_interfaces_TARGETS}
)
install(TARGETS
  test_topic_node
  DESTINATION lib/${PROJECT_NAME}
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  # the following line skips the linter which checks for copyrights
  set(ament_cmake_copyright_FOUND TRUE)
  # the following line skips cpplint (only works in a git repo)
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
