# NOTE: the sudo invoker _HAS TO BE_ same as the auto-login user
# Because we need to update that specific user's wayfire configs
# Ensure making this abundantly clear in the install instuctions
SITE=$(cat /etc/passwd | grep /$SUDO_USER: | cut -f6 -d:)
cd $SITE

# Update if there's a better way to install node than nodesource
# Although, building (electron?) runtime binary can be an option
[ $(which node) ] || curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
# Install deps (apt update already handled by nodesource script)
apt install -y git jq nodejs wtype

# Clone the PiOSK repo, or (in case it exits) pull from upstream
git clone https://github.com/debloper/piosk.git || git -C piosk pull

# Set up wayfire autostart config to start up browser & switcher
echo "[autostart]" >> $SITE/.config/wayfire.ini
echo "browser = $SITE/piosk/browser.sh" >> $SITE/.config/wayfire.ini
echo "switcher = bash $SITE/piosk/switcher.sh" >> $SITE/.config/wayfire.ini

# If PiOSK config doesn't exist, try backup or use sample config
if [ ! -f $SITE/piosk/config.json ]; then
    if [ -f $SITE/piosk.config.bak ]; then
        mv piosk.config.bak piosk/config.json
    else
        mv piosk/config.json.sample piosk/config.json
    fi
fi

# Not necessary to change directory; npm does take --prefix path
cd $SITE/piosk
# This either goes in active development, or stays as is forever
# In either of the cases, `npm ci` is less suitable than `npm i`
npm i

# Add dashboard web server to rc.local to autostart on each boot
sed -i '/^exit/d' /etc/rc.local
echo "cd $SITE/piosk/ && node index.js &" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local

# Also, start the server without needing to wait for next reboot
node index.js &

# Report the URL with hostname & IP address for dashboard access
echo -e "\033[0;35m\nPiOSK is now installed.\033[0m"
echo -e "Visit either of these links to access PiOSK dashboard:"
echo -e "\t- \033[0;32mhttp://$(hostname)/\033[0m or, \n\t- \033[0;32mhttp://$(hostname -I | cut -d " " -f1)/\033[0m"
echo -e "Configure links to shuffle; then apply changes to reboot."
echo -e "\033[0;31mThe kiosk mode will start on next startup.\033[0m"
