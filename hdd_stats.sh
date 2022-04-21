#!/usr/bin/env bash
source bj.sh

JOB_HOST=host_stats
URL_BASE=$pushgateway_url
INSTANCE_NAME=$(cat /etc/hostname)

hdd_total=0
k32_total=0
mount_hdd8t=0
mount_hdd10t=0
mount_hdd12t=0
mount_hdd14t=0
mount_hdd16t=0
mount_hdd18t=0

i=0
while _device=$(bj "$(bj "$(lsblk -Jo NAME,MOUNTPOINT,TRAN,ROTA)" blockdevices)" "$i"); do
  (( i++ ))
  $(bj "$_device" rota) || continue                              # 非旋转设备跳过
  [[ $(bj "$_device" tran) =~ "usb" ]] && continue               # usb跳过
  (( hdd_total++ ))
  _target=$(bj "$_device" mountpoint)
  _size=$(bj "$_device" size)
  _source=$(bj "$_device" path)
  _fsuse=$(bj "$_device" fsuse%)
  if [[ $(bj "$_device" mountpoint) == null ]]; then
    ii=0
    while _children=$(bj "$_device" children "$ii"); do
      (( ii++ ))
      [[ $(bj "$_children" mountpoint) == null ]] && continue
      _source=$(bj "$_children" path)
      _fsuse=$(bj "$_children" fsuse%)
      _target=$(bj "$_children" mountpoint)
    done
  fi
  [[ $_size == *"16."* ]] && (( mount_hdd18t++ ))              # 已挂载18T硬盘数量累计
  [[ $_size == *"14."* ]] && (( mount_hdd16t++ ))              # 已挂载16T硬盘数量累计
  [[ $_size == *"12."* ]] && (( mount_hdd14t++ ))              # 已挂载14T硬盘数量累计
  [[ $_size == *"10."* ]] && (( mount_hdd12t++ ))              # 已挂载12T硬盘数量累计
  [[ $_size == *"9."* ]]  && (( mount_hdd10t++ ))              # 已挂载10T硬盘数量累计
  [[ $_size == *"7."* ]]  && (( mount_hdd8t++ ))               # 已挂载8T硬盘数量累计
  _k32=$(cat $_target/logs/k32 2>/dev/null)
  if [[ ! $(grep '^[[:digit:]]*$' <<< $_k32) ]]; then _k32=0; fi
  echo "$hdd_total $_source =》$_target $_size $_fsuse ${_k32}k32"
  k32_total=$[ $k32_total+$_k32 ]
done

echo ""
echo " k32文件：$k32_total"
echo ""
echo " 18T数量：$mount_hdd18t"
echo " 16T数量：$mount_hdd16t"
echo " 14T数量：$mount_hdd14t"
echo " 12T数量：$mount_hdd12t"
echo " 10T数量：$mount_hdd10t"
echo "  8T数量：$mount_hdd8t"
echo "    合计：$hdd_total"
echo ""

if [[ -n ${pushgateway_url} ]]; then
cat << EOF | curl -X POST --data-binary @- http://${URL_BASE}/metrics/job/${JOB_HOST}/instance/${INSTANCE_NAME}
date              $(date +%Y%m%d%H%M%S)
mount_hdd8t       $mount_hdd8t
mount_hdd10t      $mount_hdd10t
mount_hdd12t      $mount_hdd12t
mount_hdd14t      $mount_hdd14t
mount_hdd16t      $mount_hdd16t
mount_hdd18t      $mount_hdd18t
hdd_total         $hdd_total
k32_total        $k32_total
EOF
fi