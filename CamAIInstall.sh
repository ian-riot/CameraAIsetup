#!/bin/bash

# Assume a  debian install with docker



#install tmux to allow disconnects
sudo apt-get -y install tmux htop

# create an populate the docker file
cd ~/
rm Dockerfile
touch Dockerfile
cat > Dockerfile <<- "EOF"
FROM ubuntu:18.04
MAINTAINER ian
ENV OPENCV_VERSION 4.1.2
ENV NUM_CORES 2
ENV DEBIAN_FRONTEND=noninteractive
# Install OpenCV
RUN apt-get -y update -qq && \
    apt-get -y install build-essential cmake git pkg-config libgtk-3-dev && \
    apt-get -y install inetutils-ping net-tools && \
    apt-get -y install libtbb2 libtbb-dev libavcodec-dev libavformat-dev libswscale-dev && \
    apt-get -y install inetutils-ping net-tools libavfilter-dev && \
    apt-get -y install libmosquittopp-dev libjsoncpp-dev libgps-dev && \
    apt-get autoclean autoremove 
    # Get OpenCV
RUN cd ~/ &&\
    git clone https://github.com/opencv/opencv.git &&\
    cd ~/opencv &&\
    git checkout $OPENCV_VERSION &&\
    cd ~/ &&\
    # Get OpenCV contrib modules
    git clone https://github.com/opencv/opencv_contrib &&\
    cd ~/opencv_contrib &&\
    git checkout $OPENCV_VERSION &&\
    mkdir ~/opencv/build &&\
    cd ~/opencv/build &&\
    # Lets build OpenCV
    cmake \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D ENABLE_PRECOMPILED_HEADERS=OFF \
      -D OPENCV_GENERATE_PKGCONFIG=ON \
      -D INSTALL_C_EXAMPLES=OFF \
      -D INSTALL_PYTHON_EXAMPLES=OFF \
      -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
      -D BUILD_EXAMPLES=OFF \
      -D BUILD_DOCS=OFF \
      -D BUILD_TESTS=OFF \
      -D BUILD_PERF_TESTS=OFF \
      -D WITH_TBB=ON \
      -D WITH_OPENMP=ON \
      -D WITH_IPP=ON \
      -D WITH_CSTRIPES=ON \
      -D WITH_OPENCL=ON \
      -D WITH_V4L=ON \
      -D WITH_VTK=ON \
      .. &&\
    make -j$NUM_CORES &&\
    make install &&\
    ldconfig &&\
    # Clean the install from sources
    cd ~/ &&\
    rm -r ~/opencv &&\
    rm -r ~/opencv_contrib
# Change working dirs
WORKDIR /builds
RUN touch gh && cd /builds  && git clone https://fc4adc1969d6c736b9aaf1f43c5929243ccf704a@github.com/ian-riot/AIbroker.git &&\
    cd /builds/AIbroker &&\
    make -j$NUM_CORES release &&\
    cd .. &&\
    cd /builds &&\
    ls /builds/AIbroker &&\
    cp /builds/AIbroker/bin/Release/ffmpeg /builds/ffmpeg &&\
    cp  /builds/AIbroker/coco.names /builds/coco.names &&\
    cp  /builds/AIbroker/yolov3-tiny.cfg /builds/yolov3-tiny.cfg &&\
    cp  /builds/AIbroker/yolov3-tiny.weights /builds/yolov3-tiny.weights &&\
    mkdir /builds/home  &&\
    rm -r  /builds/AIbroker/* &&\
    apt-get -y install mosquitto
COPY ./start.sh /builds

#CMD ["/bin/bash", "-x", "/home/riot/start.sh"]
EOF

# create an populate the start shell
cd ~/
rm start.sh
touch start.sh
cat > start.sh <<- "EOF"
#!/bin/bash -x
# get the required files and place them correctly

mosquitto &

./ffmpeg %1 %2 %3 %4 %5 %6

EOF

# Pull in the Docker file for the build
#curl -u Mnandi@vigilent-tek.com ftp://vigilent-tek.com/Dockerfile -o /home/riot/Dockerfile
#curl -u Mnandi@vigilent-tek.com ftp://vigilent-tek.com/start.sh -o /home/riot/start.sh


# create an populate the start shell
cd ~/
rm makedocker.sh
touch makedocker.sh
cat > makedocker.sh <<- "EOF"
#!/bin/bash
# get the required files and place them correctly
docker build --network host -t humantracker .


EOF

# build the dockerfile in a tmux session
cd ~/

 tmux new -d -s ian 
 tmux send -t ian 'sh ~/makedocker.sh' ENTER
 tmux attach -t ian

# sh ~/makedocker.sh

# running the file will be manual for first time in the form:
# docker run --network home --restart always --name video_ai -p 1882:1883 -v ./home:/root/home -d riotnetwork/aibroker:1.3 sh start.sh cloud.riot.network 1886 127.0.0.1 1883 videoai videoai RiotLaunchpad
# 

