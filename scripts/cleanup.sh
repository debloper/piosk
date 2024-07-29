SITE=$(cat /etc/passwd | grep /$SUDO_USER: | cut -f6 -d:)
cd $SITE

mv piosk/confg.json piosk.config.bak
echo -e "PiOSK config is backed up to: \033[0;32m$SITE/piosk.config.bak\033[0m"

rm -rf piosk
echo -e "\033[0;31m1. removed cloned repository.\033[0m"

sed -i "/piosk/d" /etc/rc.local
echo -e "\033[0;31m2. removed startup run command.\033[0m"

sed -i "/\[autostart\]/d" .config/wayfire.ini
sed -i "/^browser/d" .config/wayfire.ini
sed -i "/^switcher/d" .config/wayfire.ini
echo -e "\033[0;31m3. removed autostart wayfire config.\033[0m"

# If you wanna reinstall/update PiOSK, then ignore the following
#
# Forced uninstallation of system packages may cause instability
# That's why -y flag is avoided to use interactive user approval
# Even safer option would be to review & uninstall them manually
# Uncomment the following lines if you are totally sure about it
#
# echo -e "\033[0;31m4. removing installed dependencies.\033[0m"
# apt remove -y git jqnodejs wtype
# rm -rf /etc/apt/sources.list.d/nodesource.list
