#!/bin/bash
set -e

# https://stackoverflow.com/questions/27771781/how-can-i-access-docker-set-environment-variables-from-a-cron-job
echo "[step 1/4]导入环境变量"
printenv | grep -v "no_proxy" > /etc/environment
echo "=>完成"

echo "[step 2/4]配置cron定时任务"
cat << EOF > /etc/cron.d/cron1
16 */6 * * * bash /src/cron1.sh
EOF

# 配置 cron 定时任务所执行的脚本
function cronsrc() {

cat << EOF > /src/cron1.sh
COMMAND1="copy "
COMMAND2="copyto"
REMOTE_PATH="CHANGE_RC_REMOTE"

rclone \${COMMAND1} -v "/app/Deploy" "\${REMOTE_PATH}/Deploy" --transfers=1
rclone \${COMMAND1} -v "/app/appdata" "\${REMOTE_PATH}/appdata" --transfers=1
rclone \${COMMAND2} -v "/root/.config/rclone/rclone.conf" "\${REMOTE_PATH}/rc" --transfers=1
EOF
}

# 配置 cron 定时任务所执行的脚本
curl -L -H "Cache-Control: no-cache" -o /src/cron1.sh CHANGE_CRON_URL
chmod +x /src/cron1.sh

# 配置 rclone config
mkdir -p /root/.config/rclone
curl -L -H "Cache-Control: no-cache" -o /root/.config/rclone/rclone.conf CHANGE_RC_CONF_URL

# 初始化 E5 程序配置目录
cat << EOF > /src/init.sh
COMMAND1="copy "
COMMAND2="copyto"
REMOTE_PATH="CHANGE_RC_REMOTE"

rclone \${COMMAND1} -v "\${REMOTE_PATH}/Deploy" "/app/Deploy" --transfers=1
rclone \${COMMAND1} -v "\${REMOTE_PATH}/appdata" "/app/appdata" --transfers=1

EOF
chmod +x /src/init.sh
bash /src/init.sh

echo "=>完成"

echo "[step 3/4]启动定时任务，开启每 6 小时定时运行"
chmod 0644 /etc/cron.d/cron1
crontab /etc/cron.d/cron1
touch /var/log/cron.log
cron
echo "=>完成"

echo "[step 4/4]初始启动容器，运行 E5 主程序"
# 运行 E5 主程序
dotnet Microsoft365_E5_Renew_X.dll
