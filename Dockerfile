FROM ubuntu:22.04

# 版本
ARG SPUG_VERSION=3.3.2

# 安装依赖
RUN apt-get update && apt install -y default-libmysqlclient-dev libldap2-dev libssl-dev gnupg2 ca-certificates lsb-release build-essential libsasl2-dev pkg-config locales \
  rsync git curl wget sshfs \
  nginx redis supervisor python3-dev python3-pip

# 安装源代码
RUN mkdir -p /data/spug
RUN cd /tmp && wget https://github.com/openspug/spug/archive/refs/tags/v${SPUG_VERSION}.tar.gz -O spug.tar.gz \
    && tar -xzvf spug.tar.gz -C /data/spug/ --strip-components=1

# 安装pip依赖
RUN pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir -r /data/spug/spug_api/requirements.txt
RUN pip3 install --no-cache-dir \
    gunicorn \
    mysqlclient \
    apscheduler==3.7.0 \
    user_agents==2.2.0

# 安装编译好的web页面
RUN cd /tmp && curl -o web.tar.gz https://cdn.spug.cc/spug/web_v${SPUG_VERSION}.tar.gz \
    && tar -xzvf web.tar.gz -C /data/spug/spug_web/

# mysql数据库相关配置
ENV MYSQL_DATABASE=spug
ENV MYSQL_USER=spug
ENV MYSQL_PASSWORD=spug.cc
ENV MYSQL_HOST=127.0.0.1
ENV MYSQL_PORT=3306

# 环境变量
RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN echo -e '\n# Source definitions\n. /etc/profile\n' >> /root/.bashrc
RUN mkdir -p /data/repos

COPY init_spug /usr/bin/
RUN chmod +x /usr/bin/init_spug
COPY nginx.conf /etc/nginx/
COPY ssh_config /etc/ssh/
COPY spug.ini /etc/supervisor/conf.d/spug.conf
COPY redis.conf /etc/
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

WORKDIR /data
VOLUME /data

EXPOSE 80

RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/*

ENTRYPOINT ["/entrypoint.sh"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
STOPSIGNAL SIGQUIT