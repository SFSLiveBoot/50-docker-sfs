# 50-docker

SFS component providing the docker daemon (engine, CLI and the compose/buildx
plugins) for [SFSLiveBoot](https://github.com/SFSLiveBoot) systems.
Similar to [50-docker-cli-sfs](https://github.com/SFSLiveBoot/50-docker-cli-sfs),
but installs the server side (daemon/packages get unpacked into the SFS, no
package maintainer scripts are run).

## Rebuilding / installing

Using the `rebuild-sfs` mode of [`lbu_cli.py`](https://github.com/SFSLiveBoot/LiveBootUtils):

```
sudo /opt/LiveBootUtils/lbu_cli.py rebuild-sfs /path/to/50-docker.sfs https://github.com/SFSLiveBoot/50-docker-sfs.git
```

### Build parameters

* `ADD_NVIDIA=1` - additionally install the
  [NVIDIA container toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)
  (from the `libnvidia-container` repository into the SFS) and preconfigure
  docker to use the `nvidia-container-runtime` (`/etc/docker/daemon.json`):

  ```
  sudo /opt/LiveBootUtils/lbu_cli.py rebuild-sfs 50-docker.sfs https://github.com/SFSLiveBoot/50-docker-sfs.git ADD_NVIDIA=1
  ```

  The parameter is persisted in `usr/src/sfs.d/.env` of the built SFS, so
  subsequent rebuilds build with NVIDIA support too. Pass `ADD_NVIDIA=0` once
  to rebuild without it again. The update-check (`.get-latest-stamp`) also
  accounts for the libnvidia-container repository when enabled.

## What it provides

* `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` and
  `docker-compose-plugin` (dependencies resolved while building)
* `docker.service`, `docker.socket` and `containerd.service` enabled for boot.
  The `15-settings-sfs` component adds
  `ConditionPathExists=/var/lib/docker` drop-ins for the docker
  service/socket, so the daemon only starts once `/var/lib/docker` exists
  (i.e. on a mounted RW storage). After mounting storage, run
  `systemctl start docker.socket docker.service` to activate it.
* `create-docker-group.service` which creates the `docker` group at boot
  before `docker.socket` (which uses `SocketGroup=docker`) and before
  `create-user.service` (which adds user 1000 to the group). Access to the
  docker socket for user 1000 is granted via socket ACL by the settings
  module as well.

## Development notes

* `usr/src/sfs.d/.pkgs` - top level docker packages, dependencies are
  resolved while unpacking (without running package maintainer scripts)
* `usr/src/sfs.d/.sources`/`.repo-key-url` - the docker.com apt repository
  used while building
* `usr/src/sfs.d/10-install-docker.sh` - install script run by the builder
  (installs the packages and enables the systemd units)
* `usr/src/sfs.d/.get-latest-stamp` - used by `update-sfs` to detect new
  upstream versions
