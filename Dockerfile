FROM ubuntu:18.04

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && apt-get update

RUN apt install -y git curl gnupg2 ca-certificates lsb-release wget redis supervisor python3-dev python3-pip rsync sshfs default-libmysqlclient-dev libldap2-dev libssl-dev build-essential libsasl2-dev locales
# nginx1.14.0
RUN apt install -y nginx

RUN pip3 install --no-cache-dir --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/
RUN pip3 install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/ \
    gunicorn \
    mysqlclient \
    cryptography==36.0.2 \
    apscheduler==3.7.0 \
    asgiref==3.2.10 \
    Django==2.2.28 \
    channels==2.3.1 \
    channels_redis==2.4.1 \
    paramiko==2.11.0 \
    django-redis==4.10.0 \
    requests==2.22.0 \
    GitPython==3.0.8 \
    python-ldap==3.4.0 \
    openpyxl==3.0.3 \
    user_agents==2.2.0

ARG SPUG_VERSION=3.3.0
ENV MYSQL_DATABASE=spug
ENV MYSQL_USER=spug
ENV MYSQL_PASSWORD=spug.cc
ENV MYSQL_HOST=127.0.0.1
ENV MYSQL_PORT=3306

RUN mkdir -p /data/spug
RUN cd /tmp && wget https://github.com/openspug/spug/archive/refs/tags/v${SPUG_VERSION}.tar.gz -O spug.tar.gz \
    && tar -xf spug.tar.gz -C /data/spug/ --strip-components=1

RUN cd /tmp && curl -o web.tar.gz https://cdn.spug.cc/spug/web_v${SPUG_VERSION}.tar.gz \
    && tar xf web.tar.gz -C /data/spug/spug_web/

RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN echo '\n# Source definitions\n. /etc/profile\n' >> /root/.bashrc
RUN mkdir -p /data/repos
COPY init_spug /usr/bin/
RUN chmod +x /usr/bin/init_spug
COPY nginx.conf /etc/nginx/
COPY ssh_config /etc/ssh/
COPY spug.ini /etc/supervisor/conf.d/spug.conf
COPY redis.conf /etc/
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

VOLUME /data
EXPOSE 80

RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/*

ENTRYPOINT ["/entrypoint.sh"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
STOPSIGNAL SIGQUIT