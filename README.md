# rpi-docker-php5.3.29-fpm

This is a Dockerfile to build an image of PHP5.3.29-fpm

This is needed to ~~support~~ rewrite legacy PHP apps depending on deprecated and removed functionality, such as:

* register_globals
* magic_quotes_gpc

Check what is enabled in the **conf/php.ini**

## Installation

You will need to have **git** and **docker** installed.

```
sudo apt-get install git
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker [user_name]
sudo apt-gget install docker-compose
```


# clone the repository
git clone https://github.com/Habilya/rpi-docker-php5.3.29-fpm.git

# build a docker image
```
cd rpi-docker-php5.3.29-fpm
```
Before building, feel free to edit the docker-compose.yml

To build a container, run the following command:
```
docker-compose up -d
```
# in your webserver config use the php5.3 (php5_3 - is the name of container, should be resolved to the container's IP)
```
fastcgi_pass php5_3:9000;

```



_Note : This was developed for a Raspberry Pi, should work just fine on any other OS._

Just change the

```
FROM balenalib/rpi-raspbian:latest
```

to something like

```
FROM ubuntu:14.04
```

Please contribute.

Cheers!
