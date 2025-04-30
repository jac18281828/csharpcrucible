# Stage 1: Build yamlfmt
FROM golang:1-bullseye AS go-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG TARGETARCH

# Install yamlfmt
WORKDIR /yamlfmt
RUN go install github.com/google/yamlfmt/cmd/yamlfmt@v0.16.0 && \
    strip $(which yamlfmt) && \
    yamlfmt --version

# Stage 2: C# Development Container
FROM mcr.microsoft.com/dotnet/sdk:7.0-bullseye-slim

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install OS-level dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      git \
      gnupg2 \
      unzip \
      sudo \
      pkg-config \
      zip \
      libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for development
ARG USER=csdev
RUN useradd --create-home -s /bin/bash ${USER} \
    && usermod -aG sudo ${USER} \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER ${USER}
WORKDIR /home/${USER}

# Install yamlfmt
COPY --chown=${USER}:${USER} --from=go-builder /go/bin/yamlfmt /go/bin/yamlfmt    
ENV PATH=${PATH}:/go/bin

# install dotnet-format
ENV PATH="/home/${USER}/.dotnet/tools:${PATH}"
# Install the dotnet-format global tool (latest stable version)
# Using version 5.1.250801, which is the newest release on NuGet
# Reference: https://www.nuget.org/packages/dotnet-format/5.1.250801
RUN dotnet tool install -g dotnet-format --version 5.1.250801 \
    && dotnet-format --version



# Expose default .NET watch ports
EXPOSE 5000 5001

# Labels for metadata
LABEL org.label-schema.name="csharp-dev" \
      org.label-schema.description="C# .NET SDK Development Container" \
      org.label-schema.vendor="John Cairns" \
      org.label-schema.schema-version="1.0"

# Default command: launch bash
CMD ["bash"]
