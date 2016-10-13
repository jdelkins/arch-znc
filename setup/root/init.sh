#!/bin/bash

# exit script if return code != 0
set -e

# set user nobody to specified user id (non unique)
usermod -o -u "${PUID}" nobody
echo "[info] Env var PUID defined as ${PUID}"

# set group users to specified group id (non unique)
groupmod -o -g "${PGID}" users
echo "[info] Env var PGID defined as ${PGID}"


# Build modules from source.
if [ -d "/config/modules" ]; then
  # Store current directory.
  cwd="$(pwd)"

  # Find module sources.
  modules=$(find "/config/modules" -name "*.cpp")

  # Build modules.
  for module in $modules; do
    echo "[info] Building module $module..."
    cd "$(dirname "$module")"
    znc-buildmod "$module"
  done

  # Go back to original directory.
  cd "$cwd"
fi

# Create default config if it doesn't exist
if [ ! -f "/config/configs/znc.conf" ]; then
  echo "[warn] Creating a default configuration, this will need to be modified"
  mkdir -p "/config/configs"
  cp /root/znc.conf.default "/config/configs/znc.conf"
fi

# Make sure /config is owned by znc user. This effects ownership of the
# mounted directory on the host machine too.
echo "[info] Setting necessary permissions..."
chown -R nobody:users /config

# set permissions inside container
if [[ -n $PIPEWORK_WAIT ]]; then
	echo "[info] Waiting on interface eth1 to come up"
	/root/pipework --wait
fi

echo "[info] Starting Supervisor..."

# run supervisor
umask 002
"/usr/bin/supervisord" -c "/etc/supervisor.conf" -n
