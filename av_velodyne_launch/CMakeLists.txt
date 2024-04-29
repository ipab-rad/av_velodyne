cmake_minimum_required(VERSION 3.8)
project(av_velodyne_launch)

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(velodyne_driver REQUIRED)
find_package(velodyne_pointcloud REQUIRED)

install(DIRECTORY config DESTINATION share/${PROJECT_NAME})

install(DIRECTORY launch DESTINATION share/${PROJECT_NAME})

install(PROGRAMS scripts/curl_engage.py DESTINATION lib/${PROJECT_NAME})

ament_package()
