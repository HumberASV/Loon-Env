# Optional Setup and Maintenance Commands

## Remove libreoffice

```bash
sudo apt remove --purge libreoffice* -y
sudo apt autoremove -y
```

## X11 Forwarding
To enable X11 forwarding for running graphical applications from the container on your host machine, you can follow these steps:

```bash
sudo apt update && sudo apt install -y xauth
```

```bash
sudo vi /etc/ssh/sshd_config
```

add lines
```bash
X11Forwarding yes
X11UseLocalhost yes
```

restart ssh service
```bash
sudo systemctl restart sshd
```