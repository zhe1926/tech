#!/bin/bash
#==========================
# Program    : static_ip.sh
# Info       : Change DHCP ip address to static ip address use shell,Support Ubuntu and RHEL
# Author	 : Lasse
# Date		 : 20160504
# Version    : 0.1
#==========================
sleep 180
# 已配置信息的网卡个数
ETHNUM=0

# 网卡名称信息，多个网卡用#符号分隔
ETHS=""

# 网卡IP/NetMask/GateWay，用：符号分隔，多个网卡用#符号分隔
ETHINFO=""

# 网卡名称用数组存储
ETHSArray[0]=""

# 网卡IP/NetMask/GateWay，用数组存储
ETHINFOArray[0]=""

# 修改IP时原IP所在网卡在数组中的索引
ETHINDEX=0

# 网卡文件路径
RHELNETPATH="/etc/sysconfig/network-scripts"
DEBIAN="/etc/network"

# 系统版本
RHELVS=`cat /proc/version |egrep -i '(centos|red hat)' 2>&1 > /dev/null;echo $?`
DEBIANVS=`cat /proc/version |egrep -i '(ubuntu|debian)' 2>&1 > /dev/null;echo $?`

# 获取网卡信息，并存储到数组中
rhelStaticIP()
{
	typeset ethList="";
	typeset ethaddr="";
	typeset ethmask="";
	typeset gateway="";
	typeset ethinfo="";

	# 获取所有网卡信息,使用ls /sys/class/net也可以
	ethList=`ip -o link show|awk -F': ' '{print $2}'|grep -v 'lo'` 

	# 循环所有网卡
	for eth in ${ethList}
	do
		#获取网卡IP
		ethaddr=`ip addr show dev ${eth}|grep '\<inet\>'|awk '{print $2}'|awk -F'/' '{ print $1 }'`
		ethmask=`ip addr show dev ${eth}|grep '\<inet\>'|awk '{print $2}'|awk -F'/' '{ print $2 }'`

		#能够获取网卡和掩码
		if [ "-$ethaddr" != "-" ]
		then
			# 获取网卡默认网关
			gateway=`ip route|grep default.*via.*${eth}|awk '{print $3}'`

			# 将网卡的信息拼成字符串
			ethinfo="${eth}:${ethaddr}:${ethmask}:${gateway}"

			ETHSArray[$ETHNUM]="$eth"

			ETHINFOArray[$ETHNUM]="$ethinfo"
			
			ETHNUM=`expr $ETHNUM + 1`
cat > $RHELNETPATH/ifcfg-${eth} <<EOF
DEVICE="${eth}"
BOOTPROTO="none"
IPV6INIT="yes"
MTU="1500"
NM_CONTROLLED="no"
ONBOOT="yes"
TYPE="Ethernet"
IPADDR="${ethaddr}"
PREFIX="${ethmask}"
EOF
		if [ "-$gateway" != "-" ]
		then
			cat >> $RHELNETPATH/ifcfg-${eth} <<EOF
GATEWAY="${gateway}"

EOF
		fi
			# ETHS为空字符串
			if [ "-$ETHS" == "-" ]
			then
				ETHS="${eth}"
			else
				ETHS="${ETHS}#${eth}"
			fi

			# ETHINFO为空字符串
			if [ "-$ETHINFO" == "-" ]
			then
				ETHINFO="${ethinfo}"
			else
				ETHINFO="${ETHINFO}#${ethinfo}"
			fi
		fi
	done
	return 0

}

debianStaticIP()
{
	typeset ethList="";
	typeset ethaddr="";
	typeset ethmask="";
	typeset gateway="";
	typeset ethinfo="";

	# 获取所有网卡信息,使用ls /sys/class/net也可以
	ethList=`ip -o link show|awk -F': ' '{print $2}'|grep -v 'lo'` 

	# 循环所有网卡
	for eth in ${ethList}
	do
		#获取网卡IP
		ethaddr=`ip addr show dev ${eth}|grep '\<inet\>'|awk '{print $2}'|awk -F'/' '{ print $1 }'`
		ethmask=`ifconfig ${eth}|grep -i mask |awk -F':' '{ print $NF }'`

		#能够获取网卡和掩码
		if [ "-$ethaddr" != "-" ]
			then
				# 获取网卡默认网关
				gateway=`ip route|grep default.*via.*${eth}|awk '{print $3}'`

				# 将网卡的信息拼成字符串
				ethinfo="${eth}:${ethaddr}:${ethmask}:${gateway}"

				ETHSArray[$ETHNUM]="$eth"
				ETHINFOArray[$ETHNUM]="$ethinfo"
				ETHNUM=`expr $ETHNUM + 1`

				ETHEXISTS=`cat /etc/network/interfaces|grep -i ${eth}.*dhcp 2>&1 > /dev/null;echo $?`
				ETHSTATIC=`cat /etc/network/interfaces|grep -i ${eth}.*static 2>&1 > /dev/null;echo $?`
				if [ $ETHEXISTS == '0' ]
					then
						sed -i 's/dhcp/static/' $DEBIAN/interfaces
cat >> $DEBIAN/interfaces <<EOF
address ${ethaddr}
netmask ${ethmask}
EOF
				elif [ "$ETHSTATIC" == '0' ]
					then
						return 0
				else
cat >> $DEBIAN/interfaces <<EOF
auto ${eth}
iface ${eth} inet static
address ${ethaddr}
netmask ${ethmask}
EOF
				fi

		if [ "-$gateway" != "-" ]
			then
cat >> $DEBIAN/interfaces <<EOF
gateway ${gateway}
EOF
		fi

		# ETHS为空字符串
		if [ "-$ETHS" == "-" ]
			then
				ETHS="${eth}"
			else
				ETHS="${ETHS}#${eth}"
		fi

		# ETHINFO为空字符串
		if [ "-$ETHINFO" == "-" ]
			then
				ETHINFO="${ethinfo}"
			else
				ETHINFO="${ETHINFO}#${ethinfo}"
		fi

		fi
	done
	return 0

}

# 判断系统版本
if [ "$RHELVS" == "0" ]
	then
		rhelStaticIP
	elif [ "$DEBIANVS" == "0" ]
	then
		debianStaticIP
fi
rm -f /etc/init.d/static_ip.sh
