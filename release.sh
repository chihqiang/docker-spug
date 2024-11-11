#!/bin/bash

set -e
set -u

# ubuntu: apt install -y jq
# mac:  brew install jq

# 获取tag版本号
version=$(curl --silent "https://api.github.com/repos/openspug/spug/tags" | jq -r '.[0].name')

#本地已经发布的版本号
currentversion=$(cat currentversion)

if [[ $version =~ ^v ]]; then
  version=${version#v}
fi

echo "currentversion:$currentversion version:$version"

# 判断版本号是否相同 如果相同就exit
if [[ "$currentversion" == "$version" ]]; then
    exit
fi

echo "Submit Docker Image"
# 登录仓库
docker login -u $DOCKER_USER -p $DOCKER_PWD
# 构建仓库
docker build --build-arg="SPUG_VERSION=$version" -t zhiqiangwang/spug:$version  .
# 发布仓库
echo "Release Docker Version: " $version
docker push zhiqiangwang/spug:$version


echo "Release Docker Version latest"
# docker pull 
docker build  --build-arg="IMAGE_TAG=$version" -f Dockerfile.latest   -t zhiqiangwang/spug:latest  .
docker push zhiqiangwang/spug:latest

echo "Submit the latest code"
# 更新代码
echo "$version" >currentversion
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add currentversion
git commit -a -m "Auto Update spug to buildid: $version"
git push origin main
