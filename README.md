![PiOSK Banner](assets/banner.png)
**One-shot set up Raspberry Pi in kiosk mode as a webpage shuffler, with a web interface for management.**

# 0. Foreword

This started as a simple automation script &mdash; a wrapper of the [official Raspberry Pi kiosk mode tutorial](https://www.raspberrypi.com/tutorials/how-to-use-a-raspberry-pi-in-kiosk-mode/) for personal use. Then one thing lead to the other and I found myself installing nodejs & writing systemd unit files...

That's when I realized... maybe there are other people (or future me) who'd also find this "single script setup" useful.

> [!NOTE]  
> And apparently, I wasn't wrong! From GitHub [stars](https://github.com/debloper/piosk/stargazers), [issue](https://github.com/debloper/piosk/issues) reports, to [news articles](https://www.hackster.io/news/fe890d007c32) covering PiOSK - the community acceptance has been far more than I had imagined. So, with the wide range of users, there's a need for stabilizing the repo and consolidating the features. The followup updates will be less frequent, and more thoroughly tested. It's not a feature freeze, but priority would be on the refactor and maintenance.


# 1. Set Up Guide

[![PiOSK Setup Video Walkthrough](https://img.youtube.com/vi/CrQjc6P-g1A/maxresdefault.jpg)](https://youtu.be/CrQjc6P-g1A)

***PiOSK Setup Video Walkthrough***

> [!IMPORTANT]  
> As of version 3.x, PiOSK ***[assumes](#21-assumptions)*** a few things to keep itself lean and just focuses on the essentials. It may still work even if some of those assumptions aren't met; however, report/fixes for those edge cases are welcome and appreciated.


## 1.1 Preparation

0. Boot into Raspberry Pi desktop[^1]
1. Ensure username, hostname etc. are configured
2. Check ethernet/WiFi works & has internet access
3. Enable [desktop auto login](https://www.raspberrypi.com/documentation/computers/configuration.html#boot-options) (set by default on RPi OS)
4. Ensure it's using Wayland with Wayfire compositor
5. Ensure screen does not timeout & adjust brightness
6. Ensure SSH is working if you want to install remotely

[^1]: That is to say... boot into `runlevel 5` or `graphical.target` and not in console mode &mdash; it's **NOT** a recommendation to use the 3.4GB boot image named [Raspberry Pi OS Desktop](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-desktop)

> [!NOTE]  
> Check [recommendations section](#22-recommendations) for more detailed explanations.


## 1.2 Installation

Either open terminal on the Raspberry Pi's desktop environment, or remote login to it; and run the following command:

```bash
curl -sSL https://raw.githubusercontent.com/debloper/piosk/main/scripts/setup.sh | sudo bash -
```

That's it[^2].

[^2]: For some reason, if that's **NOT** it, and you hit a snag... please report an issue & give us some context to replicate & debug it.

## 1.3 Configuration

### 1.3.1 Basic

1. Visit `http://<pi's IP address>/`[^3] from a different device on the network
2. You should see the PiOSK dashboard with a list of sample URLs as kiosk mode screens
3. Feel free to add & remove links as necessary (at least 1 link is necessary for it to work)
4. The URLs don't have to be of remote domains. You can use localhost or even `file:///path`
5. Once you're happy with the list, press `APPLY ⏻` button to apply changes and reboot PiOSK
6. When rebooted, wait for the kiosk mode to start & flip through the pages in fullscreen mode


### 1.3.2 Advanced

> [!WARNING]  
> Try these at your own risk; if you know what you're doing. Misconfiguration(s) may break the setup.

1. The PiOSK repo is cloned to the user's `$HOME/piosk`
2. You can change the dashboard port from `index.js`
3. You can change the per-page timeout from `scripts/switcher.sh`
4. You can change browser behavior (e.g. no full screen) from `scripts/browser.sh`
5. Some changes can be applied without rebooting, but rebooting is safer

[^3]: PiOSK uses port 80 on the Pi to serve the web dashboard. If you're planning to use the Pi for other purposes, make sure to avoid port collision.

![PiOSK Dashboard Web GUI](assets/dashboard.png)

## 1.4 Updating

For now, there's no direct way to update the setup. This will change.

You should uninstall old version and then reinstall the new version. As long as you don't delete the backup config file (created during uninstallation), it should be picked up and reinstated by the reinstallation process.

Look into the Uninstallation section for the next steps.


## 1.5 Uninstallation

In order to uninstall/remove PiOSK from your system, run the `scripts/cleanup.sh` script as the user for whom PiOSK was installed:

```bash
sudo scripts/cleanup.sh
```

> [!NOTE]  
> By default PiOSK doesn't uninstall the system packages it installs as dependencies (i.e. git, jq, Node.js, wtype). The reason being, if they're force removed, then other packages (which have been installed since) that may also rely on them - will break. It's also because if you're going to reinstall or update PiOSK, then they'll have to be installed again. Uncomment the last section in `cleanup.sh` file if you really want to remove those packages.


# 2. Appendix

## 2.1 Assumptions

1. You're using a Raspberry Pi (other SBCs may work, not tested)
2. You're using "[Raspberry Pi OS with desktop (32bit)](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-32-bit)" (other distros may work, not tested)
3. You've applied proper [OS customizations](https://www.raspberrypi.com/documentation/computers/getting-started.html#advanced-options) & the Pi is able to access the internet (required for setup)
4. You're using **Wayland with Wayfire compositor** (probably the only *"must have"* during runtime)
5. You're using the same user to run the setup script for whom desktop auto login is configured
6. You're not using port 80 on the Pi to run some other web server (apart from PiOSK dashboard)

## 2.2 Recommendations

- Choose the right Raspberry Pi
    - Pi Zero 2 W is perhaps the most fitting RPi for the job
    - Older Pi Zero (1.3, Zero W etc.) may struggle running Chromium
    - A Pi4 or Pi5 may be overkill, but shouldn't face any issue
- Choose the right display/screen
    - Not related to PiOSK, but resolution matters for browser based kiosk mode
        - Browser content window resolutions smaller than `1024px*600px` may not be ideal
        - Different websites have different responsive rules & handle small screens differently
    - Also be mindful of [LCD burn-in](https://en.wikipedia.org/wiki/Screen_burn-in) if displaying very limited number of static pages
    - DSI displays are more discreet, but they may require driver setup to work properly
- Choose the right OS Image
    - Use Raspberry Pi [imager tool](https://www.raspberrypi.com/documentation/computers/getting-started.html#install-using-imager) for flashing
    - Alternatively, you can use [network install](https://www.raspberrypi.com/documentation/computers/getting-started.html#install-over-the-network)
    - If your Pi has 4GB or less memory, choose 32bit image
    - Use Debian Bookworm based images (for better Wayland/Wayfire support)
    - Apply the necessary customizations (user account, WiFi credentials, SSH access etc)
- Take necessary steps to harden security
    - Disable touchscreen unless required
    - Disable ports that aren't required
    - Disable unused network interfaces, remote SSH
    - Enable OverlayFS to write protect storage
- Discover the Pi on the network
    - Set hostname (e.g. `piosk`) so you can call it by hostname without needing to hunt for IP
    - The dashboard's URL with the hostname & IP address is shown at the end of the install script
    - Or, run angry IP scanner or login to router/switch to discover the Pi's IP the hard way
