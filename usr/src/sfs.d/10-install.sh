#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL "${docker_repo_gpg}" | sudo apt-key add -

add-apt-repository "deb [arch=amd64] $docker_repo $dist stable"
apt-get update

"$lbu/scripts/apt-sfs.sh" "$DESTDIR" $docker_pkgs

install -D -m 0755 "$(dl_file "$docker_compose_url")" "$DESTDIR$docker_compose_bin"
