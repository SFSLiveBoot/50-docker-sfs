#!/bin/sh

: "${lbu:=/opt/LiveBootUtils}"
. "$lbu/scripts/common.func"

: "${pkgs:=$(sed -Ee 's/(^|[[:space:]])#.*//' "$(dirname "$0")/.pkgs" | grep -v '^$' | tr '\n' ' ')}"

: "${nvidia_repo_uri:=https://nvidia.github.io/libnvidia-container/stable/deb/$(dpkg --print-architecture)}"
: "${nvidia_gpgkey_url:=https://nvidia.github.io/libnvidia-container/gpgkey}"
: "${nvidia_pkgs:=nvidia-container-toolkit}"
: "${nvidia_keyring:=/etc/apt/keyrings/nvidia-container-toolkit.asc}"
: "${nvidia_sources:=/etc/apt/sources.list.d/nvidia-container-toolkit.sources}"
