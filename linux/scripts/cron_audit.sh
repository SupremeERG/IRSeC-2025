#!/usr/bin/sh

# prints each user's crontab (if any)
for u in $(cut -d: -f1 /etc/passwd); do
	echo "---- crontab for: $u ----"
	sudo crontab -l -u "$u" 2>/dev/null || echo "(none)"
done

DEBIAN=0
if [ -f "/etc/debian_version" ]; then
	DEBIAN=1
fi

echo ---- system cron files ----
echo /etc/cron.d: $(ls /etc/cron.d)
echo /etc/cron.hourly: $(ls /etc/cron.hourly)
echo /etc/cron.daily: $(ls /etc/cron.daily)

echo ---- user cron files ----
if [ "$DEBIAN" -eq 1 ]; then
	for cronfile in $(ls /var/spool/cron/crontabs/); do
		echo /var/spool/cron/crontabs/$cronfile
	done
else
	for cronfile in $(ls /var/spool/cron/); do
                echo /var/spool/cron/$cronfile
        done
fi

