![PiOSK Banner](assets/banner.png)
**One-shot set up Raspberry Pi in kiosk mode as a webpage shuffler, with a web interface for management.**

# 0. Foreword

This started as a simple automation script &mdash; a wrapper of the [official Raspberry Pi kiosk mode tutorial](https://www.raspberrypi.com/tutorials/how-to-use-a-raspberry-pi-in-kiosk-mode/) for personal use. Then one thing lead to the other and I found myself installing nodejs & writing systemd unit files...

That's when I realized... maybe there are other people (or future me) who'd also find it useful.

This is far from done. It's just the first checkpoint that meets my initial goal of making the entire process a "single script setup".


# 1. Set Up Guide

> [!IMPORTANT]  
> As of version 1.x, PiOSK ***[assumes](#21-assumptions)*** a few things to keep itself lean and just focus on essentials. It may still work even if some of those assumptions aren't met; however, report/fixes for those edge cases are welcome and appreciated.


## 1.1 Preparation

1. Boot into Raspberry Pi desktop[^1]
2. Ensure network/WiFi/internet is working
3. Ensure [desktop auto login](https://www.raspberrypi.com/documentation/computers/configuration.html#boot-options) is enabled (is default)
4. Ensure screen does not timeout & adjust brightness
5. Ensure SSH is working if you want to install remotely

[^1]: That is to say... boot into `runlevel 5` or `graphical.target` and not in console mode &mdash; it's **NOT** a recommendation to use the 3.4GB boot image named [Raspberry Pi OS Desktop](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-desktop)

> [!NOTE]  
> Check [recommendations section](#22-recommendations) for more detailed explanations.


## 1.2 Installation

Either open terminal on the Raspberry Pi's desktop environment, or remote login to it; and run the following command:

```bash
curl -sSL https://raw.githubusercontent.com/debloper/piosk/main/setup.sh | sudo bash -
```

That's it[^2].

[^2]: For some reason, if that's **NOT** it, and you hit a snag... please report an issue & give us some context to replicate & debug it.

## 1.3 Configuration

### 1.3.1 Basic

1. Visit `http://<pi's IP address>/`[^3] from a different device on the network
2. You should see the PiOSK dashboard with a list of sample URLs as kiosk mode screens
3. Feel free to add & remove links as necessary (at least 1 link is necessary for it to work)
4. Once you're happy with the list, press `APPLY ⏻` button to apply changes and reboot PiOSK
5. When rebooted, wait for the kiosk mode to start & flip through the pages in fullscreen mode


### 1.3.1 Advanced

> [!WARNING]  
> Try these at your own risk; if you know what you're doing. Misconfiguration(s) may break the setup.

1. The PiOSK repo is cloned to the user's `$HOME/piosk`
2. You can change the dashboard port from `index.js`
3. You can change the per-page timeout from `switcher.sh`
4. You can change browser behavior (e.g. no full screen) from `browser.sh`
5. Some changes can be applied without rebooting, but rebooting is safer

[^3]: PiOSK uses port 80 on the Pi to serve the web dashboard. If you're planning to use the Pi for other purposes, make sure to avoid port collision.

![PiOSK Dashboard Web GUI](assets/dashboard.png)

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
    - Use the Pi imager tool for flashing
    - If your Pi has 4GB or less memory, choose 32bit image
    - Use Debian Bookworm based images (for better Wayland/Wayfire support)
- Take necessary steps to harden security
    - Disable touchscreen unless required
    - Disable ports that aren't required
    - Disable unused network interfaces, remote SSH
    - Enable OverlayFS to write protect storage
- Discover the Pi on the network
    - Set hostname (e.g. `piosk`) so you can call it by hostname without needing to hunt for IP
    - The dashboard's URL with the hostname & IP address is shown at the end of the install script
    - Or, run angry IP scanner or login to router/switch to discover the Pi's IP the hard way
