#!/usr/bin/env bash

JOB_FARM_STATS=farm_stats
JOB_FARM_COUNT=farm_count
URL_BASE=$pushgateway_url

ip=null
plot=0
size=0
size_unit=0
plot_total=0
size_total=0
size_total_unit=0
OLDIFS="$IFS"
IFS=$'\n'
for line in $(chia farm summary); do
  if [[ $ip != null ]]; then 
    if [[ $line =~ "plots of size" ]]; then
      plot=$(echo $line | grep -Eo "[0-9]+ plots" | tr -cd [0-9])
      size=$(echo $line | grep -Eo "size: [0-9]+\.[0-9]+" | tr -cd [0-9]+\.[0-9]+)
      if [[ $line =~ "TiB" ]]; then size_unit=0; fi
      if [[ $line =~ "PiB" ]]; then size_unit=1; fi
echo "$ip =》$plot $size $size_unit"
if [[ -n ${pushgateway_url} ]]; then
cat << EOF | curl -X POST --data-binary @- http://${URL_BASE}/metrics/job/${JOB_FARM_STATS}/instance/${ip}/farm/${farm_xch}/pool/${pool_xch}
date  $(date +%Y%m%d%H%M%S)
plot $plot
size $size
size_unit $size_unit
EOF
fi
      ip=null
    fi
  fi
  if [[ $line =~ "Remote Harvester for IP" ]]; then
    ip=$(echo $line | tr -cd "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
  elif [[ $line =~ "Plot count for all harvesters" ]]; then
    plot_total=$(echo $line | tr -cd [0-9])
  elif [[ $line =~ "Total size of plots" ]]; then
    size_total=$(echo $line | tr -cd [0-9]+\.[0-9]+)
    if [[ $line =~ "TiB" ]]; then size_total_unit=0; fi
    if [[ $line =~ "PiB" ]]; then size_total_unit=1; fi
  fi
done
IFS="$OLDIFS"

echo "$farm_xch =》$plot_total $size_total $size_total_unit"
if [[ -n ${pushgateway_url} ]]; then
cat << EOF | curl -X POST --data-binary @- http://${URL_BASE}/metrics/job/${JOB_FARM_COUNT}/instance/${farm_xch}/pool/${pool_xch}
date  $(date +%Y%m%d%H%M%S)
plot_total      $plot_total
size_total      $size_total
size_total_unit $size_total_unit
EOF
fi
