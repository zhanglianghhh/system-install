#!/bin/bash

# no.0 mirrors and epel change
/bin/mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.ori
/usr/bin/wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo

/usr/bin/wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo

# no.1 close selinux
/bin/cp /etc/selinux/config /etc/selinux/config.ori
/bin/sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
setenforce 0    # current environment effect

# no.2 close iptables
/etc/init.d/iptables stop
/sbin/chkconfig 'iptables' off

# no.3 boot server optimize
/sbin/chkconfig --list | /bin/grep '3:on' | /bin/grep -Ev 'crond|network|rsyslog|sshd|sysstat' | /bin/awk '{print "chkconfig",$1,"off"}' | /bin/bash

# no.4 user get root authority
userAdd=zhang
/bin/cp /etc/sudoers /etc/sudoers.ori
/usr/sbin/useradd ${userAdd} && /bin/echo '123456' | /usr/bin/passwd --stdin ${userAdd} > /dev/null 2>&1 
/bin/echo "" >>  /etc/sudoers
/bin/echo "# user zhang get root authority" >>  /etc/sudoers
/bin/echo "zhang  ALL=(ALL)       NOPASSWD: ALL" >>  /etc/sudoers

# no.5 show zh_CN.UTF-8
# /bin/cp /etc/sysconfig/i18n /etc/sysconfig/i18n.ori
# /bin/sed -i 's#en_US.UTF-8#zh_CN.UTF-8#g' /etc/sysconfig/i18n 
# . /etc/sysconfig/i18n

# no.6 time synchronization
yum install -y ntp
/bin/echo "# time sync by zhangliang at $(date +%F)" >> /var/spool/cron/root
/bin/echo '*/10 * * * * /usr/sbin/ntpdate time.nist.gov >/dev/null 2>&1' >> /var/spool/cron/root	

# no.7 command line save set
# /bin/cp /etc/profile /etc/profile.ori
# /bin/echo "# command line save set by zhangliang at $(date +%F)" >> /etc/profile
# /bin/echo 'export  TMOUT=600' >> /etc/profile
# /bin/echo 'export  HISTSIZE=50' >> /etc/profile
# /bin/echo 'export  HISTFILESIZE=50' >> /etc/profile

# no.8 alias color set
/bin/cp /etc/profile /etc/profile_zhang_$(date +%Y%m%d%H%M%S).bak
/bin/cp /etc/bashrc /etc/bashrc_zhang_$(date +%Y%m%d%H%M%S).bak

/bin/echo '' >> /etc/bashrc
/bin/echo '# grep color' >> /etc/bashrc
/bin/echo "alias grep='grep --color=auto'" >> /etc/bashrc
/bin/echo "alias egrep='grep -E --color=auto'" >> /etc/bashrc

/bin/echo "alias cp='cp -i'" >> /etc/bashrc
/bin/echo "alias l.='ls -d .* --color=auto'" >> /etc/bashrc
/bin/echo "alias ll='ls -l --color=auto'" >> /etc/bashrc
/bin/echo "alias ls='ls --color=auto'" >> /etc/bashrc
/bin/echo "alias mv='mv -i'" >> /etc/bashrc
/bin/echo "alias rm='rm -i'" >> /etc/bashrc

/bin/echo '' >> /etc/bashrc
/bin/echo 'export HISTTIMEFORMAT="%F %T $(whoami) "' >> /etc/bashrc
/bin/echo "export PROMPT_COMMAND='{ msg=\$(history 1 | { read x y; echo \$y; });logger \"[euid=\$(whoami)]\":\$(who am i):[\`pwd\`]\"\$msg\"; }'" >> /etc/bashrc 
# export PROMPT_COMMAND='{ msg=$(history 1 | { read x y; echo $y; });logger "[euid=$(whoami)]":$(who am i):[`pwd`]"$msg"; }'  
source /etc/bashrc

# no.9 limits.conf
/bin/cp /etc/security/limits.conf /etc/security/limits.conf.ori
/bin/echo "* soft nofile 65535" >> /etc/security/limits.conf
/bin/echo "* hard nofile 65535" >> /etc/security/limits.conf

# no.10 kernel optimize
/bin/cp /etc/sysctl.conf /etc/sysctl.conf.ori
/bin/cat >> /etc/sysctl.conf << EOF

### optimization by zhangliang $(date +%F)
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range = 4000		65000
net.ipv4.tcp_max_syn_backlog = 16384

net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1

net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384

## CentOS 6.x
net.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
EOF

/sbin/sysctl -p > /dev/null 2>&1

# no.11 timing clear system mail
/bin/mkdir /server/scripts/ -p	
/bin/echo "# timing clear system mail" >>/server/scripts/del_mail_file.sh
/bin/echo '/bin/find /var/spool/postfix/maildrop/ -type f | xargs -I{} /bin/rm -f {}' >> /server/scripts/del_mail_file.sh
/bin/echo "" >> /var/spool/cron/root
/bin/echo '# delete mail file by zhangliang at $(date +%F)' >> /var/spool/cron/root	
/bin/echo '00 00 * * 6 /bin/sh /server/scripts/del_mail_file.sh >/dev/null 2>&1' >> /var/spool/cron/root	

# no.12 hide system version info
/bin/cp /etc/issue /etc/issue.ori
/bin/cp /etc/issue.net /etc/issue.net.ori
> /etc/issue
> /etc/issue.net

/bin/echo "" >> /etc/motd
/bin/echo 'Welcome You Login' >> /etc/motd
/bin/echo "" >> /etc/motd

# no.13 SSH optimize
/bin/cp /etc/ssh/sshd_config /etc/ssh/sshd_config.ori
/bin/cat >> /etc/ssh/sshd_config << EOF

##### by zhangliang # $(date +%F)##	
Port 52113
PermitRootLogin no
PermitEmptyPasswords no
UseDNS no
GSSAPIAuthentication no
##### by zhangliang # $(date +%F)##
EOF

/etc/init.d/sshd restart

# no.14 install necessary software
/usr/bin/yum install -y pcre pcre-devel
/usr/bin/yum install -y openssl openssl-devel 
/usr/bin/yum install -y nfs-utils rpcbind
/usr/bin/yum install -y lrzsz sysstat nmap tree telnet dos2unix nc





