# Developer Documentation

This document explains how to set up the development environment from scratch, build and run the project, and manage its containers and data.

---

## 1. Prerequisites

| Component | Version / Notes |
|---|---|
| Host hypervisor | VirtualBox |
| Guest OS | Alpine Linux (penultimate stable release) with XFCE |
| Container engine | Docker + Docker Compose plugin |
| Editor (optional) | VS Code (via Flatpak) |

---

## 2. Virtual machine setup

### 2.1 Create the VM

1. Create a new VirtualBox VM (Linux, other 64-bit) with at least 2 CPUs, 4 GB RAM and 20 GB disk.
2. Install Alpine Linux from the official ISO using `setup-alpine`.
3. Install a desktop environment:

```sh
setup-desktop xfce
```

### 2.2 Create the user and grant sudo

Run as `root`:

```sh
apk add sudo
adduser pmendez
adduser pmendez wheel
visudo
```

In `visudo`, make sure this line is present and uncommented (note the `%`, which means *group*):

```
%wheel ALL=(ALL:ALL) NOPASSWD: ALL
```

### 2.3 Enable the community repository

Edit `/etc/apk/repositories` and uncomment the line ending in `/community`, then:

```sh
sudo apk update
```

### 2.4 Shared folder with the host (VirtualBox)

1. In VirtualBox: *Settings â Shared Folders â* add the project folder, name it `Inception`, check *Auto-mount*.
2. In the VM, install the guest additions and add the user to the `vboxsf` group:

```sh
sudo apk add virtualbox-guest-additions
sudo rc-update add virtualbox-guest-additions default
sudo adduser pmendez vboxsf
sudo reboot
```

The project is then available at `/media/sf_Inception`.

> Group changes only apply after logging out and back in. Check with `id`.

---

## 3. Docker installation

```sh
sudo apk add docker docker-cli-compose
sudo rc-update add docker default
sudo rc-service docker start
sudo adduser pmendez docker
```

Log out and back in, then verify:

```sh
docker --version
docker compose version
docker run --rm hello-world
```

---

## 4. Domain name

The site must be reachable at `pmendez.42.fr`. Add it to `/etc/hosts`:

```sh
echo "127.0.0.1 pmendez.42.fr" | sudo tee -a /etc/hosts
```

---

## 5. Editor (optional): VS Code via Flatpak

The official VS Code build does not run natively on Alpine (musl), so it is installed through Flatpak:

```sh
sudo apk add flatpak dbus dbus-x11 xdg-desktop-portal xdg-desktop-portal-gtk
sudo rc-update add dbus default
sudo rc-service dbus start
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub com.visualstudio.code
sudo reboot
```

Optional `code` command:

```sh
printf '#!/bin/sh\nexec flatpak run com.visualstudio.code "$@"\n' | sudo tee /usr/local/bin/code
sudo chmod +x /usr/local/bin/code
```

---

## 6. Project configuration

### 6.1 Project structure

```
.
âââ Makefile
âââ secrets/
â   âââ credentials.txt
â   âââ db_password.txt
â   âââ db_root_password.txt
âââ srcs/
    âââ .env
    âââ docker-compose.yml
    âââ requirements/
        âââ mariadb/
        âââ nginx/
        âââ wordpress/
```

### 6.2 Environment variables

Create `srcs/.env` (non-sensitive values only):

```
DOMAIN_NAME=pmendez.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

### 6.3 Secrets

Sensitive values are stored in `secrets/` and mounted inside the containers at `/run/secrets/<name>`. Create them:

```sh
mkdir -p secrets
echo "your_db_password"      > secrets/db_password.txt
echo "your_db_root_password" > secrets/db_root_password.txt
echo "your_wp_credentials"   > secrets/credentials.txt
chmod 600 secrets/*
```

> `secrets/` and `srcs/.env` are listed in `.gitignore` and must never be committed.

---

## 7. Build and run

From the project root:

| Command | Action |
|---|---|
| `make` | Creates the data directories, builds the images and starts the containers |
| `make down` | Stops and removes the containers |
| `make clean` | `down` + removes unused images and build cache |
| `make fclean` | `clean` + removes volumes and persistent data |
| `make re` | Full rebuild from scratch |

Once running, open `https://pmendez.42.fr` in the browser.

---

## 8. Managing containers and volumes

```sh
docker ps                          # running containers
docker compose -f srcs/docker-compose.yml logs -f   # follow logs
docker exec -it mariadb sh         # shell inside a container
docker volume ls                   # list volumes
docker volume inspect <volume>     # volume details
docker network ls                  # list networks
```

---

## 9. Data persistence

Persistent data lives on the VM, outside the containers:

| Volume | Container path | Host path |
|---|---|---|
| `mariadb_data` | `/var/lib/mysql` | `/home/pmendez/data/mariadb` |
| `wordpress_data` | `/var/www/html` | `/home/pmendez/data/wordpress` |

Data survives `make down` and container restarts. It is only deleted with `make fclean`.