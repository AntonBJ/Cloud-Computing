#!/bin/sh
# Run cpu bench
cpubench=$(sysbench cpu --time=60 run | grep -oP 'events per second:\s*\K\d+\.\d+')
# Run memory bench with Block size=4KB and 100 TB total
memorybench=$(sysbench memory --memory-block-size=4K --memory-total-size=100T --time=60 run | grep -oP 'transferred \(\s*\K\d+\.\d+')
# Random read disk speed on file size 1 GB 
sysbench fileio --file-test-mode=rndrd --file-total-size=1G --file-num=1 --file-extra-flags=direct --time=60 prepare > /dev/null 2>&1
rndfilebench=$(sysbench fileio --file-test-mode=rndrd --file-total-size=1G --file-num=1 --file-extra-flags=direct --time=60 run | grep -oP 'read, MiB\/s:\s*\K\d+\.\d+')
sysbench fileio --file-test-mode=rndrd --file-total-size=1G --file-num=1 --file-extra-flags=direct --time=60 cleanup > /dev/null 2>&1
# sequential read disk speed on file size 1 GB 
sysbench fileio --file-test-mode=seqrd --file-total-size=1G --file-num=1 --file-extra-flags=direct --time=60 prepare > /dev/null 2>&1
seqfilebench=$(sysbench fileio --file-test-mode=seqrd --file-total-size=1G --file-num=1 --file-extra-flags=direct --time=60 run | grep -oP 'read, MiB\/s:\s*\K\d+\.\d+')
sysbench fileio --file-test-mode=seqrd --file-total-size=1G --file-num=1 --file-extra-flags=direct --time=60 cleanup > /dev/null 2>&1

# Format results to stdout
echo $(date +%s)','$cpubench','$memorybench','$rndfilebench','$seqfilebench