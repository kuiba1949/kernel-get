#!/bin/bash
## coding: utf-8
#  auto download (and install) kernel packages (.deb),
#  from Ubuntu PPA
#
## filename: kernel-get
## original filename: kernel-get.sh
#
## auto download kernel packages (.deb) from:
## http://kernel.ubuntu.com/~kernel-ppa/mainline/
#
## get lastest kernel version informations from:
#  (include: mainline, stable, longterm)
## https://www.kernel.org/

## 2017-1-13, v1.1-5 updated by Careone <emacslocale@126.com>
## 2018-3-19, updated by Careone 

### new defines for ver 2.0, 2018-3 ###
APPNAME="kernel-get"
APPVER="2.0.5"
prefix="http://kernel.ubuntu.com/~kernel-ppa/mainline"
URL_KERNEL_PPA="http://kernel.ubuntu.com/~kernel-ppa/mainline"
URL_KERNEL_ORG="https://www.kernel.org"
URL_ADD=

#SHARE_DIR="/usr/local/share/kernel-get"
SAVETO="$HOME/kernel"

## defines for wget
declare -i id TIMES=3 TIMEOUT=30

## sample linux kernel SUBDIR in "$prefix"
SAMPLE_VER="v3.16.55"
SUBDIR=		#subdir in http://kernel.ubuntu.com/.../mainline/
PKGFMT="deb" #now support .deb only, not for .rpm and others
ALL="all"	# 'all' for .deb; and 'noarch' for .rpm (TODO)
SUFFIX="$PKGFMT.list"

## ARCH: i386, amd64, all (for .deb). can auto probe and update
ARCH=`uname -m`
  case "$ARCH" in
    i?86)ARCH="i386" ;;
    *) : ;;	
  esac

declare -a pkglist	# kernel resource files
declare -a kver		# kernel versions
declare -a kdesc		# kernel descriptions

declare -a src	#url to download kernel packages

declare -a tmp	#tmp array

  declare -a linux_image	# linux-images files for current arch
  declare -a linux_headers	# linux-headers files for current arch
  declare -a linux_headerall	# linux-headers files for all/noarch arch
  declare -a imgver	# linux_image versions, such as general, lowlatency

PROBE_KVER=`uname -r | cut -d'.' -f1-2`
## example: uname -r
# 3.16.0-4-686-pae 
# 3.16

  ### defines for TAG 750
  declare -i LINE1=25 LINE2=32
  declare -i SLEEP1=1 SLEEP3=3

    declare -a arch_result sed_line 
    # id: 0-1, example: arch_result=( i386 succeeded )
    # id: 0-1, example: sed_line=( 25 32 )
    
### defines for option --kernels ###   
declare -a lts 
## 数组 lts[@]: LTS 长期支持的内核版本。数据截止 2018-3-15
# --lts 选项会自动联网读取并生成文件，再更新 lts[@], MAINLINE, STABLE 数值
lts=( 3.2 3.16 3.18 4.1 4.4 4.9 4.14 )
MAINLINE='4.16'
STABLE='4.15'

## command examples:
# html2text -width 999 kernel-org.htm > kernel-org.txt
# grep --color=auto -E "longterm|stable|mainline" kernel-org.txt | cut -d'[' -f1 > kernel-lts.txt
# grep ... | sed '/\[tarball/s//\n&/' | grep -v "\[tarball\"
## https://www.kernel.org/
#  
#mainline:  4.16-rc5 2018-03-12
#stable:    4.15.10  2018-03-15
#  
#longterm:  4.14.27  2018-03-15
#longterm:  4.9.87   2018-03-11
#longterm:  4.4.121  2018-03-11
#longterm:  4.1.50   2018-03-05
#longterm:  3.18.99 [EOL]
#longterm:  3.16.55  2018-03-03
#longterm:  3.2.100  2018-03-03

### ---------
### file name defines for option
declare -a fn #file name, id 0-8;
## path: $HOME/kernel/list/

## defines for: $0 v3.16
#fn[0]="$1.htm"
#fn[1]="$1.$PKGFMT.list"
#fn[2]="$1.log"
## examples
##fn[0]="v3.16.55.htm"
##fn[1]="v3.16.55.deb.list"
##fn[2]="v3.16.55.log"

## defines for option --kernel
fn[4]="kernel-ppa.htm"
fn[5]="kernel-ppa.txt"
#file6=`mktemp -u`	#tmp file

## defines for option --longterm
fn[7]="kernel-org.htm"
fn[8]="kernel-org.txt"

## fn[3], fn[6], : not used yet

if [ ! -d "$SAVETO/list/" ]; then
  mkdir -p "$SAVETO/list"
fi

if [ ! -d "$SAVETO/$PKGFMT/" ]; then
  mkdir -p "$SAVETO/$PKGFMT"
fi
## -------

### debug switches ###
## 1: show debug info (for develop and debug only); 0: not show
DEBUG=0

TODO=1	# 1: todo; 0: done and can be enabled
### ----------- ###


## defun 1
# Usage: 
# Print the usage.
	_usage_en () {
cat <<EOF
Usage: $APPNAME
       $APPNAME [KERNEL_VERSION]
       $APPNAME [OPTION]
Example: $APPNAME $SAMPLE_VER 
download Linux kernel .$PKGFMT packages from web URL:
  $prefix/  
 
OPTIONS
  --lts, --longterm
        fetch latest kernel version infomation from
        $URL_KERNEL_ORG
  -k, --kernels    fetch kernel version list from
        $URL_KERNEL_PPA/
  -t, --tips       print the tips and exit
  -v, --version    print the version information and exit
  -h, --help       print this message and exit
EOF
}

## defun 2
	_usage_cn () {
cat <<EOF
用法: $APPNAME
      $APPNAME 内核版本号
      $APPNAME [选项]
示例: $APPNAME $SAMPLE_VER
  从网络下载（并安装）Linux 内核 .$PKGFMT 软件包。来源:
  $prefix/

选项
  --lts, --longterm
    从 $URL_KERNEL_ORG/ 获取最新的内核版本号信息
  -k, --kernels
    从 $URL_KERNEL_PPA/
    获取可下载的内核版本号名称
  -t, --tips       显示使用技巧提示并退出
  -v, --version    显示版本信息并退出
  -h, --help       显示帮助信息并退出
EOF
}

## defun 3
	_about () {
  cat <<EOF
Homepage: https://github.com/kuiba1949/kernel-get/

Please report bugs to Careone <emacslocale@126.com>.
EOF
}

## defun 4
_makeSample () {
cat <<EOF
$prefix/$SAMPLE_VER/
description=sample, $(date '+%Y-%m-%d %H:%M:%S') created

linux-headers-3.16.55-031655_3.16.55-031655.201803041545_all.deb
linux-headers-3.16.55-031655-generic_3.16.55-031655.201803041545_amd64.deb
linux-headers-3.16.55-031655-generic_3.16.55-031655.201803041545_i386.deb
linux-image-3.16.55-031655-generic_3.16.55-031655.201803041545_amd64.deb
linux-image-3.16.55-031655-generic_3.16.55-031655.201803041545_i386.deb
EOF
}

### defun 5 # not used yet


### defun 6
	_tips_en () {
cat<<EOF
  tips: there's 2 methods to run:
    method 1: run '$APPNAME' whit kernel version number, 
      for example: '$APPNAME v3.16.55'
      and then, run '$APPNAME' whitout any option to download
      kernel packages (from list)
      (notice: need network connection!)

    method 2: run '$APPNAME --lts -k' 
      to fetch lastest kernel version data, and then
      run '$APPNAME' (whitout any option!)
EOF
}

### defun 7
	_tips_cn () {
cat<<EOF
  $APPNAME 使用提示: 
      有两种方式来下载（和安装）内核软件包：
      普通用户只能下载，不能安装！
      root用户在下载完成后，可以选择：是否直接安装内核包。
  方式1: 直接输入带有内核版本号的命令，如
      $APPNAME v3.16.55
      注意：版本号数字前面，要加一个小写字母 v 。
      这样是为了匹配网站上的内核子目录名称。联网后，会自动生成数据文件。
      下一步再继续运行不带参数的 $APPNAME ，选择要下载的内核版本。

  方式2: 如果不确定内核版本号是多少，可以先运行
      '$APPNAME --lts -k'
      来查看可用的版本号（需要连接网络），然后再运行不带参数的
      $APPNAME ，选择要下载的内核版本。

  说明：运行命令时，如果带有选项（如 -a, -k, --lts ），
      或者版本参数（如 v3.16.55），只能联网下载信息并生成数据文件，
      不会直接下载软件包；
	  如果需要下载内核软件包，请直接运行 $APPNAME 
      不要带参数！ 
EOF
}

## ===============

## PART 2: main
# Check the arguments.

if [ "$#" -eq 0 ]; then

## tag 010: probe package format
## --------------------
case `uname -n` in
  ubuntu | debian | linuxmint | lmde | linuxdeepin | ubuntukylin)
  PKGFMT="deb"	#may in *.deb and *.udeb format?
  ALL="all"
	;;
  *)
if which apt-get &>/dev/null && which dpkg &>/dev/null; then
  PKGFMT="deb"
  ALL="all"
elif which rpm &>/dev/null || which yum &>/dev/null; then
  PKGFMT="rpm"	#may in *.rpm or *.drpm format?
  ALL="noarch"

 	TODO=1
  if [ "$TODO" = 1 ]; then
  echo -n "  unsupport Linux release `uname -n`." 1>&2
  echo -n " (support Debian/Ubuntu and similar DEB serious Linux only.)" 1>&2
  echo "  abort." 1>&2
  exit 0
  fi
else 
  PKGFMT="other"
  echo -n "  unsupport Linux release `uname -n`." 1>&2
  echo -n " (support Debian/Ubuntu and similar DEB serious Linux only.)" 1>&2
  echo "  abort." 1>&2
  exit 0
fi
	;;
esac

# tag d020: probe current headware arch
  case `uname -m` in
    i?86)ARCH="i386" ;;
    amd64)ARCH="amd64" ;;

    powerpc)ARCH="powerpc" ;;
    armel)ARCH="armel" ;;
    armhf)ARCH="armhf" ;;
    mips)ARCH="mips" ;;
    mipsel)ARCH="mipsel" ;;
    ia64)ARCH="ia64" ;;

    sparc)ARCH="sparc" ;;
    s390)ARCH="s390" ;;
    s390x)ARCH="s390x" ;;

    *)ARCH="unknown-arch"; echo "  Error: unsupported hardware ARCH '$ARCH'" ;;
  esac
## --------------------


  ## tag d025: probe current Linux release and package format
  ## PKGFMT: package format
  echo " * download (and install) kernel *.$PKGFMT packages from:"
  echo "   $prefix/"
  
  ## old method: show OS id in lowercase, such as "ubuntu"
  # echo "  current kernel version: `uname -n` `uname -m`, `uname -r`"
  #
  ## new method: show OS id with frist uppercase, such as "Ubuntu"
  echo "   check OS and kernel version:"
  #echo "  `lsb_release -sd` (`lsb_release -sc`), `uname -m`, `uname -r`"
  #
  echo "   `lsb_release -sd`, `uname -m`, `uname -r`"
  # sample output: Debian GNU/Linux 7.5 (wheezy), i686, 3.14.5-031405-generic

  echo
#  echo "Tips: download .DEB packages from:"
#  echo "  $prefix/"
#  echo
	# tag d030: get kernel list to download
	
	echo " ** check available kernel list files..."
	#echo "   User:   $SAVETO/list/*.$PKGFMT.list"
	echo "    files: $SAVETO/list/*.$PKGFMT.list"
		
		if [ ! -s "$SAVETO/list/sample.$SUFFIX" ]; then
		  echo "   creating a SAMPLE kernel .$SUFFIX file..."
		    _makeSample > "$SAVETO/list/sample.$SUFFIX"
		fi

		#IFS=$'\n'
#pkglist=( `ls -1 "$SAVETO/list/"*.$SUFFIX` `ls -1 "$SHARE_DIR/list/"*.$SUFFIX` )
	pkglist=( `ls -1 "$SAVETO/list/"*.$SUFFIX` )

	## get arrays: list-files, kernel-versions, kernel-descriptions

	# probe and remove null/unreadable/void files from array
	
	#echo "   Global: $SHARE_DIR/list/*.$SUFFIX"
		sleep $SLEEP1
		echo

	id=1	#init

	for a in `seq 1 "${#pkglist[@]}"`; do
	  let "b = a -1"
if grep -i "linux-image" "${pkglist[b]}" 2>/dev/null | grep -i "$ARCH" &>/dev/null; then
# if [ -r "${pkglist[b]}" ] && [ -s "${pkglist[b]}" ] && grep -i "linux-image" "${pkglist[b]}" 2>/dev/null &>/dev/null; then
	      echo "  found: $id* '${pkglist[b]}'"
	     else
		echo -e "  ignore: '$pkglist{[b]}'\t(unreadable or void)" 1>&2
		unset pkglist[b] ; continue ;
	     fi
		 ## add a new line after every 4 lines
		N="$(($id % 4))"

		if [ "$N" = 0 ]; then
		  echo
		fi
		
		let "id += 1"
	   	
	done

	#
	for a in `seq 1 "${#pkglist[@]}"`; do
	  let "b = a -1"

	## get kernel resources and versions from filename string
	# samples:
	# source 1:
	# for ubuntu daily
	# http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.8-trusty/
	# linux-image-3.13.8-031308-generic_3.13.8-031308.201403311335_i386.deb

	# source 2:
	# http://mirrors.163.com/ubuntu/pool/main/l/linux/
	# for ubuntu 14.04 lts
	# linux-image-generic-lts-trusty_3.13.0.23.27_i386.deb	#normal filename style
	# linux-image_3.11.0.19.20_i386.deb	#special filename style

	# source 3:
	# http://mirrors.163.com/debian/pool/main/l/linux/
	# for debian sid, 2014-03
	# linux-image-3.13-0.bpo.1-486_3.13.7-1~bpo70+1_i386.deb
	#
	src[b]=`grep -i "http://" "${pkglist[b]}" 2>/dev/null | head -1 | sed '/#/s///g' | tail -1 | sed '/\/$/s///'`

	## sample:
	#kver[b]=`grep -i "linux-image" "${pkglist[b]}" 2>/dev/null | grep -i "\_$ARCH\.$PKGFMT" | sed "/linux-image/s//\nlinux-image/g;/_$ARCH\.$PKGFMT/s//_$ARCH\.$PKGFMT\n/g" | grep "linux-image" | sort | uniq | head -1 | cut -d'e' -f2- | sed '/./s///' | cut -d_ -f1`

	KFILE="linux-image"
	FARCH="$ARCH"	#File architecture
	kver[b]=`grep -i "$KFILE" "${pkglist[b]}" 2>/dev/null | grep -i "\_$FARCH\.$PKGFMT" | sed "/$KFILE/s//\n$KFILE/g;/_$FARCH\.$PKGFMT/s//_$FARCH\.$PKGFMT\n/g" | grep "$KFILE" | sort | uniq | head -1 | cut -d'e' -f2- | sed '/./s///' | cut -d_ -f1`

	## todo
	## need edit to auto pick the latest kernel, now is force to pick
	#  version 3.13, with code 'grep 3.13'
#kver[b]=`grep -i "$KFILE" "${pkglist[b]}" 2>/dev/null | grep -i "\_$FARCH\.$PKGFMT" | sed "/$KFILE/s//\n$KFILE/g;/_$FARCH\.$PKGFMT/s//_$FARCH\.$PKGFMT\n/g" | grep "$KFILE" | sort | uniq | grep -i "3\.13" | head -1 | cut -d'e' -f2- | sed '/./s///' | cut -d_ -f1`

	#$ grep linux-image ubuntu.ls-lR.2014-04-12.*.list | cut -d_ -f2 | sort | cut -d. -f1-2 | uniq | sort | uniq
	
## TAG 320:

imgver=( `grep "$KFILE" "${pkglist[b]}" 2>/dev/null | cut -d_ -f2 | sort | cut -d. -f1-2 | uniq | sort | uniq` )
	# grep "[-\.~]"
	# sed '/[-~]/s//./g'


        # sample:
	# linux-image-generic-lts-trusty_3.13.0.23.27_i386.deb
        #             |---- kver -----| |-- kdesc -|
	#
        # linux-image_3.11.0.19.20_i386.deb
        #           > kver & kdesc <

	if [ -z "${kver[b]}" ]; then
	  kver[b]="unknown-version"
	  #echo "  Error: void kernel list file '${pkglist[b]}'. skip." 1>&2
	  #exit 1;
	fi

	# get kernel description from list file, method 1
	  kdesc[b]=`grep -i "description=" "${pkglist[b]}" 2>/dev/null | head -1 | cut -d= -f2 | sed '/\"/s///g;/'\''/s///g'`
	# get descrition from linux-image filename, method 2
	#`grep -i "\.deb" "${pkglist[b]}" 2>/dev/null | head -1 | cut -d= -f2 | sed '/\"/s///g;/'\''/s///g'`
        # sample: linux-image-3.13.8-031308-generic_3.13.8-031308.201403311335_i386.deb
        #    	                                    --------------------------
	# output: 3.13.8-031308.201403311335

	# $ grep i386.deb *ubuntu*.list | grep linux-image | grep "\-generic_" | grep 3.13

	if [ -z "${kdesc[b]}" ]; then
	  kdesc[b]=`grep -i "linux-image" "${pkglist[b]}" 2>/dev/null | head -1 | cut -d_ -f2`
	fi

	# if not find filename linux-image.* string in kernel list file,
	if [ -z "${kdesc[b]}" ]; then
	  kdesc[b]="?"
	  #echo "  Error: void kernel list file '${pkglist[b]}'. abort." 1>&2
	  #exit 1;
	fi

	done

	# -----
	echo

	# tag d040: show available kernel lists with versions and descriptions
	case "$2" in
	 * | "")echo "please select a kernel version to download (or press number 0 to quit):"

		for id in `seq 1 "${#pkglist[@]}"`; do
		 let "n = id - 1"
		 echo -e "  $id* ${kver[n]}\t(${kdesc[n]})"

		 ## add a new line after every 4 lines
		N="$(($id % 4))"

		if [ "$N" = 0 ]; then
		  echo
		fi
		done

		echo -en "\t[0-${#pkglist[@]}] "

		until [ "$KID" != "" ]; do	
		  read KID DESC
		  #KID = kernel id, and DESC used to throw bad strings inputed.
		  case "$KID" in
		    0* | [nN]* | [qQ]* | [xX]*)echo "  quit."
		      exit 0 ;
			;;
		    *[^0-9]*)KID="" ;
		      echo -en "  bad id number. please retry: " # continue ;
			;;
		    [[:digit:]]): ;;
		    *)echo "  error: void id number. quit." 1>&2
		      exit 1 ;
			;;
		  esac
		done

		# tag d045: check inputed id isn't out of range
		if [ "$KID" -le "${#pkglist[@]}" ] && [ "$KID" -ge 1 ];then
		  let "m = KID - 1"
	        else echo "  error: void id number. quit." 1>&2
		  exit 1
		fi

		;;
	*)
	# todo: need more code to do something if kernel-list files given
	echo "  Error (E415): unknown error. quit." 1>&2
	exit 1

	 shift
	 pkglist=( "$@" )

	;;
	esac

	id=1	#init

  echo -e "download kernel packages from:\n\t${src[m]}/"
  echo "* check available packages to download..."

### tag d050: show files found in list file which need to download
  ## kernel related files
  # file 1/3: linux-image* for i386/amd64/...
  KFILE="linux-image"
  FARCH="$ARCH"	#kernel file arch
  echo "** package (for $FARCH): $KFILE"
  linux_image=( `grep -i "$KFILE" "${pkglist[m]}" 2>/dev/null | grep -i "_$FARCH\.$PKGFMT" | sed "/$KFILE/s//\n$KFILE/;/_$FARCH\.$PKGFMT/s//_$FARCH.$PKGFMT\n/" | grep -i "$KFILE"` )


## files numbers not limited
  for a in "${linux_image[@]}"; do
    echo -e "  $id $a"

## files numbers limited to 4 max to keep your hard disk safe
#  for a in `seq 0 3`; do
#    echo -e "  $id ${linux_image[a]}"

    let "id += 1"
  done
  echo

###
  # file 2/3: linux-headers* for i386/amd64/...
  KFILE="linux-headers"
  FARCH="$ARCH"	#kernel file arch
  echo "** package (for $FARCH): $KFILE"
  linux_headers=( `grep -i "$KFILE" "${pkglist[m]}" 2>/dev/null | grep -i "_$FARCH\.$PKGFMT" | sed "/$KFILE/s//\n$KFILE/;/_$FARCH\.$PKGFMT/s//_$FARCH.$PKGFMT\n/" | grep -i "$KFILE"` )

## files numbers not limited
  for a in "${linux_headers[@]}"; do
    echo -e "  $id $a"

## files numbers limited to 4 max to keep your hard disk safe
#  for a in `seq 0 3`; do
#    echo -e "  $id ${linux_headers[a]}"

    let "id += 1"
  done
  echo

###
  # file 3/3: linux-headers* for all/noarch...
  KFILE="linux-headers"
  FARCH="$ALL"	#kernel file arch
  echo "** package (for $FARCH): $KFILE"
  linux_headerall=( `grep -i "$KFILE" "${pkglist[m]}" 2>/dev/null | grep -i "_$FARCH\.$PKGFMT" | sed "/$KFILE/s//\n$KFILE/;/_$FARCH\.$PKGFMT/s//_$FARCH.$PKGFMT\n/" | grep -i "$KFILE"` )

## files numbers not limited
  for a in "${linux_headerall[@]}"; do
    echo -e "  $id $a"

## files numbers limited to 4 max to keep your hard disk safe
#  for a in `seq 0 3`; do
 #   echo -e "  $id ${linux_headerall[a]}"

    let "id += 1"
  done
  echo

 #echo "L298 ---------------------"
 #exit 0
## tag d055: start download
  echo "* start downloading (save to '$SAVETO/$PKGFMT/${kver[m]}/')..."
  id=1 	#init
  	if [ ! -d "$SAVETO/$PKGFMT/${kver[m]}/" ]; then
	  mkdir -p "$SAVETO/$PKGFMT/${kver[m]}/"
	fi

  # ---- show packages need download, usually need 3 files (example for i386):
  # linux-image*_i386.deb
  # linux-headers*_i386.deb
  # linux-headers*_all.deb

  for a in "${linux_image[@]}"; do
    echo "**  package $id: ($a)"
    echo

	if [ "$DEBUG" = 1 ];then
	  echo "L333: linux-image='$SAVETO/$PKGFMT/${kver[m]}/$a'"
	else
    	  wget -c "${src[m]}/$a" -O "$SAVETO/$PKGFMT/${kver[m]}/$a"
	fi
    let "id += 1"
  done

  for a in "${linux_headers[@]}"; do
    echo "**  package $id: ($a)"
    echo
	if [ "$DEBUG" = 1 ];then
	  echo "L360: linux-headers='$SAVETO/$PKGFMT/${kver[m]}/$a'"
	else
    	  wget -c "${src[m]}/$a" -O "$SAVETO/$PKGFMT/${kver[m]}/$a"
	fi
    let "id += 1"
  done

  for a in "${linux_headerall[@]}"; do
    echo "**  package $id: ($a)"
    echo
	if [ "$DEBUG" = 1 ];then
	  echo "L346: linux-headers_all='$SAVETO/$PKGFMT/${kver[m]}/$a'"
	else
    	  wget -c "${src[m]}/$a" -O "$SAVETO/$PKGFMT/${kver[m]}/$a"
	fi
    let "id += 1"
  done
  # ----

  if ls "$SAVETO/$PKGFMT/${kver[m]}/${linux_image[0]}" 2>/dev/null &>/dev/null; then
    echo
    echo "* available kernel packages in '$SAVETO/$PKGFMT/${kver[m]}/':"

    #ls "$SAVETO/$PKGFMT/${kver[m]}/linux-image"*"_$ARCH.$PKGFMT" "$SAVETO/$PKGFMT/${kver[m]}/linux-headers"*"_$ARCH.$PKGFMT" 2>/dev/null

    ls "$SAVETO/$PKGFMT/${kver[m]}/linux-image"*"_$ARCH.$PKGFMT" "$SAVETO/$PKGFMT/${kver[m]}/linux-headers"*"_$ARCH.$PKGFMT" "$SAVETO/$PKGFMT/${kver[m]}/linux-headers"*"_$ALL.$PKGFMT" 2>/dev/null | cat -n
  else
    echo "  Error: no downloaded kernel package found in '$SAVETO/$PKGFMT/${kver[m]}/'. quit." 1>&2
    exit 1
  fi
    echo
    echo "  [notice] you can install kernel packages later!"

  if ls -1 "$SAVETO/$PKGFMT/"* &>/dev/null; then
    echo " * show downloaded kernel packages:"
    echo "   ------------------"
    ls -1 "$SAVETO/$PKGFMT/"* | cat -n
    echo "   ------------------"
  fi

## install downloaded packages
	echo
	echo "* ready to install downloaded kernel packages..."
	echo -en "  press Y to install new kernel, or N to exit: [y/N]\t"

 [ `whoami` = "root" ] || { echo -e "\n\troot please!"; exit 0; }
	read YES_OR_NO DESC
	case "$YES_OR_NO" in
	  [Yy]*): ;;
	  [Nn]* | '' | *)exit 0 ;;
	esac

  #,fuzzy: linux_image[@] or linux_image[0] ?
  if ls "$SAVETO/$PKGFMT/${kver[m]}/${linux_image[0]}" 2>/dev/null &>/dev/null; then
  	echo ""
    cd "$SAVETO/$PKGFMT/${kver[m]}/"
    #dpkg -i "${linux_image[@]}" "${linux_headers[@]}" "${linux_headerall[@]}"
    dpkg -i "${linux_headerall[@]} ${linux_image[@]}" "${linux_headers[@]}"
    cd -
  else echo "  Error: no downloaded kernel package found in '$SAVETO/$PKGFMT/${kver[m]}/'. quit." 1>&2
    exit 1
  fi

	if [ "$?" = 0 ]; then
	  echo "   Done."
	fi
	exit 0 ;

### kernel downloaded and end here

else

## other options
for option in "$@"; do
    case "$option" in
      -h | --help)
	case "$LANG" in
	  zh_CN*)_usage_cn ;;
	  zh_TW*)_usage_en ;;
	  en* | *)_usage_en ;;
	esac

	echo
	_about ;
	exit 0 ;;

      -t | --tips)
	case "$LANG" in
	  zh_CN*)_tips_cn ;;
	  zh_TW*)_tips_en ;;
	  en* | *)_tips_en ;;
	esac
	exit 0 ;;

      ## TAG 585:
      --lts | --longterm)

  echo " * fetch latest LTS (Long Term Support) kernel version data,"
  echo "   from: $URL_KERNEL_ORG/"
  echo

	    tmp_html=`mktemp`
	    URL_ADD="$URL_KERNEL_ORG"
	    fn[7]="kernel-org.htm" 
	    fn[8]="kernel-org.txt" #read this file
	    
	    file7="$SAVETO/list/${fn[7]}"
	    file8="$SAVETO/list/${fn[8]}"

	#### ............

	# 1.如果已经存在 kernel-org.txt 文件
	if [ -s "$file8" ]; then
	  echo -e " * search file '${fn[8]}' ...\t[found]"

	else
	## 2.否则（即不存在 kernel-org.txt）,
	#    再查找 .htm 文件(必要时下载)，转换成 .txt

 	  ### =========
	  if [ -s "$file7" ]; then
	    #echo -e "  search file '${fn[7]}'\t[found]"

	    ## 2.1 如果 .htm 存在，仍然需要重新下载到临时文件，再用 md5sum 比对
	    #  确认文件内容是否相同。如果不同，强制替换 .htm，并转换成 .txt
	    wget -q -c -t $TIMES -T $TIMEOUT "$URL_ADD" -O "$tmp_html"

	if [ "$?" != 0 ]; then
  echo "  Error (E641): download failed, bad version string or network. quit" 1>&2; exit 1;
	fi
  MD5_OLD=`md5sum "$file7" | cut -d' ' -f1`
  MD5_TMP=`md5sum "$tmp_html" | cut -d' ' -f1`

	if [ "$MD5_TMP" != "$MD5_TMP" ]; then
	  echo " * updating html file '${fn[7]}' ..."
	  cp -f "$tmp_html" "$file7"
	fi

 	    ## -------- 1 
	    if which html2text &>/dev/null; then
#	      html2text -width 999 "$file7" > "$file8"
html2text -width 999 "$file7" | grep '\[tarball' | sed '/\[tarball/s//\//' | cut -d'/' -f1 > "$file8"
	    else
	      echo "   Error (E635): command 'html2text' not found! abort." 1>&2
		exit 1;
	    fi
 	    ## -------- 1 end
	  
	  else  # 不存在文件7 (kernel-org.htm)
	    echo -e " * download html file '${fn[7]}'..."
	    wget -q -c -t $TIMES -T $TIMEOUT "$URL_ADD" -O "$file7"

 	    ## -------- 2
	    if which html2text &>/dev/null; then
#	      html2text -width 999 "$file7" > "$file8"
html2text -width 999 "$file7" | grep '\[tarball' | sed '/\[tarball/s//\//' | cut -d'/' -f1 > "$file8"
	    else
	      echo "   Error (E640): command 'html2text' not found! abort." 1>&2
		exit 1;
	    fi
 	    ## -------- 2 end

	if [ "$?" != 0 ]; then
  echo "  Error (E661): download failed, bad version string or network. quit" 1>&2; exit 1;
	fi

      fi
 	  ### =========

    fi
	#### ............

	if [ -s "$file8" ]; then
  	  echo -e " * show file '${fn[8]}'"	
	  echo "   ------------------"
	  cat "$file8"
	  echo "   ------------------"
	fi

	  shift
	  ;;
      
      ## TAG 685:
      -k | --kernels)
	## connect web and fetch kernel subdirs, 
	# save to ~/kernel/list/kernel-ppa.txt

	    tmp_html=`mktemp`
	    URL_ADD="$prefix"

	    fn[4]="kernel-ppa.htm" #data from ubuntu.com, need update
	    fn[5]="kernel-ppa.txt" #data from ubuntu.com, need update
	    fn[8]="kernel-org.txt" #data from kernel.org, not update 

	    file4="$SAVETO/list/${fn[4]}"    
	    file5="$SAVETO/list/${fn[5]}"
	    file6=`mktemp -u`	#tmp file
	    file8="$SAVETO/list/${fn[8]}"
	    
	    echo " * fetch and save kernel versions data,"
	    echo "   from: $URL_ADD/"
	    echo "   save to: $file5"
	    echo

  if [ ! -s "$file5" ]; then 
  # file5: .../kernel-ppa.txt
    ### wget
    ## -t 3: try 3 times; -T 30: timeout 30 seconds
    ## -q: quiet
    #wget -c -t 3 -T 30 "$URL_ADD" -O "$tmp_html"
    wget -q -c -t $TIMES -T $TIMEOUT "$URL_ADD" -O "$tmp_html"

if [ "$?" != 0 ]; then
  echo "  Error (E711): download failed, bad version string or network. quit" 1>&2; exit 1;
fi	    
    if [ -s "$tmp_html" ]; then
	
	# if -s file: file have size (not 0)
	#cp -f "$tmp_html" "$file4" 	#file4: .../kernel-ppa.htm

	echo -e " * creat file: ${fn[5]}"

echo -e "## $URL_ADD/\n## kernel version subdirs\n## auto created by '$APPNAME', $(date +'%Y-%m-%d %H:%M:%S')\n" > "$file5"

## part 2 (optional): save html to text. 
  if which html2text &>/dev/null; then  
     # html2text -width 999 "$tmp_html" > "$file6" 2>/dev/null
      html2text -width 999 "$tmp_html" > "$file6"
      
      sed '/v[2-9]/s//\n&/;/\//s//&\n/' "$file6" | grep 'v[2-9]' | cut -d'/' -f1 >> "$file5"
  else
    sed '/v[2-9]/s//\n&/' "$tmp_html" | grep 'v[2-9]' | cut -d'/' -f1 >> "$file5"
  fi

## TAG 590: 

  echo -e "\n   Done.\n  please run '$APPNAME' again, and select a Linux kernel to download."

  sleep 1
    else echo "   Error: can't connect to web! please check your network, and try again." 1>&2
	 exit 0
    fi
  else echo -e "   found file '${fn[5]}' . ok."
  fi

### TAG 744:
### do more: backup and update file4 (kernel-ppa.htm)
  	if [ -s "$tmp_html" ] && [ ! -s "$file4" ]; then
	    echo " * save html file '${fn[4]}' ..."
	    cp -f "$tmp_html" "$file4"
	fi

  	if [ -s "$tmp_html" ] && [ -s "$file4" ]; then
	    ## 确认 kernel-ppa.htm 文件是否需要更新替换
  		MD5_OLD=`md5sum "$file4" | cut -d' ' -f1`
  		MD5_TMP=`md5sum "$tmp_html" | cut -d' ' -f1`

	  if [ "$MD5_TMP" != "$MD5_TMP" ]; then
	    echo " * updating html file '${fn[4]}' ..."
	    cp -f "$tmp_html" "$file4"
	  fi
	fi
### ----

### TAG 762: examples, 2018-3-15
#lts=( 3.2 3.16 3.18 4.1 4.4 4.9 4.14 )
#MAINLINE='4.16'
#STABLE='4.15'

	if [ "$DEBUG" = 1 ]; then
		echo
	  echo " L781 file5=$file5"
	  echo "  fn[5]=${fn[5]}"
	  echo "  fn[8]=${fn[8]}"
	  sleep 3
	fi

    #fn[5]="kernel-ppa.txt" #data from ubuntu.com
    # file8: kernel-org.txt 	#data from kernel.org
    if [ -s "$file8" ]; then
	echo
        echo " * read file '${fn[8]}' ..."
	echo "   (check 'longterm/mainline/stable' kernel versions)"

tmp=( `grep -i "mainline:" "$file8" | head -1` )
STABLE=`echo ${tmp[1]} | cut -d'-' -f1 | cut -d'.' -f1-2`

tmp=( `grep -i "stable:" "$file8" | head -1` )
STABLE=`echo ${tmp[1]} | cut -d'.' -f1-2`

lts=( `grep -i "longterm:" "$file8" | sed '/[1-9]/s//\n&/' | grep -vi "longterm:" | cut -d' ' -f1 | cut -d'.' -f1-2` )
    fi

  ## show longterm kernel versions, and some more, from file 
  if [ -s "$file5" ]; then
    echo
    echo -e " * show lastest kernel versions (${fn[5]})..."

###
	if [ "$DEBUG" = 1 ]; then
	  echo
  echo " L793 STABLE=$STABLE  MAINLINE=$MAINLINE  PROBE_KVER=$PROBE_KVER"
	  echo "  #lts=${#lts[@]}  lts[*]=( ${lts[*]} )"
	  sleep 3
	fi
  unset tmp

    echo "   ------------------"
# grep --color=auto -E "longterm|stable|mainline" kernel-org.txt

    # 1. show latest mainline version
    cat -n "$file5" | grep "$MAINLINE[.-]" | tail -n 1 | sed '/$/s//\t[mainline]/'

    # 2. show latest stable version
    cat -n "$file5" | grep "$STABLE\." | tail -n 1 | sed '/$/s//\t[stable]/'

    echo	
    # 3. show latest longterm version
    for a in "${lts[@]}"; do
cat -n "$file5" | grep "v$a\." | tail -n 1 | sed '/$/s//\t[longterm]/'
    done

    # 4. (***) show kernel version relative with mime
    if [ "$PROBE_KVER" != '' ]; then
      echo
    cat -n "$file5" | grep "v$PROBE_KVER[.-]" | tail -n 1 | sed '/$/s//\t[***]/' | grep --color=auto "v$PROBE_KVER"
    fi  
    echo "   ------------------"    
  fi  
  echo

  shift
    ;; 
### TAG 762: option --kernels end
	
    -a | --auto)
	$APPNAME --lts
	$APPNAME -k
	exit 0 ;;

	
    -v | --version)
	echo "$APPNAME $APPVER"
	exit 0 ;;

    -*)
	echo "Unrecognized option \`$option'" 1>&2
	exit 1;;

    esac

done


##----
### TAG 940:
### do more for 2 case:
## $0
## or:
## $0 vVERSION

if [ "$#" -ge 1 ] && [ "$1" != '' ]; then

    case "$1" in
	v[0-9]* | [0-9]*)
	  ## 保险措施：用户输入的内核版本号数据后面，
	  # 可能带有目录斜杠/，使用 sed 过滤去除
	    case "$1" in
		[0-9]*)SUBDIR=`echo "v$1" | sed '/\//s///g'` ;;
		*)SUBDIR=`echo "$1" | sed '/\//s///g'`  ;;
	    esac

	    tmp_html=`mktemp`
	    URL_ADD="$prefix/$SUBDIR"

	    ## file0: 原始网页，通过 html2text 转换成file1 和 file2(文本文件)； 
	    ## file1: 根据这个文件来提取要下载的软件包名称和网址；
	    ## file2: 主要用于附加显示并确认：某个版本的内核是否正常编译成功。
	    #    只有成功的包，才有下载和安装的价值；
	    fn[0]="$SUBDIR.htm"
	    fn[1]="$SUBDIR.$SUFFIX"
	    fn[2]="$SUBDIR.log"
	
	    file0="$SAVETO/list/${fn[0]}"	#example: v3.16.55.htm
	    file1="$SAVETO/list/${fn[1]}"	#example: v3.16.55.deb.list
	    file2="$SAVETO/list/${fn[2]}"	#example: v3.16.55.log 

	  echo -e " * download data and kernel packages from:\n   $URL_ADD/"
    	  wget -q -c -t $TIMES -T $TIMEOUT "$URL_ADD" -O "$tmp_html"


if [ "$?" != 0 ]; then
  echo "  Error (E781): download failed, bad version string or network. quit" 1>&2;
  exit 1;
else :
fi

    if [ -s "$tmp_html" ]; then
	cp -f "$tmp_html" "$file0"

	# if -s file: file have size (not 0)
	echo -e " * creat .$SUFFIX package list file, and save to:\n  $file1\n"
	
#	if [ -s "$file1" ]; then
#    cp -vf --backup "$file1" "${file1}_$(date +'%Y-%m%d-%H%M%S')"	    
#	fi


#echo -e "$URL_ADD/\ndescription=auto added, $(date +'%Y-%m-%d %H:%M:%S')\n" > "$file1"
#echo -e "$URL_ADD/\ndescription=ppa date: $PPA_DATE\n" > "$file1"
echo -e "$URL_ADD/\ndescription=\n" > "$file1"

## 默认不保留带有 lowlatency （即低延时）特性的DEB软件包
#（对个人用户和普通用户意义不大），减少下载的软件包个数，节省下载时间
sed "/linux-/s//\n&/g;/.deb/s//&\n/g;/.udeb/s//&\n/g" "$tmp_html" | grep "^linux-" | uniq | sort | uniq | sed '/lowlatency/d' >> "$file1"

## part 2 (optional): save html to text. filename: v{X.Y.Z}.log
  if which html2text &>/dev/null; then  
     # html2text -width 999 "$tmp_html" > "$file2" 2>/dev/null
      html2text -width 999 "$tmp_html" > "$file2"
  fi

## read data from file1 (example: v3.16.55.deb.list)
  if [ -s "$file1" ]; then

## example: 
## 
## linux-headers-3.16.55-031655_3.16.55-031655.201803041545_all.deb
## to: 20180304	
PPA_DATE=`grep "_$ALL\." "$file1" | head -1 | cut -d'_' -f2 | cut -d'-' -f2 | cut -d'.' -f2 | cut -c 1-8`
   sed -i "/^description=/s//description=$PPA_DATE/" "$file1"
		
    echo -e " * show file: $file1"
    echo "   ------------------"
    cat "$file1"
    echo "   ------------------"    
  fi

  ## 显示对应硬件ARCH (i386/amd64) log文件(即 file2)的内容，
  #  确认官方的编译结果是成功(succefuled )还是失败(failed),
  #  来决定是否能安装对应的内核软件包

#  echo "  L854: ARCH=$ARCH"; 
sleep $SLEEP3
  
#Build for i386 succeeded (see BUILD.LOG.i386):
#  linux-headers-3.16.54-031654_3.16.54-031654.201802141044_all.deb
#  linux-headers-3.16.54-031654-generic_3.16.54-031654.201802141044_i386.deb
#  linux-headers-3.16.54-031654-lowlatency_3.16.54-031654.201802141044_i386.deb
#  linux-image-3.16.54-031654-generic_3.16.54-031654.201802141044_i386.deb
#  linux-image-3.16.54-031654-lowlatency_3.16.54-031654.201802141044_i386.deb
#
#Build for armhf failed (see BUILD.LOG.armhf): 
#
#grep -n "Build for" v3.16.54.log | cut -d' ' -f-4
#25:Build for amd64 succeeded
#32:Build for i386 succeeded
#39:Build for armhf failed
#43:Build for ppc64el succeeded

  ## TAG 750:
  # id: 0-1, example: arch_result=( i386 succeeded )
  # id: 0-1, example: sed_line=( 25 32 )
  arch_result=( `grep "^Build for $ARCH " "$file2" | cut -d' ' -f3-4` )
  sed_line=( `grep -n "^Build for " "$file2" | grep -A1 "Build for $ARCH " | cut -d':' -f1` )
  
  LINE1="${sed_line[0]}"; #let " LINE1 += 1";
  LINE2="${sed_line[1]}"; #let " LINE2 -= 1";

	if [ "$LINE1" = 0 ]; then
	  LINE1=21	#safe value, about amd64 (start)
	fi

	if [ "$LINE2" = 0 ]; then
	  LINE2=35	#safe value, about i386 (end)
	fi

	###
	if [ "$DEBUG" = 1 ]; then
	  echo "  L888"
	  echo " arch_result=( ${arch_result[*]} )"
	  echo " sed_line=( ${sed_line[*]} )"
	  echo " LINE1='$LINE1' LINE2=$LINE2"
	  sleep 3
	fi

## debug only
#arch_result=( amd64 failed )

  if [ -s "$file2" ]; then

    sleep $SLEEP3
    echo
    echo -en " * check log (${fn[2]}) ...\n   Build for ${arch_result[0]}"
    case "${arch_result[1]}" in
	## echo color: 32m=green, 31m=red
	succeeded) echo -e " \e[1;32m${arch_result[1]}\e[0m";;
	failed)    echo -e " \e[1;31m${arch_result[1]}\e[0m" ;;
	*) echo -e " ${arch_result[1]}" ;;
    esac
    echo "   ------------------"
    sed -n "$LINE1,${LINE2}p" "$file2"
    echo "   ------------------"    
  fi

  if [ "$?" = 0 ]; then
	echo -e "   Done."
  fi
  
  echo -e "  please run '$APPNAME' again, and select a Linux kernel to download."
  fi 
#fi 

###---------------------- TAG 1097:
	    ;;
 	
   *) 
    echo -e "  Error (E865): bad string '$1'.\n  examples: v3.2.100 v4.4.121 v4.16-rc5" 1>&2
	   exit 0

	   ;;
	     esac

fi fi 


### TAG 1095:
##----
if [ "$?" != 0 ]; then
  echo "  Error (E875): unknown error. quit" 1>&2
fi

exit 0 ;

