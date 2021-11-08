#!/bin/bash
#version 3.0


#SN
SN=`sudo /usr/sbin/dmidecode -s system-serial-number | grep -v "#"`

#系统:system
system=`cat /etc/redhat-release | sed 's/ *$//'`

#CPU
cpu=`grep "model name" /proc/cpuinfo | sort | uniq | awk -F ": " '{print $2}'`\*`grep "physical id" /proc/cpuinfo | sort  | uniq | wc -l`


#网卡类型
giga_num=`lspci |grep -v "10 Gigabit"|grep -v 10Gb |grep "Gigabit\|1Gb" | wc -l`
ten_giga_num=`lspci |grep "10 Gigabit\|10Gb\|10-Gigabit" |wc -l `
if [ $ten_giga_num -eq 0 ] && [ $giga_num -ne 0  ]
then
        net="Gigabit nics"
elif [ $ten_giga_num -ne 0 ] && [ $giga_num -eq 0 ]
then
        net="10*Gigabit nics"
elif [ $ten_giga_num -ne 0 ] && [ $giga_num -ne 0 ]
then
        net="10*Gigabit nics"
else
        net="unknown"
fi

#网卡mode模式
if [ -f /proc/net/bonding/bond0 ]
then
        bond=`cat /proc/net/bonding/bond0  | grep "Bonding Mode" | awk -F": " '{print $2}'|awk '{print $1}'`
        if [ $bond = adaptive ] || [ $bond = load ]
        then
                net_mode=mode6
        elif [ $bond = IEEE  ]
        then
                net_mode=mode4
        elif [ $bond = fault-tolerance ]
        then
                net_mode=mode1
        else
                net_mode=unknown
        fi
else
        net_mode=no_bonding
fi
        
updateDisk(){
sed -e \
        's/222.585GB/240GBSSD/g' -e \
        's/223.062GB/240GBSSD/g' -e \
        's/278.875GB/300GB/g' -e \
        's/558.406GB/600GB/g' -e \
        's/558.375GB/600GB/g' -e \
        's/837.75GB/900GB/g' -e \
        's/837.843GB/900GB/g' -e \
        's/1.454TB/1.6TBSSD/g' -e \
        's/5.457TB/6TB/g' -e \
        's/5.456TB/6TB/g' -e \
        's/7.276TB/8TB/g' -e \
        's/8.909TB/10TB/g' -e \
        's/1.818TB/2TB/g' -e \
        's/185.75GB/200GBSSD/g' -e \
        's/287.875GB/300GBSSD/g' -e \
        's/372.0GB/400GBSSD/g' -e \
        's/744.63GB/800GBSSD/g' -e \
        's/744.625GB/800GBSSD/g' -e \
        's/893.137GB/960GBSSD/g' -e \
        's/893.75GB/960GBSSD/g' -e \
		's/446.102GB/480GBSSD/g' -e \
        's/223.0GB/240GBSSD/g'

}
updateMem(){
sed -e \
        's/81/8/'
}

######################################################################
model=`sudo /usr/sbin/dmidecode -t system | grep Manufacturer | awk '{print $2}'` 
case $model in

###DELL#################
"Dell")
#型号:model_type
        typeset -u model_type
        model_type="DELL"" "`sudo /usr/sbin/dmidecode -t system | grep Product | awk '{print $4}'` 
#raid型号和raid格式  
        raid_type=`cat /proc/scsi/scsi | grep Model |grep -v DVD|grep -v SSD| uniq | awk '{print $5}' `  
        if [ `cat /proc/scsi/scsi | grep Model |grep -v DVD|grep -v SSD| uniq | awk '{print $5}' | wc -l` = 1 ]
        then
                raid_result=`omreport storage vdisk controller=0 | grep Layout | awk '{print $3}' | sed 's/-//g'`        
                raid=`echo ${raid_result[*]}|tr " " +`
        else
                raid_result0=`omreport storage vdisk controller=0 | grep Layout | awk '{print $3}' | sed 's/-//g'`       
                raid_result1=`omreport storage vdisk controller=1 | grep Layout | awk '{print $3}' | sed 's/-//g'`   
                raid0=`echo ${raid_result0[*]}|tr " " +`
                raid1=`echo ${raid_result1[*]}|tr " " +`
                raid=$raid0"+"$raid1
        fi
#硬盘
        disk=$MegaCli_disk
        ;;


###浪潮################
"Inspur")
#型号:model_type
    model_type="INSPUR"" "`sudo /usr/sbin/dmidecode -t system | grep Product | awk '{print $3}'`
    if [ "`cat /proc/scsi/scsi | grep Model | uniq | head -1 | awk '{print $2}' | awk -F"-" '{print $1}'`"x = "PM8060"x ]
    then
#PM8060型号/raid格式/硬盘
        raid_type=`cat /proc/scsi/scsi | grep Model | uniq | head -1 | awk '{print $2}' | awk -F"-" '{print $1}' |head -1`
        raid_result=`sudo /opt/arcconf  getconfig 1 ld | grep RAID | awk -F ' level                               : ' '{print $1$2}'`
        raid=`echo ${raid_result[*]}|tr " " +`
#硬盘
        disk=$Arcconf_disk
    elif [ "`cat /proc/scsi/scsi | grep Model | uniq |grep -v PMC| head -1 | awk '{print $4}'`"x = "MR9361-8i"x ]
        then
#MR9361-8i型号/raid格式/硬盘
        raid_type=`cat /proc/scsi/scsi | grep Model | uniq |grep -v PMC| head -1 | awk '{print $4}'`
        raid_result=`sudo /opt/MegaRAID/storcli/storcli64 /c0 show | grep RW |grep RAID |awk '{print $2}'`
        raid=`echo ${raid_result[*]}|tr " " +`
#硬盘
        disk=$MegaCli_disk
    else
        raid_type=unknown
        raid_result=unknown
        raid=unknown
                disk=unknown
    fi
    ;;



###联想################
"Lenovo")
#型号:model_type
    model_type="LENOVO"" "`sudo /usr/sbin/dmidecode -t system | grep Product | awk '{print $3,$4}'`
#raid型号和raid格式
   	raid_type=`cat /proc/scsi/scsi | grep Model | uniq | awk '{print $5}' |grep -v Rev`
        raid_result=`sudo /opt/MegaRAID/storcli/storcli64 /c0 show | grep RW |grep RAID |awk '{print $2}'`
        raid=`echo ${raid_result[*]}|tr " " +`
    disk=$MegaCli_disk
        ;;

###其他品牌###
*)
    model_type=unknown
        raid_type=unknown
        raid_result=unknown
        raid=known
    ;;
esac





sudo rm -f MegaSAS.log



[[ "$model_type" =~ "DELL"  ]] &&  disk_sn=$(for i in `omreport storage pdisk controller=0 | awk '/Serial No/{print $4}'`;do echo "\"$i\"":"\"$(/opt/MegaRAID/MegaCli/MegaCli64 -PDList-aALL |grep -B 18 $i | awk '/^Coerced Size/{print $3$4}'|updateDisk)\"";done|tr '\n' ',')|| intel_disk_sn=$(for i in `/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL  |grep -v 'SEAGATE\|HGST'|awk '/^Inquiry Data/{print $3}'`;do echo "\"$i\":\"$(/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL  |  grep -B 18 $i | awk '/^Coerced Size/{print $3$4}'|updateDisk)\"";done| tr '\n' ',') 



[[ "$model_type" =~ "DELL"  ]] &&  disk_sn=$(for i in `omreport storage pdisk controller=0 | awk '/Serial No/{print $4}'`;do echo "\"$i\"":"\"$(/opt/MegaRAID/MegaCli/MegaCli64 -PDList-aALL |grep -B 18 $i | awk '/^Coerced Size/{print $3$4}'|updateDisk)\"";done|tr '\n' ',') || seagate_disk_sn=$(for i in `/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL |grep -E SEAGATE\|HGST |awk '/^Inquiry Data/{print $NF}'`;do echo "\"$i\"":"\"$(/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL |grep -B 18 $i | awk '/^Coerced Size/{print $3$4}'|updateDisk)\"";done|tr '\n' ',')

[[ "$raid_type" =~ "PM8060" ]] && disk_sn=$(for i in `/opt/arcconf  getconfig  1  pd |awk '/Serial number/{print $4}'`;do echo "\"$i\"":"\"$(/opt/arcconf getconfig 1 pd | grep -A 5 $i |grep Used | uniq -c | awk '{print $5/1024}' |sed -e 's/558/600GB/g' -e 's/838/900GB/g' -e 's/1860/2TB/g' -e 's/9310/10TB/g' -e 's/894/960GBSSD/g')\"";done|tr '\n' ',') 


mem_sn=$(for i in `dmidecode | grep -A 20 "Memory Device" | grep  'Serial Number'|awk '{print $3}'| grep -v -i NO` ;do echo "\"$i\":\"$(dmidecode | grep -A 20 "Memory Device" | grep -B 15 $i | awk '/Size/{print $2}'|cut -b 1-2|updateMem)GB\"";done| tr '\n' ',' | sed 's/,*$//')
#mem_sn=$(for i in `dmidecode | grep -A 20 "Memory Device" | grep  'Serial Number'|awk '{print $3}'| grep -v -i NO` ;do echo "\"$i\":\"$(dmidecode | grep -A 20 "Memory Device" | grep -B 15 $i | awk '/Size/{print $2}'|cut -b 1-2 |updateMem)GB\"";done| tr '\n' ',' | sed 's/,*$//')


power_sn=$(for i in `dmidecode -t 39  | awk '/Serial/{print $3}'` ;do echo "\"$i\":"\"$(dmidecode -t 39  | grep -A 5 $i | awk '/Max Power Capacity/{print $4}')W\";done| tr '\n' ',' | sed 's/,*$//')

bmc_ip=`ipmitool lan print 1 | grep -v "IP Address Source" | awk '/^IP Address/{print $4}'`

net_cart_num=`lspci | grep -c Ethernet`

#Ip=$(for i  in `ls -l /sys/class/net|egrep 'em1|bond0|eth0' | awk '/^l/{print $9}'`;do echo "\"$i"\":\"`ip addr show $i | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|uniq | grep -v -E 255$\|^255`\"|tr '\n' ',';done|sed 's/.$//')
HOSTNAME=`hostname`
Ip=$(for i  in `ls -l /sys/class/net|egrep 'em1|bond0|eth0' | awk '/^l/{print $9}'`;do echo "\"`ip addr show $i | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|uniq| grep -v -E 255$\|^255`\""|tr '\n' ',';done|sed 's/.$//')

#PORT=$(ss -lnt  | awk -F ":|:::|::1:" '{print $2}' |grep -v Port | awk '{print $1}' |sed '/^$/d'|awk '!a[$0]++' | tr '\n' ' ' | sed 's/.$//')
#PORT=$(for i in `ss -lnt  | awk -F ":|:::|::1:" '{print $2}' |grep -v Port | awk '{print $1}' |sed '/^$/d'|awk '!a[$0]++'`;do echo \""$i"\"|tr '\n' ', ';done |sed 's/,*$//')
HEIGHT=`dmidecode | awk -F ":" '/Height/{print $2}'`

#docker ps >/dev/null 2>&1
#[ $? -eq 0 ] && num=$(docker network ls | awk '/macvlan/{print $1}' | wc -l) || num=0
#[[ $num -ne 0 ]] && CONTAINER_CIDR=$(docker network inspect $(docker network ls | awk '/macvlan/{print $1}') | awk -F '"' '/Subnet/{print $4}'| tr '\n' ' '|sed 's/ *$//') && CONTAINER_IP=$(for container_ip  in $(docker ps  | awk '!/CONTAINER/{print $1}') ; do echo \""$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_ip)"\"|tr '\n' ',';done  | sed 's/,*$//')

Disk_sn=$(echo ${disk_sn} ${seagate_disk_sn} ${intel_disk_sn}|sed 's/,*$//')

#\"RAID_TYPE\":\""$raid"\",

echo "{\"SN\":\""$SN"\",\"HEIGHT\":\""$HEIGHT"\",\"HOSTNAME\":\""$HOSTNAME"\",\"IP\":"$Ip",\"BMC_IP\":\""$bmc_ip"\",\"TYPE_SPEC\":\""$model_type"\",\"SYSTEM\":\""$system"\",\"POWER\":{"$power_sn"},\"CPU\":\""$cpu"\",\"MEM_SN\":{"$mem_sn"},\"DISK\":{"${Disk_sn}"},\"RAID_SPEC\":\""$raid_type"\",\"NET_CART_TYPE\":\""$net"\",\"NET_CART_NUM\":\""$net_cart_num"\",\"BOND_TYPE\":\""$net_mode"\"}" | jq "."

