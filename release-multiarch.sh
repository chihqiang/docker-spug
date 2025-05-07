#!/bin/bash

set -euo pipefail

# 💡 安装 jq：Ubuntu -> apt install -y jq，macOS -> brew install jq

# 1. 获取 openspug 最新版本（去除 v 前缀）
version=$(curl --silent "https://api.github.com/repos/openspug/spug/tags" | jq -r '.[0].name')
version=${version#v}

# 2. 获取当前已构建的版本
currentversion=$(cat currentversion)

echo "📌 当前版本: $currentversion，最新版本: $version"

if [[ "$currentversion" == "$version" ]]; then
  echo "✅ 版本一致，无需构建。退出。"
  exit 0
fi

# 3. 登录 Docker Hub
echo "🔐 登录 Docker 仓库..."
echo "$DOCKER_PWD" | docker login -u "$DOCKER_USER" --password-stdin

# 4. 创建并使用 buildx builder
echo "🧱 初始化 buildx 构建器..."
docker buildx create --name spugbuilder --use || docker buildx use spugbuilder
docker buildx inspect --bootstrap

# 5. 构建并推送 version 镜像（多平台）
echo "🚀 构建并推送 spug:$version 镜像..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg SPUG_VERSION="$version" \
  -t "zhiqiangwang/spug:$version" \
  . \
  --push

# 6. 构建并推送 latest 镜像（通过 Dockerfile.latest）
echo "🚀 构建并推送 spug:latest 镜像..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg IMAGE_TAG="$version" \
  -f Dockerfile.latest \
  -t "zhiqiangwang/spug:latest" \
  . \
  --push

# 7. 更新版本记录并提交
echo "📦 更新 currentversion 并提交 Git"
echo "$version" > currentversion
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add currentversion
git commit -m "Auto Update spug to version: $version"
git push origin main

echo "🎉 发布完成！构建版本: $version"
