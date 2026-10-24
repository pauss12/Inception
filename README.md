*This project has been created as part of the 42 curriculum by pmendez-*

# Inception

## Description

Inception is a system administration project. The goal is to build a small web infrastructure with **Docker Compose**, inside a virtual machine, writing every Docker image from scratch.

The infrastructure serves a **WordPress** website over HTTPS and is made of three containers, each running a single service:

| Container | Service | Port |
|---|---|---|
| `nginx` | Web server, the only entry point (TLSv1.2 / TLSv1.3) | 443 (published) |
| `wordpress` | WordPress + PHP-FPM, runs the PHP code | 9000 (internal) |
| `mariadb` | Database of the website | 3306 (internal) |

```
 Browser ──443 (HTTPS)──▶ NGINX ──9000──▶ WordPress + PHP-FPM ──3306──▶ MariaDB
                            │                     │                         │
                            └──── volume: website files ────┘     volume: database
```

The containers talk to each other through a private Docker network, and the website files and the database are stored in two named volumes, so the data survives restarts and rebuilds.

## Instructions

### Requirements

- A Linux virtual machine with **Docker** and the **Docker Compose** plugin.
- `make`.
- The domain pointing to the machine:

```sh
echo "127.0.0.1 pmendez-.42.fr" | sudo tee -a /etc/hosts
```

### Configuration

Two things are not in the repository and must be created first (see [DEV_DOC.md](DEV_DOC.md#8-configuration-from-scratch-env-and-secrets) for the full explanation):

1. **`srcs/.env`**: non-secret settings (domain, database name, WordPress usernames and emails).
2. **`secrets/`**: one file per password:

```sh
mkdir -p secrets
openssl rand -base64 18 > secrets/db_password.txt
openssl rand -base64 18 > secrets/db_root_password.txt
openssl rand -base64 18 > secrets/wp_admin_password.txt
openssl rand -base64 18 > secrets/wp_user_password.txt
```

### Run

| Command | Action |
|---|---|
| `make` | Build the images and start the containers |
| `make down` | Stop and remove the containers (data is kept) |
| `make clean` | Remove containers, images, volumes and data |
| `make re` | Rebuild everything from zero |

Then open **https://pmendez-.42.fr** (the certificate is self-signed, so the browser shows a warning: accept it). The administration panel is at **https://pmendez-.42.fr/wp-admin**.

More documentation:

- [USER_DOC.md](USER_DOC.md): how to use and check the running stack.
- [DEV_DOC.md](DEV_DOC.md): how to set it up from scratch and how every file works.

## Project description

### Use of Docker

Each service has its own folder in `srcs/requirements/` with:

- A **Dockerfile** built from `alpine:3.23` (the penultimate stable Alpine release). No ready-made images are pulled, apart from the Alpine base;

- A **conf/** folder with the service configuration (`nginx.conf`, `mariadb-conf.cnf`);

- A **tools/** script run when the container starts. It reads the passwords from the secrets, performs the setup only the first time (creating the database, installing WordPress with WP-CLI), and finally replaces itself with the server using `exec`, so the server runs as **PID 1** in the foreground.

**PID 1** is important: it receives the stop signals from Docker directly, so the container can stop gracefully. No infinite loops (`tail -f`, `sleep infinity`…) are used. See [DEV_DOC.md](DEV_DOC.md#65-pid-1-the-main-process-of-a-container) for a full explanation.


`srcs/docker-compose.yml` defines the three services, the network, the volumes and the secrets, and the `Makefile` drives Docker Compose.

### Main design choices

- **Alpine** as base image: small images and fast builds.
- **NGINX as the only entry point**: only port 443 is published; PHP-FPM (9000) and MariaDB (3306) are only reachable inside the Docker network.
- **Self-signed TLS certificate** generated at build time with `openssl`, restricted to TLSv1.2 and TLSv1.3.
- **WP-CLI** to install and configure WordPress automatically, without the web installer.
- **Idempotent start scripts**: they detect existing data (`wp-config.php`, `/var/lib/mysql/mysql`) and skip the installation, so restarting never reinstalls or overwrites anything.
- **No infinite loops** (`tail -f`, `sleep infinity`…): every server runs in the foreground as PID 1 and receives Docker's stop signals directly.
- **`restart: unless-stopped`**: a crashed container is restarted automatically.

### Virtual Machines vs Docker

| Virtual machine | Docker container |
|---|---|
| Emulates a full computer, with its own kernel | Shares the host's kernel; isolates processes only |
| Heavy: GBs of disk, minutes to boot | Light: MBs, starts in seconds |
| Strong isolation | Lighter isolation (namespaces and cgroups) |
| Good to run a whole different OS | Good to package and run one service |

In this project both are used: the VM is the host machine, and inside it each service runs in its own container.

### Secrets vs Environment Variables

| Environment variables (`.env`) | Docker secrets (`secrets/`) |
|---|---|
| Visible with `docker inspect` and to every process of the container | Mounted as files in `/run/secrets/`, only in the containers that declare them |
| Fine for non-sensitive settings | Meant for passwords and keys |
| Used here for: domain, database name, usernames, emails | Used here for: the four passwords |

Both `srcs/.env` and `secrets/` are ignored by git, so no credentials are stored in the repository.

### Docker Network vs Host Network

| Docker (bridge) network | Host network |
|---|---|
| Containers get their own private network | Containers use the host's network directly |
| Containers find each other by name (`mariadb`, `wordpress`) | No name resolution between containers |
| Only explicitly published ports are reachable from outside | Every port opened by a container is open on the host |

This project uses a bridge network called `inception`, so only port 443 is exposed; `network: host` is forbidden by the subject.

### Docker Volumes vs Bind Mounts

| Named volume | Bind mount |
|---|---|
| Created and managed by Docker (`docker volume ls`) | Any host path mounted directly into the container |
| Declared once and shared by name between services | Path written in each service |
| Independent from the host's folder layout | Depends on the host's folders and permissions |

The subject requires **named volumes** stored in `/home/pmendez-/data`. The two volumes (`wordpress` and `mariadb`) are named volumes declared in `docker-compose.yml`; the `local` driver option `device:` only tells Docker in which host folder to keep their data.

## Resources

### Documentation

- [Docker documentation](https://docs.docker.com/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [NGINX documentation](https://nginx.org/en/docs/) and the [`ngx_http_ssl_module`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [NGINX + PHP-FPM (FastCGI)](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)
- [WP-CLI commands](https://developer.wordpress.org/cli/commands/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [Alpine Linux wiki](https://wiki.alpinelinux.org/)

### Use of AI

AI (Claude) was used as a support tool during the project:

- **Explanations**: to understand concepts such as how NGINX and PHP-FPM communicate, named volumes, Docker secrets and PID 1 in containers.
- **Debugging**: to find the cause of errors while building and running the stack (for example, the PHP memory limit when WP-CLI downloads WordPress, and MariaDB not accepting network connections).
- **Code review and readability**: to review the Dockerfiles and start scripts, make them consistent between services and add comments.
- **Documentation**: to help structure and write `README.md`, `USER_DOC.md` and `DEV_DOC.md`.

Every piece of generated content was reviewed, tested in the virtual machine and understood before being kept in the project.
