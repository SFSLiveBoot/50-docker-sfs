#!/bin/sh

# Install the docker daemon (docker-ce CLI and required dependencies come
# in as dependencies) into $DESTDIR, built as an SFS module with e.g.:
#   lbu_cli.py rebuild-sfs 50-docker.sfs https://github.com/SFSLiveBoot/50-docker-sfs.git
# Build parameters:
#   ADD_NVIDIA=1    also install NVIDIA container toolkit and preconfigure
#                   docker for it (daemon.json)

set -e

sfs_d="$(dirname "$0")"
. "$sfs_d/.common.sh"

test -n "$DESTDIR" || { echo "Error: DESTDIR not set" >&2; exit 1; }

test -n "$pkgs" || { echo "Error: no packages defined in $sfs_d/.pkgs" >&2; exit 1; }

echo "Installing docker packages: $pkgs" >&2
"$lbu/scripts/apt-sfs.sh" "$DESTDIR" $pkgs

if test "x${ADD_NVIDIA:-}" = "x1"; then
  echo "Installing NVIDIA container toolkit (ADD_NVIDIA=1)" >&2

  mkdir -p "${nvidia_keyring%/*}"
  curl -fs "$nvidia_gpgkey_url" >"$nvidia_keyring"
  {
    echo "Types: deb"
    echo "URIs: $nvidia_repo_uri"
    echo "Suites: /"
    echo "Signed-By: $nvidia_keyring"
  } >"$nvidia_sources"

  apt-get -o APT::Get::List-Cleanup=false update
  echo "Installing nvidia container toolkit packages: $nvidia_pkgs" >&2
  "$lbu/scripts/apt-sfs.sh" "$DESTDIR" $nvidia_pkgs

  # preconfigure docker for the nvidia runtime, equivalent to
  #   nvidia-ctk runtime configure --runtime=docker --config=/etc/docker/daemon.json
  mkdir -p "$DESTDIR/etc/docker"
  cat >"$DESTDIR/etc/docker/daemon.json" <<EOF
{
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    }
}
EOF
fi

# Enable the units (maintainer scripts do not run when installing the
# packages by unpacking). The docker.service/docker.socket stay inactive
# until /var/lib/docker exists, enforced by the drop-ins of the settings
# module (ConditionPathExists=/var/lib/docker).
enable_unit() {
  local unit="$1" target="$2" unit_d
  for unit_d in "$DESTDIR/usr/lib/systemd/system" "$DESTDIR/lib/systemd/system"; do
    test ! -f "$unit_d/$unit" || break
  done
  test -f "$unit_d/$unit" || {
    echo "Error: unit file '$unit' not found in $DESTDIR" >&2
    return 1
  }
  mkdir -p "$DESTDIR/etc/systemd/system/$target"
  ln -sfn "${unit_d#$DESTDIR}/$unit" "$DESTDIR/etc/systemd/system/$target/$unit"
  echo "Enabled $unit ($target)" >&2
}

cond_enable_unit() {
  local unit="$1" target="$2"
  if test -f "$DESTDIR/usr/lib/systemd/system/$unit" -o -f "$DESTDIR/lib/systemd/system/$unit"; then
    enable_unit "$unit" "$target"
  else
    echo "Skipping \"$unit\" ($target), unit file not found" >&2
  fi
}

enable_unit docker.service multi-user.target.wants
enable_unit docker.socket sockets.target.wants
enable_unit containerd.service multi-user.target.wants

if test "x${ADD_NVIDIA:-}" = "x1"; then
  # also enable the toolkit CDI specification auto-refresh units
  # (enabled by the package maintainer scripts as upstream)
  cond_enable_unit nvidia-cdi-refresh.service multi-user.target.wants
  cond_enable_unit nvidia-cdi-refresh.path multi-user.target.wants
fi
