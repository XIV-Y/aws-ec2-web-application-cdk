#!/bin/bash

KEY_PATH="~/.ssh/simple-web-app-keypair.pem"
WEB_SERVER_IP=""
API_SERVER_IP=""
REMOTE_USER="ec2-user"

# IPアドレスが設定されているかチェック
if [ -z "$WEB_SERVER_IP" ]; then
    echo "WEB_SERVER_IP が設定されていません"
    exit 1
fi

if [ -z "$API_SERVER_IP" ]; then
    echo "API_SERVER_IP が設定されていません"
    exit 1
fi

echo "Nginxプロキシサーバーをデプロイ中..."

# フロントエンドをビルド
echo "Reactアプリをビルド中..."
cd frontend
npm run build
cd ..

# Nginx設定ファイルを作成（APIサーバーのIPを置換）
echo "Nginx設定ファイルを作成中..."
mkdir -p tmp
sed "s/API_SERVER_IP/$API_SERVER_IP/g" nginx/default.conf > tmp/default.conf

echo "SSH接続をテスト中..."
ssh -i $KEY_PATH -o ConnectTimeout=10 $REMOTE_USER@$WEB_SERVER_IP "echo 'SSH接続成功'" || {
    echo "SSH接続に失敗しました"
    exit 1
}

echo "ファイルをアップロード中..."
scp -i $KEY_PATH tmp/default.conf $REMOTE_USER@$WEB_SERVER_IP:/tmp/
scp -i $KEY_PATH -r frontend/build $REMOTE_USER@$WEB_SERVER_IP:/tmp/

echo "Nginxを設定・起動中..."
ssh -i $KEY_PATH $REMOTE_USER@$WEB_SERVER_IP << 'ENDSSH'
# Reactアプリを配置
sudo rm -rf /var/www/html/*
sudo mv /tmp/build/* /var/www/html/
sudo chown -R nginx:nginx /var/www/html

# Nginx設定を配置
sudo mv /tmp/default.conf /etc/nginx/conf.d/

# Nginx設定をテスト・再起動
sudo nginx -t && sudo systemctl restart nginx

# 起動確認
if systemctl is-active --quiet nginx; then
    echo "Nginxが正常に起動しました"
    curl -s -I http://localhost | head -1
else
    echo "Nginxの起動に失敗しました"
    sudo systemctl status nginx --no-pager
fi
ENDSSH

# 一時ファイルを削除
rm -rf tmp

echo "デプロイ完了: http://$WEB_SERVER_IP"
