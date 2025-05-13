<style>
body { counter-reset: h1counter h2counter h3counter h4counter h5counter h6counter; }

h1 { counter-reset: h2counter; }
h2 { counter-reset: h3counter; }
h3 { counter-reset: h4counter; }
h4 { counter-reset: h5counter; }
h5 { counter-reset: h6counter; }
h6 {}

h2:before {
    counter-increment: h2counter;
    content: counter(h2counter) ".\0000a0\0000a0";
}

h3:before {
    counter-increment: h3counter;
    content: counter(h2counter) "." counter(h3counter) ".\0000a0\0000a0";
}

h4:before {
    counter-increment: h4counter;
    content: counter(h2counter) "." counter(h3counter) "." counter(h4counter) ".\0000a0\0000a0";
}

h5:before {
    counter-increment: h5counter;
    content: counter(h2counter) "." counter(h3counter) "." counter(h4counter) "." counter(h5counter) ".\0000a0\0000a0";
}

h6:before {
    counter-increment: h6counter;
    content: counter(h2counter) "." counter(h3counter) "." counter(h4counter) "." counter(h5counter) "." counter(h6counter) ".\0000a0\0000a0";
}
</style>

<h1>ELPRIS - logging the price of electricity in Scandinavia</h1>

The `elpris` project uses a Raspberry Pi Zero W and a Pimoroni Inky pHAT 2.13"
display for the continuous logging of the current price for electricity.

<h1>Installation</h1>

<h2>Install disk image</h2>
Install a brand new Raspberry Pi OS, using the instructions at https://www.raspberrypi.com/software/

<h2>Finding your Raspberry Pi Zero on the local network</h2>
Usually, your Raspberry Pi Zero will automatically show up on your local network with the name you assigned it, regardless of whether you are using a wired or wireless (WiFi) connection to it. You can check its presence by, say, pinging it:
```bash
(base) user@computer:~/elpris$ ping rpi-zero-elpris.local
PING rpi-zero-elpris.local (192.168.0.16) 56(84) bytes of data.
64 bytes from 192.168.0.16: icmp_seq=1 ttl=64 time=4.01 ms
64 bytes from 192.168.0.16: icmp_seq=2 ttl=64 time=4.99 ms
^C
--- rpi-zero-elpris.local ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 4.005/4.833/5.279/0.489 ms
```
If the unit has not showed up within a few minutes, being enough for your local router to assign DHCP and its local name on the network, you can always look for its IP address and access it via this instead. In order to do so, you may use, for example, `nmap` to scan for all nodes present (in this example assuming that 192.168.0.0 is your local network):
```bash
(base) user@computer:~/elpris$ nmap -sn 192.168.0.0/24
Starting Nmap 7.94SVN ( https://nmap.org ) at 2025-05-13 16:43 CEST
Nmap scan report for _gateway (192.168.0.1)
Host is up (0.00068s latency).
Nmap scan report for 192.168.0.3
Host is up (0.0017s latency).
...
```
If you need to compare the obtained map with and without the Raspberry Pi Zero present, you may find it convenient to generate text file output and compare two sessions with the unit switched on and off, using
```bash
(base) user@computer:~/elpris$ nmap -sn 192.168.0.0/24 -oG output.txt
```

<h2>Log in to your Raspberry Pi Zero</h2>
```bash
user@computer:~/elpris$ ssh user@rpi-zero-elpris.local
Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue May 13 02:24:36 2025
user@rpi-zero-elpris:~ $ 
```
It is quite convenient to generate SSH Key pairs so that you can log in to your Raspberry Pi Zero as remote host without having to present your password every time. Do this by the following, starting with the Raspberry Pi Zero which you currently have logged in to:
```bash
user@rpi-zero-elpris:~ $ ssh-keygen -b 2048 -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/home/frejon/.ssh/id_rsa): 
Created directory '/home/frejon/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/frejon/.ssh/id_rsa
Your public key has been saved in /home/frejon/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:eYcG7DAFyzqLTCGLc6c2QVzv3KOZlPBVT2daHlWvw+k frejon@rpi-zero-elpris
The key's randomart image is:
+---[RSA 2048]----+
|    . ... . . =.+|
| . . o + . o * ..|
|. + . A +   o . .|
|.+ . * B o . . o |
|+ + + * S + . =  |
| = = + + + . . . |
|  * . +       E  |
| . .  +    .     |
|                 |
+----[SHA256]-----+
user@rpi-zero-elpris:~ $ 
```
The `ssh-keygen` command generates an SSH key pair consisting of a public key and a private key, and saves them in the specified path. The file name of the public key is created automatically by appending `.pub` to the name of the private key file. For example, if the file name of the SSH private key is `id_rsa`, the file name of the public key would be `id_rsa.pub`.


<h2>References</h2>

  [1] Raspberry Pi Zero W (Retrieved April 20, 2025),
      https://www.raspberrypi.com/products/raspberry-pi-zero-w
      https://www.electrokit.com/raspberry-pi-zero-wh-kort-med-inlodd-header

  [2] Inky pHAT (ePaper/eInk/EPD) by Pimoroni (Retrieved April 20, 2025),
      https://shop.pimoroni.com/products/inky-phat
      https://www.electrokit.com/inky-phat-svart/vit/gul
