# Use a stable Haskell base image built on Debian 12 (Bullseye) for strict reproducibility
FROM haskell:9.6-slim-bullseye

WORKDIR /workspace

# Install Agda C-dependencies, Python for telemetry, and wrk for latency benchmarking
RUN apt-get update && apt-get install -y \
    git \
    make \
    zlib1g-dev \
    libtinfo-dev \
    python3 \
    python3-pip \
    time \
    wrk \
    && rm -rf /var/lib/apt/lists/*

# Pin Agda to the stable version (2.6.4.1)
RUN cabal update && cabal install Agda-2.6.4.1 --overwrite-policy=always && \
    cabal install --lib aeson bytestring text

# Ensure the newly built Agda binary is in the system PATH
ENV PATH="/root/.cabal/bin:${PATH}"

# Fetch the Cubical Agda Library (This is all we need now!)
RUN git clone https://github.com/agda/cubical.git /opt/cubical \
    && cd /opt/cubical \
    && git checkout v0.6

# Wire the Cubical library into Agda's global configuration
RUN mkdir -p /root/.agda \
    && echo "/opt/cubical/cubical.agda-lib" > /root/.agda/libraries \
    && echo "cubical" > /root/.agda/defaults

# Clean up potentially mismatched pre-compiled files
RUN find /opt/cubical -name "*.agdai" -type f -delete

# Copy the artifact repository into the container
COPY . /workspace/

# By default, drop into a bash shell so reviewers can run compile commands
CMD ["/bin/bash"]
