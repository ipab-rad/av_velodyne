^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Changelog for package av_velodyne_launch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1.1.0 (2024-05-21)
------------------
* Add cyclone DDS as ROS RMW  + configurate it to support high msg throughput
* Avoid `dev.sh` override `latest` docker tag for convenience
* Enable colorised ROS log
* Synchronise host time with docker container via volume mount

1.0.0 (2024-04-29)
------------------
* Remove Dockerfile deps only needed for compilation
* Porting code from ipab-rad/velodyne repository (`#1 <https://github.com/ipab-rad/av_velodyne/issues/1>`_)
  This PR ports the `av_velodyne_launch` ROS 2 package, dockerfile and
  scripts from the ipab-rad/velodyne repository.
  - This repositories does not longer inclue the velodyne driver source
  code, instead, the drivers are installed from the `apt` repository.
  - The generated av image has been tested in the vehicle
* Contributors: Alejandro Bordallo, Hector Cruz
