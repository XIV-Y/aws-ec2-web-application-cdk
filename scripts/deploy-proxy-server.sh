#!/bin/bash

KEY_PATH="~/.ssh/simple-web-app-keypair.pem"
WEB_SERVER_IP=""
API_SERVER_IP=""
REMOTE_USER="ec2-user"

echo "プロキシサーバーをデプロイ中..."

cd frontend && npm run build && cd ..

ssh -i $KEY_PATH $REMOTE_USER@$WEB_SERVER_IP "mkdir -p /home/ec2-user/proxy-server/public"

scp -i $KEY_PATH proxy-server/package.json $REMOTE_USER@$WEB_SERVER_IP:/home/ec2-user/proxy-server/
scp -i $KEY_PATH proxy-server/server.js $REMOTE_USER@$WEB_SERVER_IP:/home/ec2-user/proxy-server/
scp -i $KEY_PATH -r frontend/build/* $REMOTE_USER@$WEB_SERVER_IP:/home/ec2-user/proxy-server/public/

ssh -i $KEY_PATH $REMOTE_USER@$WEB_SERVER_IP << ENDSSH
cd /home/ec2-user/proxy-server
npm install
pkill -f "node server.js" 2>/dev/null || true
API_SERVER_IP="$API_SERVER_IP" PORT=8080 nohup npm start > /dev/null 2>&1 &

sleep 3
if pgrep -f "node server.js" > /dev/null; then
    echo "プロキシサーバーが起動しました"
else
    echo "プロキシサーバーの起動に失敗しました"
fi
ENDSSH

echo "デプロイ完了: http://$WEB_SERVER_IP:8080"
