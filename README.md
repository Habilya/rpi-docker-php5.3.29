# rpi-docker-php5.3.29-fpm

This is a Dockerfile to build an image of PHP5.3.29-fpm

This is needed to ~~support~~ rewrite legacy PHP apps depending on deprecated and removed functionality, such as:

* **register_globals**
* **magic_quotes_gpc**

Check what is enabled in the **volumes/conf.d/php.ini**

## Volumes

You may use the volumes of the container in the `./volumes` directory
* You may edit the configs in the `./volumes/conf.d` and restart the container
* You may view the php-fpm log in the `./volumes/php-fpm-log`

## Installation

You will need to have **git** and **docker** installed.

```
sudo apt-get install git
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker [user_name]
sudo apt-get install docker-compose
```


## Clone the repository
git clone https://github.com/Habilya/rpi-docker-php5.3.29-fpm.git

## Build a docker image
```
cd rpi-docker-php5.3.29-fpm
```
Before building, feel free to edit:

* Dockerfile (edit if running not on a Raspberry Pi)
* docker-compose.yml
* volumes/conf.d/php.ini
* volumes/conf.d/php-fpm.conf

This container runs under a non-privileged `www-data` user, you will have to have it in your host system, and set the permissions on thevolumes
```
sudo usermod -aG www-data [YOUR_USER]
exec su -l $USER
sudo chown www-data:www-data -R ./volumes
sudo chmod 770 -R ./volumes
```

To build a container, run the following command:
```
export WWWUNAME=www-data && export WWWUID=$(id -u $WWWUNAME) && export WWWGID=$(id -g $WWWUNAME)
docker-compose up -d
```
## Configure webserver NginX
```
fastcgi_pass 127.0.0.1:9000;
```


_Note : This was developed for a Raspberry Pi, should work just fine on any other OS._

Just change the

```
FROM balenalib/raspberrypi3-alpine:latest
```

to something like

```
FROM alpine:latest
```

Please contribute.

Cheers!
