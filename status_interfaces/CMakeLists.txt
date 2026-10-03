cmake_minimum_required(VERSION 3.20)
project(status_interfaces)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# 找到必要的包
find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(builtin_interfaces REQUIRED)

# 生成接口
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/Massage.msg"
  "srv/Contact.srv"
  DEPENDENCIES builtin_interfaces
)

# 导出运行时依赖
ament_export_dependencies(rosidl_default_runtime)

ament_package()
