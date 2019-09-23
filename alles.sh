#!/bin/bash

function logo {
  echo "   ___   __   __   ________      __  "
  echo "  / _ | / /  / /  / __/ __/ ___ / /  "
  echo " / __ |/ /__/ /__/ _/_\ \_ (_-</ _ \ "
  echo "/_/ |_/____/____/___/___(_)___/_//_/ "
}

function help {
  logo
  echo -e "\nCommands:"
  echo -e "\t -c No colors"
  echo -e "\t -v Print errors\n"
}

runlist=(

"Topic: Determine OS"

)

# The different test stages. Your additions would be appreciated!
#runlist=(

#"TOPIC: Determine OS"
#"uname -a" "head -1 /etc/issue" "head -4 /etc/os-release" 
#"cat /etc/debian_version" "cat /etc/lsb_release"

#"TOPIC: Network"
#"hostname -f" "ip route show" "route" "grep -v -e '^$' -e '#' /etc/hosts"
#"lsof -i4 -n" "lsof -i6 -n"

#"TOPIC: Local users and groups"
#"id" "w" "last -10" "env" "cat /etc/passwd"
#"getent passwd 0" "grep 'root\|adm\|wheel\|admin' /etc/group"

#"TOPIC: SSH"
#"grep -v -e '^$' -e '#' /etc/ssh/sshd_config" "ls -lah /home/$USER/.ssh"
#"find /home -type d ! -perm -g+r,u+r,o+r -prune -name .ssh"

#"TOPIC: Sudo"
#"sudo -l"
#"grep -v -e '^$' -e '#' /etc/sudoers"


#"TOPIC: SUID and GUID"
#"find '/' -user root -perm -4000 -print ; 2>/dev/null"
#"find '/' -group root -perm -2000 -print ;  2>/dev/null"

#"TOPIC: Loose permissions"
#"find / -perm -222 -type d ; 2>/dev/null"
#"find / -perm -4000 -o -perm -2000 -print ; 2>/dev/null"

#"TOPIC: Places of interest"
#"ls -lah /root" "ls -lah /opt/"

#"TOPIC: Services"
#"crontab -l" "ps -aux" 
#"systemctl list-units"

)

COLORMODE=0
SUPPRESS_ERRORS=1

# Test terminal color support
if test -t 1; then
    ncolors=$(tput colors)
    if test -n "$ncolors" && test $ncolors -ge 8; then COLORMODE=1; fi
fi

while getopts "vch" option; do
 case "${option}" in
    v) SUPPRESS_ERRORS=0;;
    c) COLORMODE=0;;
    h) help; exit;;
 esac
done

logo

if [[ COLORMODE -eq 1 ]]; then
    h="\n$(tput bold)$(tput setaf 6)======== " # header start: bold and turquoise
    e=" ========$(tput sgr0)"                  # header end
    s="\n$(tput bold;tput setaf 2)"            # success: bold and green
    f="\n$(tput bold;tput setaf 1)"            # fail: bold and red
    r="$(tput sgr0)"                           # reset
else
    h="\n======== "
    e=" ========"
    s="\n###############\n# "
    f="\n!! "
    r=""
fi

function error_filter {
  if [[ $SUPPRESS_ERRORS -ne 1 ]]; then
    echo -e "$1"
  fi
}

function commandrunner {

  cmd="$1"
  if [[ $cmd == TOPIC* ]]; then
    echo -e "${h}${cmd}${e}"
    return
  fi
  
  IFS=' ' read -r -a cmdarray <<< $(echo -e ${cmd} | tr "'" '"')

  command_exists=$(command -v ${cmdarray[0]})
  
  if [[ $? -ne 0 ]]; then
    error_filter "${f}${cmdarray[@]}${r}: command not present!"
  else
    output=$(${cmdarray[@]} 2>&1)
    exitcode=$?
    if [[ exitcode -ne 0 ]]; then
      error_filter "${f}${cmdarray[*]}${r} (${exitcode}) $(echo -e ${output@Q} | head -4)"
    else
      echo -e "${s}${cmdarray[*]}${r}\n${output@Q}"
    fi
  fi
}

for i in "${runlist[@]}"; do commandrunner "$i"; done
