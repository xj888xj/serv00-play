#!/bin/bash

# 假设 HOSTS_JSON 是一个包含多个账户信息的 JSON 字符串
# 示例格式:
# HOSTS_JSON='[{"username":"user1","host":"host1","port":22,"password":"pass1"},{"username":"user2","host":"host2","port":22,"password":"pass2"}]'

# 解析 JSON 数据
hosts_info=$(echo "$HOSTS_JSON" | jq -c '.[]')

# 主循环
summary=""
for info in $hosts_info; do
  user=$(echo "$info" | jq -r ".username")
  host=$(echo "$info" | jq -r ".host")
  port=$(echo "$info" | jq -r ".port")
  pass=$(echo "$info" | jq -r ".password")

  echo "正在尝试登录：用户 $user，主机 $host，端口 $port"

  # 假设 execute_keepalive 是执行保活的函数
  if execute_keepalive "$user" "$host" "$port" "$pass"; then
    msg="🟢主机 ${host}, 用户 ${user}， 登录成功!\n"
  else
    msg="🔴主机 ${host}, 用户 ${user}， 登录失败!\n"
  fi
  summary+="$msg"
done

# 输出总结信息
echo -e "$summary"

# 示例的 execute_keepalive 函数（根据需要替换）
execute_keepalive() {
  local user="$1"
  local host="$2"
  local port="$3"
  local pass="$4"

  # 这里可以添加实际的 SSH 登录逻辑
  # 例如使用 sshpass 进行密码登录
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$host" "echo '登录成功'"
}

