# Package creation tool for Kurento projects - Dockerfile
#
# This Docker image is used to generate Debian packages from Kurento projects.
# It runs [kurento-buildpackage.sh][1] from a properly configured system.
#
# [1]: https://github.com/Kurento/kurento/blob/main/ci-scripts/kurento-buildpackage.sh
#
#
# Build command
# -------------
#
# docker build [Args...] --tag kurento/kurento-buildpackage:<UbuntuCodename> .
#
#
# Build arguments
# ---------------
#
# --build-arg UBUNTU_CODENAME=<UbuntuCodename>
#
#   <UbuntuCodename> is like "focal".
#
#   Optional. Default: "focal".
#
#
# Run command
# -----------
#
# git clone https://github.com/Kurento/kurento.git
# cd kurento/server/module-core/
# docker run --rm \
#     --mount type=bind,src="$PWD",dst=/hostdir \
#     kurento/kurento-buildpackage:focal \
#         --install-kurento 7.0.0 \
#         --apt-add-repo \
#         [kurento-buildpackage arguments...]
#
#
# Run arguments
# -------------
#
# It is possible to pass arguments to the `kurento-buildpackage.sh` script in
# this image: just append them to the `docker run` call.
#
# It is strongly recommended to use '--install-kurento' and '--apt-add-repo',
# because this Docker image doesn't include any build dependencies or repos.
#
# Use '--help' to read about arguments accepted by *kurento-buildpackage*.

ARG UBUNTU_CODENAME=noble

FROM ubuntu:${UBUNTU_CODENAME}

ARG UBUNTU_CODENAME

# Configure environment:
# * DEBIAN_FRONTEND: Disable Apt interactive questions and messages
# * PYTHONUNBUFFERED: Disable Python stdin/stdout/stderr buffering
# * LANG: Set the default locale for all commands
# * PATH: Add the auxiliary scripts to the current PATH
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8 \
    PATH="/ci-scripts:${PATH}"

# Configure Apt:
# * Disable installation of recommended and suggested packages
RUN \
echo 'APT::Install-Recommends "false";' >/etc/apt/apt.conf.d/00recommends \
&& echo 'APT::Install-Suggests "false";' >>/etc/apt/apt.conf.d/00recommends

# Install a basic set of packages
# * gnupg, iproute2, zip: Tools used by various CI scripts.
RUN \
apt-get update && apt-get install --no-install-recommends --yes \
    gnupg \
    iproute2 \
    zip unzip \
&& rm -rf /var/lib/apt/lists/*

# Install an extra set of packages.
# These are basic build dependencies that end up beind required by most jobs.
RUN \
apt-get update && apt-get install --no-install-recommends --yes \
    build-essential \
    libglib2.0-dev \
    wget \
&& rm -rf /var/lib/apt/lists/*

# Install dependencies of the `kurento-buildpackage` build script
# (listed in the script header).
RUN \
apt-get update && apt-get install --no-install-recommends --yes \
    python3 python3-pip python3-setuptools python3-wheel \
    devscripts \
    dpkg-dev \
    lintian \
    git \
    openssh-client \
    equivs \
    coreutils \
&& rm -f /var/lib/man-db/auto-update \
&& rm -rf /var/lib/apt/lists/*

# Add Ubuntu debug repository key for apt-get.
RUN \
apt-get $APT_ARGS update && apt-get $APT_ARGS install --no-install-recommends --yes \
    ubuntu-dbgsym-keyring \
|| apt-key adv \
    --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv-keys F2EDC64DC5AEE1F6B9C621F0C8CAB6595FDFF622 \
&& rm -rf /var/lib/apt/lists/*

# Add Ubuntu debug repository line for apt-get.
RUN \
echo "deb http://ddebs.ubuntu.com $UBUNTU_CODENAME main restricted universe multiverse" >/etc/apt/sources.list.d/ddebs.list \
&& echo "deb http://ddebs.ubuntu.com ${UBUNTU_CODENAME}-updates main restricted universe multiverse" >>/etc/apt/sources.list.d/ddebs.list

# Configure Git user, which will appear in the Debian Changelog files
# (this is required by Git-BuildPackage)
RUN \
git config --system user.name "Kurento" \
&& git config --system user.email "kurento@openvidu.io" \
&& git config --global --add safe.directory '*'

# Install the Git-BuildPackage tool for creation of .deb files.
#RUN python3 -m pip install --upgrade gbp
RUN apt-get update && apt-get $APT_ARGS install --no-install-recommends --yes git-buildpackage

# APT_KEEP_CACHE
#
# By default, Docker images based on "ubuntu" automatically clean the Apt
# package cache. However, this breaks 'd-devlibdeps' (d-shlibs) < 0.83 so a
# workaround is needed: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=916856
#
# Also, for this image it makes sense to have a persistent cache of downloaded
# packages between runs. The user might want to set up the cache in an external
# volume or bind mount. Useful if you're doing lots of (re)builds and want to
# avoid downloading the same packages over and over again...
#
# NOTE: If you derive images from this one, you probably want to set this
# env variable again to "false".
ENV APT_KEEP_CACHE="true"

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD []
