#!/bin/bash

AUTOUPDATE=${AUTOUPDATE:-Y}
SENDTYPE=${SENDTYPE:-null}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-null}
TELEGRAM_USERID=${TELEGRAM_USERID:-null}
WXSENDKEY=${WXSENDKEY:-null}
BUTTON_URL=${BUTTON_URL:-null}
LOGININFO=${LOGININFO:-N}
export TELEGRAM_TOKEN TELEGRAM_USERID BUTTON_URL

# 使用 jq 提取 JSON 数组，并将其加载为 Bash 数组
hosts_info=($(echo "${HOSTS_JSON}" | jq -c ".info[]"))
summary=""

for info in "${hosts_info[@]}"; do
  user=$(echo "$info" | jq -r ".username")
  host=$(echo "$info" | jq -r ".host")
  port=$(echo "$info" | jq -r ".port")
  pass=$(echo "$info" | jq -r ".password")

  if [[ -z "$user" || -z "$host" || -z "$port" || -z "$pass" ]]; then
    echo "提取的值不完整：用户=$user，主机=$host，端口=$port，密码=$pass"
    continue
  fi

  if [[ "$AUTOUPDATE" == "Y" ]]; then
    script="/home/$user/serv00-play/keepalive.sh autoupdate ${SENDTYPE} \"${TELEGRAM_TOKEN}\" \"${TELEGRAM_USERID}\" \"${WXSENDKEY}\" \"${BUTTON_URL}\" \"${pass}\""
  else
    script="/home/$user/serv00-play/keepalive.sh noupdate ${SENDTYPE} \"${TELEGRAM_TOKEN}\" \"${TELEGRAM_USERID}\" \"${WXSENDKEY}\" \"${BUTTON_URL}\" \"${pass}\""
  fi

  output=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$host" "bash -s" <<<"$script")

  echo "output: $output"

  if echo "$output" | grep -q "keepalive.sh"; then
    echo "登录成功"
    msg="🟢主机 ${host}, 用户 ${user}， 登录成功!\n"
  else
    echo "登录失败"
    msg="🔴主机 ${host}, 用户 ${user}， 登录失败!\n"
    chmod +x ./tgsend.sh
    export PASS="$pass"
    ./tgsend.sh "Host: $host, user: $user, 登录失败，请检查!"
  fi

  # 发送成功消息到 Telegram
  if [[ "$msg" == *"成功!"* ]]; then
    chmod +x ./tgsend.sh
    ./tgsend.sh "$msg"
  fi

  summary+="$msg"
done

# 如果需要，在最后发送汇总信息
if [[ "$LOGININFO" == "Y" ]]; then
  chmod +x ./tgsend.sh
  ./tgsend.sh "$summary"
fi
