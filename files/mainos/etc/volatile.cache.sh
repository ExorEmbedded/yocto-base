mkdir -p "/run/lock";
chown root.root /run/lock || echo "Failed to set owner -root- for -/run/lock-." >/dev/tty0 2>&1;
chmod 1777 /run/lock || echo "Failed to set mode -1777- for -/run/lock-." >/dev/tty0 2>&1 

mkdir -p "/var/volatile/log";
chown root.root /var/volatile/log || echo "Failed to set owner -root- for -/var/volatile/log-." >/dev/tty0 2>&1;
chmod 0755 /var/volatile/log || echo "Failed to set mode -0755- for -/var/volatile/log-." >/dev/tty0 2>&1 

mkdir -p "/var/volatile/tmp";
chown root.root /var/volatile/tmp || echo "Failed to set owner -root- for -/var/volatile/tmp-." >/dev/tty0 2>&1;
chmod 1777 /var/volatile/tmp || echo "Failed to set mode -1777- for -/var/volatile/tmp-." >/dev/tty0 2>&1 

mkdir -p "/var/lock/subsys";
chown root.root /var/lock/subsys || echo "Failed to set owner -root- for -/var/lock/subsys-." >/dev/tty0 2>&1;
chmod 0755 /var/lock/subsys || echo "Failed to set mode -0755- for -/var/lock/subsys-." >/dev/tty0 2>&1 

touch "/var/log/wtmp";
chown root.root /var/log/wtmp || echo "Failed to set owner -root- for -/var/log/wtmp-." >/dev/tty0 2>&1;
chmod 0664 /var/log/wtmp || echo "Failed to set mode -0664- for -/var/log/wtmp-." >/dev/tty0 2>&1 

touch "/var/run/utmp";
chown root.root /var/run/utmp || echo "Failed to set owner -root- for -/var/run/utmp-." >/dev/tty0 2>&1;
chmod 0664 /var/run/utmp || echo "Failed to set mode -0664- for -/var/run/utmp-." >/dev/tty0 2>&1 

touch "/var/run/resolv.conf";
chown root.root /var/run/resolv.conf || echo "Failed to set owner -root- for -/var/run/resolv.conf-." >/dev/tty0 2>&1;
chmod 0644 /var/run/resolv.conf || echo "Failed to set mode -0644- for -/var/run/resolv.conf-." >/dev/tty0 2>&1 

mkdir -p "/var/run/dbus";
chown messagebus.messagebus /var/run/dbus || echo "Failed to set owner -messagebus- for -/var/run/dbus-." >/dev/tty0 2>&1;
chmod 0755 /var/run/dbus || echo "Failed to set mode -0755- for -/var/run/dbus-." >/dev/tty0 2>&1 

mkdir -p "/run/nginx";
chown www.www-data /run/nginx || echo "Failed to set owner -www- for -/run/nginx-." >/dev/tty0 2>&1;
chmod 0755 /run/nginx || echo "Failed to set mode -0755- for -/run/nginx-." >/dev/tty0 2>&1 

mkdir -p "/var/log/nginx";
chown root.root /var/log/nginx || echo "Failed to set owner -root- for -/var/log/nginx-." >/dev/tty0 2>&1;
chmod 0755 /var/log/nginx || echo "Failed to set mode -0755- for -/var/log/nginx-." >/dev/tty0 2>&1 

mkdir -p "/var/run/sepermit";
chown root.root /var/run/sepermit || echo "Failed to set owner -root- for -/var/run/sepermit-." >/dev/tty0 2>&1;
chmod 0755 /var/run/sepermit || echo "Failed to set mode -0755- for -/var/run/sepermit-." >/dev/tty0 2>&1 

mkdir -p "/var/run/sshd";
chown root.root /var/run/sshd || echo "Failed to set owner -root- for -/var/run/sshd-." >/dev/tty0 2>&1;
chmod 0755 /var/run/sshd || echo "Failed to set mode -0755- for -/var/run/sshd-." >/dev/tty0 2>&1 
