# User Documentation

This document explains how to use the Inception stack: what it provides, how to start and stop it, how to access the website, where the credentials are, and how to check that everything works.

All commands are run from the project root folder.

---

## 1. What the stack provides

The project runs a **WordPress website** served over HTTPS. It is made of three services, each in its own container:

| Service | What it does |
|---|---|
| **NGINX** | The web server. It receives every visit on `https://pmendez-.42.fr` (port 443) and is the only part reachable from outside |
| **WordPress** | The website itself (PHP-FPM runs the WordPress code) |
| **MariaDB** | The database: posts, pages, users and settings |

The website files and the database are stored on the machine in `/home/pmendez/data`, so nothing is lost when the stack is stopped.

---

## 2. Start and stop the project

| Command | What it does |
|---|---|
| `make` | Builds and starts everything |
| `make down` | Stops everything. **Data is kept** |
| `make` (again) | Starts it again with the same data |
| `make clean` | Stops everything and **deletes all data** (website and database) |
| `make re` | Deletes everything and starts again from zero |

> The first start takes about a minute: WordPress is downloaded and installed automatically. The next starts are almost immediate.

> ⚠️ `make clean` and `make re` delete the website and the database permanently.

---

## 3. Access the website and the administration panel

> The machine must know the domain. If the site does not open, check that `/etc/hosts` contains the line `127.0.0.1 pmendez-.42.fr`.

| What | Address |
|---|---|
| Website | **https://pmendez-.42.fr** |
| Administration panel | **https://pmendez-.42.fr/wp-admin** |

The first time, the browser warns that the connection is not private. This is expected: the HTTPS certificate is self-signed (created by the project, not by an official authority). Click *Advanced* → *Accept the risk / Continue*.

Only HTTPS works: `http://pmendez-.42.fr` (without the **s**) does not open.

---

## 4. Credentials

### 4.1 Where they are

| Account | Username | Password |
|---|---|---|
| WordPress administrator | `WP_ADMIN_USER` in `srcs/.env` | `secrets/wp_admin_password.txt` |
| WordPress user (author) | `WP_USER` in `srcs/.env` | `secrets/wp_user_password.txt` |
| Database user of WordPress | `DB_USER` in `srcs/.env` | `secrets/db_password.txt` |
| Database `root` | `root` | `secrets/db_root_password.txt` |

To read a password:

```sh
cat secrets/wp_admin_password.txt
```

These files are **not** stored in git. Keep them private and do not share them.

### 4.2 Change them

- **WordPress passwords**: log in to the administration panel → *Users* → choose the user → *Set New Password*. Note that the file in `secrets/` is not updated automatically.
- **Values in `srcs/.env` or `secrets/`**: they are only used when the site is installed for the first time. To apply new values, the data must be deleted and the site reinstalled (`make re`), which **erases the website content**.

---

## 5. Check that the services are running

### 5.1 The containers are up

```sh
docker ps
```

The three containers `nginx`, `wordpress` and `mariadb` must appear with status `Up`.

### 5.2 The logs show no errors

```sh
docker logs nginx
docker logs wordpress      # must end with "Arrancando PHP-FPM..."
docker logs mariadb        # must contain "ready for connections"
```

### 5.3 The website answers

```sh
curl -kI https://pmendez-.42.fr          # first line: HTTP/1.1 200 OK
```

Or simply open the website in the browser and log in to the administration panel.

### 5.4 WordPress and the database

```sh
docker exec wordpress wp user list --allow-root
```

It lists the two WordPress users: the administrator and the author.

### 5.5 Common problems

| Problem | What to do |
|---|---|
| The browser cannot find `pmendez-.42.fr` | Add `127.0.0.1 pmendez-.42.fr` to `/etc/hosts` |
| The browser shows a "connection refused" error | Make sure the containers are running (`docker ps`) and the ports are correctly mapped |
| The browser shows a "connection timed out" error | Check the firewall settings and make sure the ports are open |
| The browser shows a "SSL connection error" | This is usually due to the self-signed certificate. Accept it (see section 3) |
| The browser shows a "certificate error" | Normal: accept it (see section 3) |
| The site does not load right after `make` | Wait about a minute on the first start; check `docker logs wordpress` |
| A container is not `Up` | Look at its logs (`docker logs <name>`) and run `make down` then `make` |
| Forgot a password | Read it in `secrets/` (see section 4) |

For more technical details, see [DEV_DOC.md](DEV_DOC.md).

---

## 6. More information

- How the stack works inside: [DEV_DOC.md](DEV_DOC.md#6-how-the-project-works)
- Technical explanation of every file: [DEV_DOC.md](DEV_DOC.md#7-project-files-one-by-one)
- Step-by-step guide for the evaluation: [GUIDE.md](GUIDE.md)
