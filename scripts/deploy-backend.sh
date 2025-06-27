#!/bin/bash

# 設定変数
KEY_PATH="~/.ssh/simple-web-app-keypair.pem"
WEB_SERVER_IP=""    # CDKデプロイ後に設定（踏み台サーバー）
API_SERVER_IP=""    # CDKデプロイ後に設定（プライベートIP）
REMOTE_USER="ec2-user"
REMOTE_DIR="/home/ec2-user/backend"

# IPアドレスが設定されているかチェック
if [ -z "$WEB_SERVER_IP" ]; then
    echo "WEB_SERVER_IP が設定されていません"
    echo "CDKデプロイ後の出力からWebサーバーのパブリックIPアドレスを設定してください"
    exit 1
fi

if [ -z "$API_SERVER_IP" ]; then
    echo "API_SERVER_IP が設定されていません"
    echo "CDKデプロイ後の出力からAPIサーバーのプライベートIPアドレスを設定してください"
    exit 1
fi

echo "バックエンドをAPIサーバー（Private Subnet）にデプロイ中..."
echo "踏み台サーバー: $WEB_SERVER_IP"
echo "APIサーバー: $API_SERVER_IP"

# SSH接続テスト
echo "SSH接続をテスト中..."
ssh -i $KEY_PATH -o ConnectTimeout=10 -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p $REMOTE_USER@$WEB_SERVER_IP" $REMOTE_USER@$API_SERVER_IP "echo 'SSH接続成功'" || {
    echo "SSH接続に失敗しました。以下を確認してください："
    echo "1. キーペアファイルのパス: $KEY_PATH"
    echo "2. WebサーバーのIP: $WEB_SERVER_IP"
    echo "3. APIサーバーのIP: $API_SERVER_IP"
    exit 1
}

echo "リモートディレクトリを作成中..."
ssh -i $KEY_PATH -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p $REMOTE_USER@$WEB_SERVER_IP" $REMOTE_USER@$API_SERVER_IP "mkdir -p $REMOTE_DIR"

echo "ファイルをアップロード中..."

# package.jsonとpackage-lock.jsonをアップロード
scp -i $KEY_PATH -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p $REMOTE_USER@$WEB_SERVER_IP" backend/package*.json $REMOTE_USER@$API_SERVER_IP:$REMOTE_DIR/

# server.jsをアップロード
scp -i $KEY_PATH -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p $REMOTE_USER@$WEB_SERVER_IP" backend/server.js $REMOTE_USER@$API_SERVER_IP:$REMOTE_DIR/

# その他のJSファイルがあればアップロード
scp -i $KEY_PATH -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p $REMOTE_USER@$WEB_SERVER_IP" backend/*.js $REMOTE_USER@$API_SERVER_IP:$REMOTE_DIR/ 2>/dev/null || true

# リモートでセットアップと起動
echo "リモートサーバーでセットアップ中..."
ssh -i $KEY_PATH -o ProxyCommand="ssh -i $KEY_PATH -W %h:%p $REMOTE_USER@$WEB_SERVER_IP" $REMOTE_USER@$API_SERVER_IP << 'ENDSSH'
cd /home/ec2-user/backend

# 依存関係のインストール
echo "依存関係をインストール中..."
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
    echo ""
    echo "ローカルテスト:"
    curl -s http://localhost:3001/api/data || echo "APIテストに失敗しました"
else
    echo "APIサーバーの起動に失敗しました"
    pm2 logs api-server --lines 10
fi
ENDSSH

echo "バックエンドのデプロイが完了しました！"
