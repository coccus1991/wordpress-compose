FROM nginx:1.13.12
WORKDIR /websites
RUN apt-get update
RUN apt-get install -y nginx-extras
RUN apt-get install libcss-minifier-xs-perl libjavascript-minifier-xs-perl libhtml-packer-perl -y
RUN apt-get install vim -y
RUN apt-get install htop -y
RUN mkdir nginx_confs
RUN mkdir mycertificates
