# Evaluation Guide

Step-by-step guide to show the project during the defense. It follows the order of the evaluation scale. Every command is run from the root of the cloned repository, unless said otherwise.

For everyday use of the stack, see [USER_DOC.md](USER_DOC.md). 
For how it works inside, see [DEV_DOC.md](DEV_DOC.md).

> **Before the defense day:** make sure `/etc/hosts` contains `127.0.0.1 pmendez-.42.fr`, that `curl` and `openssl` are installed in the VM (`sudo apk add curl openssl`), and that Docker starts on boot (`sudo rc-update add docker default`).

## Step 1. Clone the repository in an empty folder

```sh
cd ~ && rm -rf inception-eval && mkdir inception-eval && cd inception-eval
```

![Folder Preparation](.img/guideDoc/folder_preparation.png)

In order to be able to clone the repository, the Virtual Machine must have the SSH key of the GitHub account.

![SSH Key](.img/guideDoc/ssh_keygen.png)

**That key must be added to the GitHub account, in *Settings → SSH and GPG keys → New SSH key*.**

```sh
git clone git@github.com:pauss12/Inception.git
```

![Clone](.img/guideDoc/cloning_project.png)

It must show the three folders: `Inception`, `srcs`, `secrets` (the last one is empty). The evaluator checks that no credentials are in git:
Makefile, srcs/, README.md, USER_DOC.md, DEV_DOC.md

```sh
cd Inception
ls -la
```

![Repository Structure](.img/guideDoc/step.png)

It must print nothing: no credentials in git

```sh
git ls-files secrets srcs/.env
```

![No Credentials in Git](.img/guideDoc/check_env.png)

## Step 2. Clean Docker and the old data

The evaluator runs the cleaning command of the scale:

```sh
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

![Docker Clean](.img/guideDoc/docker_clean.png)

That command does not delete the data folder. Delete it too, so the site is installed from zero with the new passwords:

```sh
sudo rm -rf /home/pmendez/data
```

![Data Folder Removal](.img/guideDoc/data_folder_removal.png)

> If the old data is kept and the new secrets are different, WordPress cannot connect to the old database.

## Step 3. Create `.env` and the secrets

They are not in git (on purpose), so they are created now, in front of the evaluator:

```sh
cat > srcs/.env << 'END'
DOMAIN_NAME=pmendez-.42.fr
DB_NAME=wordpress
DB_USER=wpuser
WP_TITLE=Inception
WP_ADMIN_USER=pmendez_boss
WP_ADMIN_EMAIL=pmendez-@student.42.fr
WP_USER=pmendez_user
WP_USER_EMAIL=user@student.42.fr
END

mkdir -p secrets
for s in db_password db_root_password wp_admin_password wp_user_password; do
  openssl rand -base64 18 > secrets/$s.txt
done
chmod 600 secrets/*
```

> If `openssl` is not found, install it first: `sudo apk add openssl`.

Check that everything was created:

```sh
cat srcs/.env      # the variables above
ls secrets/        # 4 .txt files
```

![Secrets Created](.img/guideDoc/env_created_check.png)

> ⚠️ Do not skip this step: without these files, `make` fails with `env file .../srcs/.env not found`.

## Step 4. Show the files the evaluator checks

| What the evaluator checks | Where to show it |
|---|---|
| No `network: host` and no `links:`; a `networks:` section exists | `srcs/docker-compose.yml` |
| No `--link` | `Makefile`, `srcs/docker-compose.yml` |
| One non-empty Dockerfile per service, each starting with `FROM alpine:3.23` | `srcs/requirements/*/Dockerfile` |
| No `tail -f`, no `sleep infinity`, no program started in the background | `CMD` of each Dockerfile and `tools/*.sh` |
| No password in any Dockerfile | `grep -ri password srcs/requirements/*/Dockerfile` only shows comments or variable names |

Quick checks:

```sh
grep -rnE 'network: *host|links:|--link' Makefile srcs/       # must print nothing
grep -rnE 'tail -f|sleep infinity|while true' srcs/          # must print nothing
grep -n '^FROM' srcs/requirements/*/Dockerfile               # alpine:3.23 in the 3 files
```

Points to explain:

- `sh /wp-installer.sh` uses `sh` **only to run a script**, which the scale allows.
- The `until mariadb-admin ping ...` loop in `wp-installer.sh` is **not** an infinite loop: it only waits until MariaDB answers, then the script continues and ends with `exec`.
- Each script ends with `exec <server>`, so the server is PID 1 in the foreground (see [DEV_DOC.md, section 6.5](DEV_DOC.md#65-pid-1-the-main-process-of-a-container)).

## Step 5. Run the Makefile

```sh
make
```

Wait about a minute (first install), then:

```sh
docker compose -f srcs/docker-compose.yml ps    # nginx, wordpress, mariadb: "Up"
docker images                                   # nginx, wordpress, mariadb (tag "inception", not "latest")
docker logs wordpress                           # ends with "Arrancando PHP-FPM..."
```

## Step 6. Explain the basics (activity overview)

Be ready to explain, with simple words:

| Question | Short answer |
|---|---|
| How Docker works | A container runs one program isolated from the rest of the system, using the host's kernel. It is created from an **image**, built from a **Dockerfile** |
| How docker compose works | One YAML file describes several containers, their network, volumes and secrets; `docker compose up` creates and starts all of them in order |
| Image with and without compose | Without compose: each image is built and run by hand with long `docker build` / `docker run` commands, and the network and volumes are created by hand. With compose: everything is declared once in `docker-compose.yml` and managed together |
| Docker vs VM | A VM emulates a whole computer with its own kernel (heavy, slow to boot). A container shares the host kernel (light, starts in seconds) |
| Directory structure | `Makefile` at the root drives everything; `srcs/` holds all the configuration; one folder per service in `srcs/requirements/` with its `Dockerfile`, `conf/` and `tools/`; `secrets/` holds the passwords outside git |

## Step 7. README and documentation

```sh
head -1 README.md       # the italic line with the login
grep -n '^## ' README.md   # Description, Instructions, Resources (with the use of AI), Project description
ls USER_DOC.md DEV_DOC.md
```

## Step 8. NGINX, port 443 only, TLS

```sh
docker compose -f srcs/docker-compose.yml ps    # only nginx publishes a port: 443
```

1. **HTTP does not work** (no port 80):

   ```sh
   curl -I http://pmendez-.42.fr      # "Connection refused"
   ```

2. **HTTPS works**: open **https://pmendez-.42.fr** in the browser. Accept the self-signed certificate warning. The WordPress site appears directly, **not** the installation page.

3. **TLS v1.2 / v1.3 are used**:

   ```sh
   openssl s_client -connect pmendez-.42.fr:443 -tls1_2 </dev/null 2>/dev/null | grep -E 'Protocol|Cipher is'   # TLSv1.2 works
   openssl s_client -connect pmendez-.42.fr:443 -tls1_3 </dev/null 2>/dev/null | grep -E 'Protocol|Cipher is'   # TLSv1.3 works
   curl -kI --tlsv1.1 --tls-max 1.1 https://pmendez-.42.fr       # fails: TLS 1.1 is refused
   ```

   In the browser: click the padlock → *Connection* / *Certificate* details also shows the TLS version.

4. Show the TLS lines in `srcs/requirements/nginx/conf/nginx.conf`: `listen 443 ssl;` and `ssl_protocols TLSv1.2 TLSv1.3;`.

## Step 9. Docker network

```sh
docker network ls                          # srcs_inception
docker network inspect srcs_inception      # the 3 containers are inside
```

Explanation: the three containers are in a private network created by Docker. Inside it they find each other **by name** (`wordpress:9000`, `mariadb:3306`). From outside, only nginx's port 443 is reachable.

## Step 10. WordPress, PHP-FPM and its volume

1. Show that the WordPress Dockerfile installs **no nginx** (only PHP, PHP-FPM, WP-CLI).
2. Volume:

   ```sh
   docker volume ls                         # srcs_wordpress, srcs_mariadb
   docker volume inspect srcs_wordpress     # "device": "/home/pmendez/data/wordpress"
   ```

3. **Comment with the normal user**: open https://pmendez-.42.fr/wp-login.php, log in as `pmendez_user` (password: `cat secrets/wp_user_password.txt`), open the "Hello world!" post and add a comment.
   If the comment shows *"Your comment is awaiting moderation"*, that is the normal WordPress behaviour: the administrator approves it in the next step.
4. **Administrator**: log out, log in as `pmendez_boss` (password: `cat secrets/wp_admin_password.txt`). The username does not contain "admin". The dashboard opens at https://pmendez-.42.fr/wp-admin.
   - If the comment was pending: *Comments* → *Approve*.
5. **Edit a page**: *Pages* → *Sample Page* → change the text → *Save* / *Update*. Open the page on the website and show the change.

## Step 11. MariaDB and its volume

1. Show that the MariaDB Dockerfile installs **no nginx**.
2. Volume:

   ```sh
   docker volume inspect srcs_mariadb       # "device": "/home/pmendez/data/mariadb"
   ```

3. **Log in to the database** (the password is in `secrets/db_password.txt`):

   ```sh
   cat secrets/db_password.txt
   docker exec -it mariadb mariadb -u wpuser -p
   ```

   Then, inside MariaDB:

   ```sql
   SHOW DATABASES;
   USE wordpress;
   SHOW TABLES;                                  -- wp_posts, wp_users, wp_comments...
   SELECT user_login FROM wp_users;              -- pmendez_boss, pmendez_user
   SELECT comment_content FROM wp_comments;      -- the comment from step 10
   EXIT;
   ```

   The database is not empty. Root also has a password: `mariadb -u root` without password is refused.

## Step 12. Persistence

```sh
sudo reboot
```

After the reboot, go back to the repository folder:

```sh
docker ps          # the containers start again by themselves (restart: unless-stopped)
make               # if they are not running, start them
```

Open https://pmendez-.42.fr again: the edited page and the comment are still there, and the admin can still log in. `docker logs wordpress` shows no new installation (`wp-config.php` already existed in the volume).

## Step 13. Configuration modification

The evaluator asks to change the configuration of one service, for example a port. The data is kept: a rebuild does not touch the volumes. After any change:

```sh
make down && make
```

### Example A: change NGINX's port (443 → 8443)

1. `srcs/requirements/nginx/conf/nginx.conf`: `listen 443 ssl;` → `listen 8443 ssl;`
2. `srcs/requirements/nginx/Dockerfile`: `EXPOSE 443` → `EXPOSE 8443`
3. `srcs/docker-compose.yml`: `"443:443"` → `"8443:8443"`
4. `make down && make`
5. WordPress stores its address (`https://pmendez-.42.fr`), so it would redirect to port 443. Update it:

   ```sh
   docker exec wordpress wp option update home    https://pmendez-.42.fr:8443 --allow-root
   docker exec wordpress wp option update siteurl https://pmendez-.42.fr:8443 --allow-root
   ```

6. Open **https://pmendez-.42.fr:8443**.

To undo it: revert the three files, `make down && make`, and run the two commands again with `https://pmendez-.42.fr`.

### Example B: change PHP-FPM's port (9000 → 9001)

1. `srcs/requirements/wordpress/Dockerfile`: `listen = 9000` → `listen = 9001` in the `sed` line, and `EXPOSE 9000` → `EXPOSE 9001`
2. `srcs/requirements/nginx/conf/nginx.conf`: `fastcgi_pass wordpress:9000;` → `fastcgi_pass wordpress:9001;`
3. `make down && make`, then open https://pmendez-.42.fr: it still works.

### Example C: change MariaDB's port (3306 → 3307)

1. `srcs/requirements/mariadb/conf/mariadb-conf.cnf`: `port = 3306` → `port = 3307`
2. `srcs/requirements/mariadb/Dockerfile`: `EXPOSE 3306` → `EXPOSE 3307`
3. `srcs/requirements/wordpress/tools/wp-installer.sh`: add `-P 3307` to the `mariadb-admin ping` line, and `--dbhost=mariadb:3306` → `--dbhost=mariadb:3307`
4. `make down && make`
5. `wp-config.php` was created with the old port, so update it:

   ```sh
   docker exec wordpress wp config set DB_HOST mariadb:3307 --allow-root
   ```

6. Open https://pmendez-.42.fr: it still works.
