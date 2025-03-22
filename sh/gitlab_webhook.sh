#!/bin/bash
SPUG_TOKEN="${SPUG_TOKEN:-"spug_token"}"
SPUG_WEBHOOK="${SPUG_WEBHOOK:-"https://spug.example.com/api/apis/deploy/1/branch/?name=develop"}"
REF_BRANCH="${REF_BRANCH:-"refs/heads/develop"}"
GITLAB_TOKEN="${GITLAB_TOKEN:-"glpat-*********************"}"
GITLAB_URL="${GITLAB_URL:-"https://gitlab.example.com/api/v4/projects/username%2Frepository/repository/branches/develop"}"

# 确保 GITLAB_TOKEN 已设置
if [[ -z "$GITLAB_TOKEN" ]]; then
    echo "❌ GITLAB_TOKEN 为空，请检查环境变量"
    exit 1
fi

# 获取 commit ID
commit_id=$(curl --silent --fail -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_URL}" | jq -r '.commit.id')

# 如果 commit_id 获取失败，则退出
if [[ -z "$commit_id" || "$commit_id" == "null" ]]; then
    echo "❌ 获取 commit ID 失败，请检查 GITLAB_TOKEN 是否正确或 GitLab API 响应"
    exit 1
fi

echo "✅获取 commit ID: $commit_id"

# 发送请求到 Spug Webhook
echo "🙏Spug 请求地址: $SPUG_WEBHOOK"
curl -w "URL: %{url_effective}
下载大小: %{size_download} 字节
上传大小: %{size_upload} 字节
下载速度: %{speed_download} B/s
上传速度: %{speed_upload} B/s
总时间: %{time_total} 秒
DNS 解析时间: %{time_namelookup} 秒
连接时间: %{time_connect} 秒
服务器 IP: %{remote_ip}
服务器端口: %{remote_port}
HTTP 状态码: %{http_code}
" \
    -o /dev/stdout \
    -X POST "${SPUG_WEBHOOK}" \
    -H "X-Gitlab-Token: ${SPUG_TOKEN}" \
    -H 'Content-Type: application/json' \
    --data "{\"event_name\": \"push\",\"after\": \"${commit_id}\", \"ref\": \"${REF_BRANCH}\",\"commits\": [{\"id\": \"${commit_id}\"}]}"

echo "🆗发送请求完成"
