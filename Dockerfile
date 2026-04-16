# Use a stable Haskell base image built on Debian 11 (Bullseye)
FROM haskell:9.6-slim-bullseye

# Set the working directory inside the container
WORKDIR /artifact

# Install system dependencies required for Agda
RUN apt-get update && apt-get install -y \
    git \
    make \
    zlib1g-dev \
    libtinfo-dev \
    && rm -rf /var/lib/apt/lists/*

# Pin Agda to a specific, stable version (2.6.4.1)
RUN cabal update && cabal install Agda-2.6.4.1

# Ensure the newly built Agda binary is in the system PATH
ENV PATH="/root/.cabal/bin:${PATH}"

# Fetch the Agda Standard Library (required for discrete IO and String compilation)
RUN git clone https://github.com/agda/agda-stdlib.git /opt/agda-stdlib \
    && cd /opt/agda-stdlib \
    && git checkout v2.0

# Fetch the Cubical Agda Library (required for continuous open sets and topological proofs)
RUN git clone https://github.com/agda/cubical.git /opt/cubical \
    && cd /opt/cubical \
    && git checkout v0.6

# Wire BOTH libraries into Agda's global configuration
RUN mkdir -p /root/.agda \
    && echo "/opt/agda-stdlib/standard-library.agda-lib" > /root/.agda/libraries \
    && echo "/opt/cubical/cubical.agda-lib" >> /root/.agda/libraries \
    && echo "standard-library" > /root/.agda/defaults \
    && echo "cubical" >> /root/.agda/defaults

# Copy the verified compiler pipeline and EKS telemetry into the container
COPY . /artifact

# By default, drop into a bash shell so reviewers can run compile commands
CMD ["/bin/bash"]
