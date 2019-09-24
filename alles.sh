#!/bin/bash
#set -euxo pipefail

function logo {
	echo -e '       ____              __ \n ___ _/ / /__ ___   ___ / /  \n/ _ `/ / / -_|_-<_ (_-</ _ \ \n\_,_/_/_/\__/___(_)___/_//_/ \n'
}

function help {
  logo
  echo -e "\nCommands:\n\t -c No colors\n\t -v Print errors\n\t -h Help\n"
}

# The different test stages. Your additions would be appreciated!
runlist=(

"TOPIC: Determine OS & Environment"
"uname -a" "head -1 /etc/issue" "head -4 /etc/os-release" 
"head -5 /etc/debian_version 2>/dev/null" "head -5 /etc/lsb_release"

"TOPIC: Network"
"hostname -f" "ip route show" "route" "grep -v -e '^$' -e '#' /etc/hosts"
"lsof -i4 -n" "lsof -i6 -n" "ss -ltn 2>/dev/null"
"arp -a" "ip neigh show"

"TOPIC: Local users and groups"
"id" "w" "last -10" "env" "cat /etc/passwd"
"getent passwd 0" "grep 'root\|adm\|wheel\|admin' /etc/group"
"find / -name .bash_history -exec ls -lah {} \; 2>/dev/null"

"TOPIC: Security measures"
"sestatus"

"TOPIC: SSH"
"find /root /home -type d -name .ssh -exec ls -lah {} +"
"grep -v -e '^$' -e '#' /etc/ssh/sshd_config 2>/dev/null" "ls -lah /home/$USER/.ssh"
"find /home -type d ! -perm -g+r,u+r,o+r -prune -name .ssh"

"TOPIC: Sudo"
"sudo -ln" "grep -v -e '^$' -e '#' /etc/sudoers"

"TOPIC: SUID and GUID"
"find '/' -user root -perm -4000 -print"
"find '/' -group root -perm -2000 -print"

"TOPIC: Loose permissions"
"find / -perm -222 -type d"
"find / -perm -4000 -o -perm -2000 -print"

"TOPIC: Places of interest"
"ls -lah /root" "ls -lah /opt/"

"TOPIC: Packages"
"zcat /var/log/apt/history.log.*.gz | cat - /var/log/apt/history.log | grep -Po '^Commandline: apt-get install (?!.*--reinstall)\K.*'"
"zgrep -h ' install ' /var/log/dpkg.log* | sort | awk '{print $4}'"
"rpm -qa --last | head -30"

"TOPIC: Services"
"ps -eo euser,ruser,suser,fuser,f,tty,label,s,args | grep -v ']$'"
"crontab -l" "ls -lah /etc/cron*" "systemctl list-units"
"ls -lahH /etc/init.d 2>/dev/null"

)

COLORMODE=0
SUPPRESS_ERRORS=1

# Test terminal color support
if test -t 1; then ncolors=$(tput colors); if test -n "$ncolors" && test $ncolors -ge 8; then COLORMODE=1; fi; fi

while getopts "vch" option; do
 case "${option}" in
    v) SUPPRESS_ERRORS=0;;
    c) COLORMODE=0;;
    h) help; exit;;
 esac
done

logo

if [[ COLORMODE -eq 1 ]]; then
	b=$(tput bold); t=$(tput setaf 6); r=$(tput sgr0); g=$(tput setaf 2); d=$(tput setaf 1)
fi

he="\n${b}${t}======== "; eh=" ========${r}"; sc="\n# ${b}${g}"; fl="\n!! ${b}${d}"; re="${r}"

function error_filter { if [[ $SUPPRESS_ERRORS -ne 1 ]]; then echo -e "$1"; fi }

function commandrunner {

  if [[ $1 == TOPIC* ]]; then echo -e "${he}${@}${eh}"; return; fi
  if [ ! -x "$(command -v ${1})" ]; then echo -e "${fl}${1}: No command or not executable${re}"; return; fi
  
  output=$(eval ${*} 2>&1)
  exitcode=$?
  if [[ exitcode -ne 0 ]]; then
    error_filter "${fl}${*}${re} (${exitcode}) $(echo -e ${output} | head -4)"
  else
    echo -e "${sc}${@}${re}\n${output}"
  fi
}

for i in "${runlist[@]}"; do commandrunner $i; done
