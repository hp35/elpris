# ELPRIS - logging the price of electricity in Scandinavia

The `elpris` project uses a Raspberry Pi Zero W and a Pimoroni Inky pHAT 2.13"
display for the continuous logging of the current price for electricity.

# Installation

## Install disk image
Install a brand new Raspberry Pi OS, using the instructions at https://www.raspberrypi.com/software/

## Finding your Raspberry Pi Zero on the local network
Usually, your Raspberry Pi Zero will automatically show up on your local network with the name you assigned it, regardless of whether you are using a wired or wireless (WiFi) connection to it. You can check its presence by, say, pinging it:
```bash
ping rpi-zero-elpris.local
```
If the unit has not showed up within a few minutes, being enough for your local router to assign DHCP and its local name on the network, you can always look for its IP address and access it via this instead. In order to do so, you may use, for example, `nmap` to scan for all nodes present (in this example assuming that 192.168.0.0 is your local network):
```bash
nmap -sn 192.168.0.0/24
```
If you need to compare the obtained map with and without the Raspberry Pi Zero present, you may find it convenient to generate text file output and compare two sessions with the unit switched on and off, using
```bash
nmap -sn 192.168.0.0/24 -oG output.txt
```

## Log in to your Raspberry Pi Zero
```bash
ssh user@rpi-zero-elpris.local
```
It is quite convenient to generate SSH Key pairs so that you can log in to your Raspberry Pi Zero as remote host without having to present your password every time. Do this by the following, starting with the Raspberry Pi Zero which you currently have logged in to:
```bash
ssh-keygen -b 2048 -t rsa
```
The `ssh-keygen` command generates an SSH key pair consisting of a public key and a private key, and saves them in the specified path. The file name of the public key is created automatically by appending `.pub` to the name of the private key file. For example, if the file name of the SSH private key is `id_rsa`, the file name of the public key would be `id_rsa.pub`.


## References

  [1] Raspberry Pi Zero W (Retrieved April 20, 2025),
      https://www.raspberrypi.com/products/raspberry-pi-zero-w
      https://www.electrokit.com/raspberry-pi-zero-wh-kort-med-inlodd-header

  [2] Inky pHAT (ePaper/eInk/EPD) by Pimoroni (Retrieved April 20, 2025),
      https://shop.pimoroni.com/products/inky-phat
      https://www.electrokit.com/inky-phat-svart/vit/gul
