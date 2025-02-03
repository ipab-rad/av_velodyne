# av_velodyne

This repository hosts the required environment for running the ROS 2 Velodyne LIDAR driver, specifically configured for running for two [VLP-16](https://velodynelidar.com/products/puck/) sensors mounted (left and right) on the autonomous vehicle platform of the [Rad](https://rad.inf.ed.ac.uk/) group at the University of Edinburgh.


## Docker container
- **Operating System**: Ubuntu 22.04
- **ROS Distribution**: Humble Hawksbill
- **Velodyne Drivers**:
    - `ros-humble-velodyne-driver ` ( version `2.4.0-1`): Manages communication with the Velodyne LIDAR sensor
    - `ros-humble-velodyne-pointcloud` (version `2.4.0-1`): Converts LIDAR data into 3D pointclouds([sensor_msgs/PointCloud2](https://docs.ros.org/en/melodic/api/sensor_msgs/html/msg/PointCloud2.html))

For more details please see [Dockerfile](./Dockerfile)

### ROS 2 launcher

The `av_velodyne_launch` ROS package contains the required launch files and configuration parameters for launching the driver for two lidars labeled as `left` and `right`.


## Usage

 Quickly build and run the Docker container using `runtime.sh` for runtime or debugging, and `dev.sh` for a convenient development setup.

### Runtime or Debugging

Execute the ROS 2 nodes in runtime mode or start an interactive bash session for detailed debugging:

```bash
./runtime.sh [bash]
```

- **Without arguments**: Activates the container in runtime mode.
- **With `bash`**: Opens an interactive bash session for debugging.

### Development

Prepare a development setting that reflects local code modifications and simplifies the build process:

```bash
./dev.sh
```

- **Live Code Synchronization**: Mounts local `av_velodyne_launch` directory with the container.
- **Convenience Alias**: The development container features a `colcon_build` alias, which simplifies the ROS2 build process. Executing `colcon_build` runs `colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release` and then sources the `setup.bash` to ensure the environment is updated with the latest build artifacts. This alias enhances productivity by combining build commands and environment setup into a single, easy command.
