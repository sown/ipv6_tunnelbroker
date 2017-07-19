#!/bin/bash
d=`dirname $0`
dir=`cd $d/../; pwd`
backuphost="backup.example.org"
backupuser="example"
if [ -f ${dir}/sbin/settings.sh ]; then
        source ${dir}/sbin/settings.sh
fi
echo "======== `date +%c` ========" >> /var/log/tunnelbroker_backup.log
/usr/bin/rsync -azP ${dir} ${backupuser}@${backuphost}: >> /var/log/tunnelbroker_backup.log 2>&1
