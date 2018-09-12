# Transparent Shadowsocks Proxy on Raspberry Pi

## 需要的东西

1. 树莓派 3B+（支持5GHz Wi-Fi）
1. 5V 2A 电源
1. USB-A to microUSB 线
1. microSD卡（8G+）
1. 网线一根
1. 最新的[固件镜像文件](https://downloads.raspberrypi.org/raspbian_lite_latest)

> 如果想直接在树莓派上操作而不是SSH远程登录的话，还需要
> 1. 显示器
> 1. HDMI线
> 1. USB鼠标&USB键盘

## 启动树莓派

1. 在电脑上安装[Etcher](https://etcher.io/)
1. 插入SD卡，选择下载好的固件，将固件刷入SD卡

> 如果想要使用SSH远程登录，需要一步额外操作
>
> 系统中会识别一个新的磁盘`boot`，在该磁盘的根目录新建一个空文件`ssh`，文件中无需任何内容，只要保证在根目录下有该文件即可

3. 将刷好固件的SD卡插入树莓派，连接网线（如果直接操作还需连接显示器和鼠标键盘）后，插入电源就会自动启动了

## 初次启动设置树莓派

> 如果你是SSH远程登录树莓派，需要进行如下额外操作
> 1. 在路由器中找到树莓派的ip地址（如192.168.100.184）
> 1. 在命令行中打`ssh pi@192.168.100.184`远程登录树莓派
>
> 注：windows需要下载一个ssh客户端，推荐PuTTY

1. 登陆账户为`pi`，初始密码`raspberry`
1. 进行初始升级
    ```
    sudo apt update
    sudo apt upgrade
    ```
1. 进行初始配置
    ```
    sudo raspi-config
    ```
    会进入到图形化设置界面，进行以下设置
    * `1 Change User Password`，修改`pi`账户的登陆密码
    * `2.3 Network interface names`，设置no
    * `4 Localisation Options`，区域设置（注：当修改Wi-Fi区域时，选择**US**，切记<血泪史>）
    * `7.1 Expand Filesystem`，使用所有的SD卡空间
1. 完成以上设置后选择底部的Finish（左右键），并重启树莓派

## 将树莓派配置为AP热点

1. 升级
    ```
    sudo apt update
    sudo apt upgrade
    ```
1. 安装需要的软件
    ```
    sudo apt install dnsmasq hostapd
    ```
1. 因为新服务还未设置，暂时停止他们
    ```
    sudo systemctl stop dnsmasq
    sudo systemctl stop hostapd
    ```
---
### 配置静态IP地址

1. 编辑配置文件
    ```
    sudo nano /etc/dhcpcd.conf
    ```
    在打开的文件最末尾，添加以下内容
    > ip地址中的`23`可以挑自己喜欢的改，范围1-254，注意不要和现有的路由器LAN地址冲突
    ```
    interface wlan0
    static ip_address=192.168.23.1/24
    nohook wpa_supplicant
    ```
    > 如此一来Wi-Fi的IP地址就改成了静态的192.168.23.1
1. 保存并关闭编辑窗口，然后重启DHCP服务器
    ```
    sudo service dhcpcd restart
    ```
---
### 配置DHCP服务器

1. 因为默认的配置文件包含许多不需要的内容，所以重命名后新建新的配置文件
    ```
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
    sudo nano /etc/dnsmasq.conf
    ```
    在打开的配置文件中添加以下内容
    > ip地址中的`23`需要和上一步中选的值对应
    ```
    interface=wlan0
    dhcp-range=192.168.23.2,192.168.23.20,255.255.255.0,24h
    ```
    > 这样我们就在Wi-Fi配置了一个DHCP服务器，可以连接19个设备
1. 保存并关闭编辑窗口
---
### 配置Wi-Fi参数

1. 新建一个配置文件
    ```
    sudo nano /etc/hostapd/hostapd.conf
    ```
    因为文件内容较多，直接参考`/etc/hostapd/`目录下的配置文件，两个配置文件分别对应2.4GHz和5GHz，注意同一时间只能使用一个频段，就是说只能用一套配置文件
1. 保存并关闭编辑窗口
1. 让配置生效
    ```
    sudo nano /etc/default/hostapd
    ```
    找到一行`#DAEMON_CONFIG`开头，将其替换为
    ```
    DAEMON_CONFIG="/etc/hostapd/hostapd.conf"
    ```
1. 启动服务
    ```
    sudo systemctl start hostapd
    sudo systemctl start dnsmasq
    ```
---
### 新增路由

1. 编辑配置文件
    ```
    sudo nano /etc/sysctl.conf
    ```
    找到一行
    ```
    #net.ipv4.ip_forward=1
    ```
    删除最前面的`#`并保存
1. 添加一条转发规则
    ```
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    ```
1. 保存该规则
    ```
    sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
    ```
1. 在开机时应用该规则
    ```
    sudo nano /etc/rc.local
    ```
    在文件最后`exit 0`行上面，添加如下内容
    ```
    iptables-restore < /etc/iptables.ipv4.nat
    ```
1. 重启
    ```
    sudo reboot
    ```

至此完成将树莓派配置成Wi-Fi的工作

## 配置Shadowsocks代理

TODO

#### 参考资料
[Installing Operating System Images](https://www.raspberrypi.org/documentation/installation/installing-images/README.md)

[Raspi-Config](https://www.raspberrypi.org/documentation/configuration/raspi-config.md)

[Setting Up a Raspberry PI as An Access Point In a Standalone Network (NAT)](https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md)

[Shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev)
