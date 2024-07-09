#!/bin/bash
echo "start clean buff/cache"
# write into disk
sync;sync;sync
sleep 20
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
echo 3 > /proc/sys/vm/drop_caches