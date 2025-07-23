FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV UTC=true
ENV ARC=false

ENV PYTHON_VERSION=3.10.12
ENV PYTHON_MINOR_VERSION=3.10
ENV PYTHON_BIN_VERSION=python3.10

ENV FREECAD_VERSION=develop
ENV FREECAD_REPO=https://github.com/ultifide/FreeCAD.git

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    python3-pybind11 \
    ca-certificates

RUN git clone --recurse-submodules --branch "$FREECAD_VERSION" "$FREECAD_REPO" /freecad

RUN chmod +x /freecad/tools/build/Docker/debian.sh && \
    /freecad/tools/build/Docker/debian.sh && \
    rm -rf /var/lib/apt/lists/*

RUN curl --silent --location --output-dir /usr/include/opencascade/ \
       --remote-name https://github.com/Open-Cascade-SAS/OCCT/raw/8af9bbd59aecf24c765e7ea0eeeb8c9dd5c1f8db/src/NCollection/NCollection_StlIterator.hxx --next \
       --remote-name https://github.com/Open-Cascade-SAS/OCCT/raw/8af9bbd59aecf24c765e7ea0eeeb8c9dd5c1f8db/src/OSD/OSD_Parallel.hxx

ENV PYTHONPATH="/usr/local/lib:$PYTHONPATH"

RUN mkdir /freecad-build

WORKDIR /freecad-build
RUN cmake \
    -DBUILD_GUI=OFF \
    -DPYTHON_EXECUTABLE=/usr/bin/$PYTHON_BIN_VERSION \
    -DPYTHON_INCLUDE_DIR=/usr/include/$PYTHON_BIN_VERSION \
    -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/lib${PYTHON_BIN_VERSION}.so \
    -DFREECAD_BUILD_DEBIAN=ON \
    -DBUILD_BIM=OFF \
    -DBUILD_FEM=OFF \
    -DBUILD_INSPECTION=OFF \
    -DBUILD_SANDBOX=OFF \
    -DBUILD_JTREADER=OFF \
    -DBUILD_OPENCASCADE=OFF \
    -DBUILD_CAM=OFF \
    -DBUILD_REVERSEENGINEERING=OFF \
    -DBUILD_TEST=OFF \
    -DENABLE_DEVELOPER_TESTS=OFF \
    -DBUILD_WEB=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    /freecad

RUN make -j$(nproc --ignore=2)
RUN make install

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
           /usr/share/doc/* \
           /usr/share/locale/* \
           /usr/share/man/* \
           /usr/share/info/* \
           /freecad

# Set the default command
CMD ["/bin/bash"]