
if shopt -q login_shell; then
  #echo -e "\n\nDetected Login Shell\n"
  echo -e "\n\n"

  R=$( systemctl get-default 2>/dev/null )
  if [ "${R}" = "graphical.target" ]; then
    echo "default runlevel is: ${R}. it's NOT advised enable lpie"
    echo "run following command before activating lpie: sudo systemctl set-default multi-user.target"
    echo ""
  elif [ "${R}" = "multi-user.target" ]; then
    echo "default runlevel is: ${R}"
    echo "run following command for GUI, after having deactivated lpie: sudo systemctl set-default graphical.target"
    echo ""
  else
    echo "unknown default runlevel is: ${R}"
    echo "run following command before activating lpie: sudo systemctl set-default multi-user.target"
    echo "run following command for GUI, after having deactivated lpie: sudo systemctl set-default graphical.target"
    echo ""
  fi


  M=$(lpie status 2>&1 |grep "^filesystem mode:" | sed 's/filesystem mode: //g' )
  C=$(lpie status 2>&1 |grep "^cmdline.txt:" | sed 's/cmdline.txt: //g' )

#filesystem mode: rw
#cmdline.txt: lpie disabled

# sudo lpie reboot-rw
#filesystem mode: rw
#cmdline.txt: lpie enabled

  if [ "${C}" = "lpie disabled" ]; then
    echo "current configuration - for next boot - is disabled: ${C}"
    echo "run following command to enable: sudo lpie enable"
    echo ""
  else
    echo "current configuration - for next boot - is enabled: ${C}"
    echo "run following command to disable: sudo lpie disable"
    echo ""
  fi

  if [ "${M}" = "rw" ]; then
    echo "layerpie is currently inactive: ${M}"
    echo "SD-card is unsafe!,"
    echo "but configuration changes will persist"
    echo ""
  else
    echo "layerpie is currently active: ${M}"
    echo "SD-card is safe,"
    echo "but any configuration changes will get lost after reboot!"
    echo ""
  fi

fi

