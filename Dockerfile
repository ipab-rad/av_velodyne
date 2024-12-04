FROM ros:humble-ros-base-jammy AS base

# Switch to much faster mirror for apt processes
ENV OLD_MIRROR archive.ubuntu.com
ENV SEC_MIRROR security.ubuntu.com
ENV NEW_MIRROR mirror.bytemark.co.uk

RUN sed -i "s/$OLD_MIRROR\|$SEC_MIRROR/$NEW_MIRROR/g" /etc/apt/sources.list

# Install basic dev tools (And clean apt-get cache afterwards)
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get -y --quiet --no-install-recommends install \
        # Velodyne Lidar driver
        ros-humble-velodyne-driver \
        ros-humble-velodyne-pointcloud \
        # Pip for Python3
        python3-pip \
        # Ping required for checking Velodynes
        inetutils-ping \
        # Install Cyclone DDS ROS RMW
        ros-"$ROS_DISTRO"-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

# Install pycurl to spin up/down velodynes
RUN pip install --no-cache-dir pycurl==7.45.3

# Setup ROS workspace folder
ENV ROS_WS /opt/ros_ws
WORKDIR $ROS_WS

# Set cyclone DDS ROS RMW
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

COPY ./cyclone_dds.xml $ROS_WS/

# Configure Cyclone cfg file
ENV CYCLONEDDS_URI=file://${ROS_WS}/cyclone_dds.xml

# Enable ROS log colorised output
ENV RCUTILS_COLORIZED_OUTPUT=1

# Setup Nebula ROS
ENV NEBULA /opt/ros_ws/src/nebula
RUN git clone https://github.com/ipab-rad/nebula.git $NEBULA \
    && apt-get update \
    && vcs import $NEBULA/ < $NEBULA/build_depends.repos \
    && DEBIAN_FRONTEND=noninteractive \
    && rosdep install --from-paths $NEBULA --ignore-src -y -r \
    && . /opt/ros/"$ROS_DISTRO"/setup.sh \
    && colcon build --packages-ignore nebula_tests nebula_examples nebula_sensor_driver --cmake-args -DCMAKE_BUILD_TYPE=Release \
    && rm -rf /opt/ros_ws/build $NEBULA \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------

FROM base AS prebuilt

# Import sensor code from repos
COPY av_velodyne_launch $ROS_WS/src/av_velodyne_launch

# Source ROS setup for dependencies and build our code
RUN . /opt/ros_ws/install/setup.sh \
    && colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# -----------------------------------------------------------------------

FROM base AS dev

# Install basic dev tools (And clean apt-get cache afterwards)
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get -y --quiet --no-install-recommends install \
        # Command-line editor
        nano \
        # Ping network tools
        inetutils-ping \
        # Bash auto-completion for convenience
        bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Add sourcing local workspace command to bashrc for convenience when running interactively
RUN echo ". /opt/ros_ws/install/setup.bash" >> /root/.bashrc && \
        # Add colcon build alias for convenience
    echo 'alias colcon_build="colcon build --symlink-install --cmake-args \
            -DCMAKE_BUILD_TYPE=Release && \
            source install/setup.bash"' >> /root/.bashrc

# Enter bash for development
CMD ["bash"]

# -----------------------------------------------------------------------

FROM base as runtime

# Copy artifacts/binaries from prebuilt
COPY --from=prebuilt $ROS_WS/install $ROS_WS/install

# Add command to docker entrypoint to source newly compiled
#   code when running docker container
RUN sed --in-place --expression \
        "\$isource \"$ROS_WS/install/setup.bash\" " \
        /ros_entrypoint.sh

# launch ros package
CMD ["ros2", "launch", "av_velodyne_launch", "av_velodyne.launch.xml"]
