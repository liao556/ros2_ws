cmake_minimum_required(VERSION 3.14.4)
project(c_make)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)

# 源文件必须带 .cpp 后缀，否则 CMake 无法判断语言（Cannot determine link language）
add_executable(make_node src/c_make.cpp)

# 链接依赖的两种写法：
#   ament_target_dependencies() 是 Humble 时代的老写法，在 Lyrical 里已经被移除
#   （报 Unknown CMake command "ament_target_dependencies"）
#   rclcpp::rclcpp 这种现代写法 Humble 和 Lyrical 都支持，优先用它
if(TARGET rclcpp::rclcpp)
  target_link_libraries(make_node rclcpp::rclcpp)
elseif(COMMAND ament_target_dependencies)
  ament_target_dependencies(make_node rclcpp)
endif()

# 注意是 TARGETS，不是 TARDET
install(TARGETS
  make_node
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
