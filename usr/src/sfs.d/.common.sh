#!/bin/sh

: ${lbu:=/opt/LiveBootUtils}
. "$lbu/scripts/common.func"

: "${dist:=$(lsb_release -cs)}"
: "${arch:=$(uname -m)}"
: "${system:=$(uname -s)}"

: "${docker_repo:=https://download.docker.com/linux/debian}"
: "${docker_repo_gpg:=$docker_repo/gpg}"
: "${docker_pkgs:=docker-ce docker-ce-cli containerd.io}"

: "${docker_compose_ver:=1.26.1}"
: "${docker_compose_bin:=/usr/local/bin/docker-compose}"
: "${docker_compose_url:=https://github.com/docker/compose/releases/download/$docker_compose_ver/docker-compose-$system-$arch}"
