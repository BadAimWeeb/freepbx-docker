#!/usr/bin/env bash
set -e

ensure_freepbx_cli_links() {
  local cli_name target_path

  for cli_name in fwconsole amportal; do
    target_path="/var/lib/asterisk/bin/${cli_name}"
    if [[ -e "$target_path" ]]; then
      ln -sfn "$target_path" "/usr/sbin/${cli_name}"
    fi
  done
}

# If FreePBX is installed (by detecting fwconsole), trigger start of FreePBX service to ensure all services are running
make_sure_freepbx_is_running() {
  if [[ -x /usr/sbin/fwconsole ]]; then
    echo "FreePBX detected, ensuring FreePBX services are running (including Asterisk)..."
    /usr/sbin/fwconsole start || true
  else
    echo "FreePBX not detected, running Asterisk only."
    /usr/local/src/freepbx/start_asterisk start
  fi
}

ensure_freepbx_cli_links

# Restoring backup of Opus and third-party documentation
if [[ -d /image_backup/asterisk_documentation_thirdparty ]]; then
  echo "Restoring backup of Opus and third-party documentation..."
  cp -r /image_backup/asterisk_documentation_thirdparty/*.* /var/lib/asterisk/documentation/thirdparty/
fi

# Start cron
/usr/sbin/cron &

# Start postfix email service
service postfix start

# Start Asterisk & FreePBX service
make_sure_freepbx_is_running &

exec apache2ctl -D FOREGROUND
