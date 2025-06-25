#!/bin/bash

# 設定変数
KEY_PATH="~/.ssh/simple-web-app-keypair.pem"
API_SERVER_IP=""  # CDKデプロイ後に設定
REMOTE_USER="ec2-user"
REMOTE_DIR="/home/ec2-user/backend"

# IPアドレスが設定されているかチェック
if [ -z "$API_SERVER_IP" ]; then
    echo "API_SERVER_IP が設定されていません"
    echo "CDKデプロイ後の出力からIPアドレスを設定してください"
    exit 1
fi

echo "バックエンドをAPIサーバーにデプロイ中..."

echo "リモートディレクトリを作成中..."
ssh -i $KEY_PATH $REMOTE_USER@$API_SERVER_IP "mkdir -p $REMOTE_DIR"

echo "ファイルをアップロード中..."

# package.jsonとpackage-lock.jsonをアップロード
scp -i $KEY_PATH backend/package*.json $REMOTE_USER@$API_SERVER_IP:$REMOTE_DIR/

# server.jsをアップロード
scp -i $KEY_PATH backend/server.js $REMOTE_USER@$API_SERVER_IP:$REMOTE_DIR/

# その他のJSファイルがあればアップロード
scp -i $KEY_PATH backend/*.js $REMOTE_USER@$API_SERVER_IP:$REMOTE_DIR/ 2>/dev/null || true

# リモートでセットアップと起動
echo "リモートサーバーでセットアップ中..."
ssh -i $KEY_PATH $REMOTE_USER@$API_SERVER_IP << 'ENDSSH'
cd /home/ec2-user/backend

# 依存関係のインストール
npm install

# 既存のプロセスを停止
echo "既存のプロセスを停止中..."
pm2 stop api-server 2>/dev/null || true
pm2 delete api-server 2>/dev/null || true

# APIサーバーの起動
echo "APIサーバーを起動中..."
pm2 start server.js --name "api-server"
pm2 startup
pm2 save

# 起動確認
sleep 3
if pm2 list | grep -q "api-server.*online"; then
    echo "APIサーバーが正常に起動しました"
    pm2 status
else
    echo "APIサーバーの起動に失敗しました"
    pm2 logs api-server --lines 10
fi
ENDSSH

echo "バックエンドのデプロイが完了しました！"
echo "API URL: http://$API_SERVER_IP:3001"
echo "API テスト: curl http://$API_SERVER_IP:3001/api/data"
