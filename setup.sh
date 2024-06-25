# NOTE: the sudo invoker _HAS TO BE_ same as the auto-login user
# Because we need to update that specific user's wayfire configs
# Ensure making this abundantly clear in the install instuctions
SITE=$(cat /etc/passwd | grep /$SUDO_USER: | cut -f6 -d:)
cd $SITE

# Update if there's a better way to install node than nodesource
# Although, building (electron?) runtime binary can be an option
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
# Install deps (apt update already handled by nodesource script)
apt install -y git jq nodejs wtype

# Clone the PiOSK repo, or (in case it exits) pull from upstream
git clone https://github.com/debloper/piosk.git || git -C piosk pull

# Set up wayfire autostart config to start up browser & switcher
echo "[autostart]" >> $SITE/.config/wayfire.ini
echo "browser = $SITE/piosk/browser.sh" >> $SITE/.config/wayfire.ini
echo "switcher = bash $SITE/piosk/switcher.sh" >> $SITE/.config/wayfire.ini

# If PiOSK config doesn't exist, use sample config to create one
[ -f $SITE/piosk/config.json ] || cp $SITE/piosk/config.json.sample $SITE/piosk/config.json

# Not necessary to change directory; npm does take --prefix path
cd $SITE/piosk
# This either goes in active development, or stays as is forever
# In either of the cases, `npm ci` is less suitable than `npm i`
npm i

# Create & install an executable wrapper to start up the web GUI
echo '#!/bin/sh' > piosk
echo "cd $SITE/piosk/" >> piosk
echo "node index.js" >> piosk
chmod +x piosk
cp piosk /usr/bin/piosk

# And set up the systemd unit to automatically start the service
cp piosk.service /etc/systemd/system/piosk.service
systemctl daemon-reload
systemctl enable piosk.service
systemctl start piosk.service

# Report the URL with hostname & IP address for dashboard access
echo -e "\033[0;35mPiOSK is now installed.\n\033[0m"
echo -e "Visit either of these links to access PiOSK dashboard:"
echo -e "\t- \033[0;32mhttp://$(hostname)/\033[0m or, \n\t- \033[0;32mhttp://$(hostname -I | cut -d " " -f1)/\033[0m"
echo -e "Configure links to shuffle; then apply changes to reboot."
echo -e "\033[0;31mThe kiosk mode will start on next startup.\033[0m"
