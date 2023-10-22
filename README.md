# docker-spug

~~~
docker build --build-arg="SPUG_VERSION=3.2.7" -t zhiqiangwang/spug:3.2.7  .
~~~

# golang Dockerfile
~~~
FROM zhiqiangwang/spug:3.2.7

RUN apt update

RUN cd /tmp && wget https://go.dev/dl/go1.18.10.linux-amd64.tar.gz -O go.tar.gz \
    && tar -xf go.tar.gz -C /usr/local 

ENV GOROOT=/usr/local/go 
ENV GOPATH=/root/go
ENV GO111MODULE=auto
ENV GOPROXY=https://goproxy.cn,direct
ENV PATH=$PATH:$GOROOT/bin
ENV PATH=$PATH:$GOPATH/bin

RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/*
~~~