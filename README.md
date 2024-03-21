# Install Docker

~~~
curl -fsSL https://get.docker.com | bash -s docker
~~~

# docker-compose运行

## 创建docker-compose.yml

~~~
version: "3.3"
services:
  spug-mysql:
    image: mysql:8.0
    container_name: spug-mysql
    restart: always
    environment:
      MYSQL_DATABASE: "spug"
      MYSQL_ROOT_PASSWORD: "123456"
    ports:
      - '3306:3306'
    volumes:
      - ./docker/mysql/data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 5

  spug:
    image: zhiqiangwang/spug:latest
    container_name: spug
    privileged: true
    restart: always
    volumes:
      - ./redis:/var/lib/redis
      - ./nginx:/var/log/nginx
      - ./spug/logs:/data/spug/spug_api/logs
      - ./spug/repos:/data/repos
      
    ports:
      # 如果80端口被占用可替换为其他端口，例如: - "8000:80"
      - "80:80"
    depends_on:
      - spug-mysql
    environment:
      - MYSQL_DATABASE=spug
      - MYSQL_USER=root
      - MYSQL_PASSWORD=123456
      - MYSQL_HOST=spug-mysql
      - MYSQL_PORT=3306
~~~

## 启动容器

~~~
docker compose up -d
~~~

# Common commands

~~~
//初始化。
docker exec spug init_spug admin spug.cc
//初始化数据库
docker exec spug python3 /data/spug/spug_api/manage.py updatedb
//重置账户密码
docker exec spug python3 /data/spug/spug_api/manage.py user reset -u admin -p 123456
//启用账户
docker exec spug python3 /data/spug/spug_api/manage.py user enable -u admin
//禁用登录MFA
docker exec spug python3 /data/spug/spug_api/manage.py set mfa disable
~~~

# Golang Dockerfile

~~~
FROM zhiqiangwang/spug:latest

RUN apt update

# golang
ARG GOLANGURL=https://go.dev/dl/go1.18.10.linux-amd64.tar.gz
RUN cd /tmp && wget ${GOLANGURL} -O go.tar.gz && tar -xf go.tar.gz -C /usr/local 
ENV GOROOT=/usr/local/go 
ENV GOPATH=/root/go
ENV GO111MODULE=auto
ENV GOPROXY=https://goproxy.io,direct
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# 清理缓存
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/*
~~~

# Link

[https://spug.cc/](https://spug.cc/)

[https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)

