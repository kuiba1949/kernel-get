README for kernel-get 
coding: utf-8


version 1.1-5, 2017-1-13, by Careone

功能和用法：
kernel-get 是一个用来下载 Linux 内核的命令行工具 

Usage: kernel-get [OPTION]
读取资源文件，从特定网址下载 Linux 内核软件包

  -v, --version    显示版本信息并退出
  -h, --help       显示帮助信息并退出

Homepage: https://github.com/kuiba1949/kernel-get


 -----------------------------------

本程序适用的 Linux 版本： 

  * DEB软件包格式的 Linux, 如 Debian/ Ubuntu/ Deepin/ Ubuntukylin/ LinuxMint...

暂不支持的 Linux 版本：

  * RPM 软件包格式的 Linux, 如 Redhat, RHEL, CentOS, SUSE, Fedora, openSUSE ...


 1* 如何制作内核源列表文件(扩展名为 .deb.list) ?

	在浏览器中打开网址 http://kernel.ubuntu.com/~kernel-ppa/mainline/
   进入自己需要的内核版本目录，复制显示出的所有文件清单，另存为 *.deb.list 文件。
   程序会自动分析并提取对应的软件包名称，并判断当前电脑硬件是 i386 还是 amd64 平台，
   再自动下载对应的内核软件包。如果程序中断，或者因网络故障未完成下载，下次运行本程
   序，选择上次的内核版本，程序会继续下载未完成的内核包。

	下载完成后，如果当前用户是普通用户，程序会提示普通用户无法安装下载好的内核
  软件包，并结束程序。
        如果是以 root 用户身份运行的，下载完成后会暂停并提示, 是否需要安装下载好的
  内核软件包。
    

 2* 编写内核资源文件(.deb.list)必须遵循的规则：

   * 用户可以自己编写 *.deb.list 资源文件，并复制到指定的目录：
     /usr/local/share/kernel-get/list/ 或者 ~/kernel/list/ ; 

   * 文件扩展名必须为小写的 .deb.list；

   * 文件中必须保存软件包的完整下载网址和目录，程序依此来下载对应的内核软件包；

   * 文件内容必须为 Unix/Linux 换行符格式（LF）。如果是 WINDOWS/DOS的（CR/LF）, 
     或者MAC 的（CR）换行符格式，程序可能会无法正确识别和读取内核软件包相关的数据，
     无法下载；

   * 某些新版本的内核编译时，可能无法在 i386, 或者 amd64 平台上编译通过，编写
     .deb.list 文件时，请不要把编译失败的软件包文件名数据包含进来，以免产生不必要
     的误操作或者风险。


 3* .deb.list 文件内容的识别和容错机制: 
 
  ** 以 http, https, ftp 开头的行，被识别为下载地址目录。
     如果是以 # 号开头的行，如 #http , 会当作无效行忽略；
     如果有多个以 http, https, ftp 开头的行，则只读取第一行，忽略其它的行。

  ** 以 description= 开头的行（可选），被识别为注释行，用于介绍内核版本相关的内容。 
     如果没有这一行，程序会自动从内核软件包名称中，截取内核版本的相关信息；

  ** 包含 linux-*.deb 内容的行，判定为有效内容，并进行分析处理，提取出有效的软件包
     文件名。这一行中多余的空格, 制表符（TAB），无效字符串等，会被忽略，不会对程序产
     生干扰。

  ** 程序自带的 deb.list 资源文件中，只包含了 i386 和 amd64 两种架构的相关软件包
     文件名数据。但程序实际上还可以兼容 arm, 以及其它硬件架构的内核软件包。有需要的
     用户，可以自己编写 deb.list 文件，并放在指定的目录中即可；

 

 4* 范例：下面的2个示例文件的主要区别：

   提示： 在"示例文件2"中, 加入了 description 定义（可选），可以对内核版本添加备注；

   ** 示例文件1: sample1.deb.list

---------------------

http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.9-trusty/ 

Index of /~kernel-ppa/mainline/v3.13.9-trusty 

	Name	Last modified	Size	Description
	Parent Directory	 	 -	 
	0001-base-packaging.patch	03-Apr-2014 19:55	 15M	 
	0002-debian-changelog.patch	03-Apr-2014 19:55	382K	 
	0003-configs-based-on-Ubuntu-3.13.0-23.45.patch	03-Apr-2014 19:55	 22K	 
	BUILD.LOG	03-Apr-2014 20:39	5.0M	 
	BUILT	03-Apr-2014 20:39	109	 
	CHANGES	03-Apr-2014 19:54	1.6K	 
	COMMIT	03-Apr-2014 20:39	 8	 
	linux-headers-3.13.9-031309-generic_3.13.9-031309.201404031554_amd64.deb	03-Apr-2014 20:12	1.0M	 
	linux-headers-3.13.9-031309-generic_3.13.9-031309.201404031554_i386.deb	03-Apr-2014 20:30	1.0M	 
	linux-headers-3.13.9-031309-lowlatency_3.13.9-031309.201404031554_amd64.deb	03-Apr-2014 20:14	1.0M	 
	linux-headers-3.13.9-031309-lowlatency_3.13.9-031309.201404031554_i386.deb	03-Apr-2014 20:32	1.0M	 
	linux-headers-3.13.9-031309_3.13.9-031309.201404031554_all.deb	03-Apr-2014 19:55	 12M	 
	linux-image-3.13.9-031309-generic_3.13.9-031309.201404031554_amd64.deb	03-Apr-2014 20:12	 49M	 
	linux-image-3.13.9-031309-generic_3.13.9-031309.201404031554_i386.deb	03-Apr-2014 20:30	 49M	 
	linux-image-3.13.9-031309-lowlatency_3.13.9-031309.201404031554_amd64.deb	03-Apr-2014 20:13	 49M	 
	linux-image-3.13.9-031309-lowlatency_3.13.9-031309.201404031554_i386.deb	03-Apr-2014 20:32	 49M	 	 
---------------------


   ** 示例文件2: sample2.deb.list

---------------------

http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.4.41/ 

description="for Ubuntu, v4.4.41, LTS, 2017-1-09" 

Build for amd64 succeeded (see BUILD.LOG.amd64): 

  linux-headers-4.4.41-040441_4.4.41-040441.201701090549_all.deb 
  linux-headers-4.4.41-040441-generic_4.4.41-040441.201701090549_amd64.deb 
  linux-image-4.4.41-040441-generic_4.4.41-040441.201701090549_amd64.deb 

Build for i386 succeeded (see BUILD.LOG.i386): 

  linux-headers-4.4.41-040441_4.4.41-040441.201701090549_all.deb 
  linux-headers-4.4.41-040441-generic_4.4.41-040441.201701090549_i386.deb 
  linux-image-4.4.41-040441-generic_4.4.41-040441.201701090549_i386.deb 
  
---------------------
