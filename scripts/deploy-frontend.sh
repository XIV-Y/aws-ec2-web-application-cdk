#!/bin/bash

KEY_PATH="~/.ssh/simple-web-app-keypair.pem"
WEB_SERVER_IP=""  # CDKデプロイ後に設定
API_SERVER_IP=""  # CDKデプロイ後に設定（プライベートIP）
REMOTE_USER="ec2-user"
REMOTE_DIR="/home/ec2-user/frontend"

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

echo "フロントエンドをWebサーバーにデプロイ中..."

# 環境変数ファイルの作成
echo "環境変数ファイルを作成中..."
cat > frontend/.env << EOF
REACT_APP_API_URL=http://${API_SERVER_IP}:3001
EOF

echo "リモートディレクトリを作成中..."
ssh -i $KEY_PATH $REMOTE_USER@$WEB_SERVER_IP "mkdir -p $REMOTE_DIR"

echo "ファイルをアップロード中..."

# package.jsonとpackage-lock.jsonをアップロード
scp -i $KEY_PATH frontend/package*.json $REMOTE_USER@$WEB_SERVER_IP:$REMOTE_DIR/

# publicディレクトリをアップロード
scp -i $KEY_PATH -r frontend/public $REMOTE_USER@$WEB_SERVER_IP:$REMOTE_DIR/

# srcディレクトリをアップロード
scp -i $KEY_PATH -r frontend/src $REMOTE_USER@$WEB_SERVER_IP:$REMOTE_DIR/

# 環境変数ファイルをアップロード
scp -i $KEY_PATH frontend/.env $REMOTE_USER@$WEB_SERVER_IP:$REMOTE_DIR/

# その他の設定ファイルをアップロード
scp -i $KEY_PATH frontend/tsconfig.json $REMOTE_USER@$WEB_SERVER_IP:$REMOTE_DIR/ 2>/dev/null || true

# リモートでセットアップと起動
echo "リモートサーバーでセットアップ中..."
ssh -i $KEY_PATH $REMOTE_USER@$WEB_SERVER_IP << ENDSSH
cd /home/ec2-user/frontend

# 依存関係のインストール
echo "依存関係をインストール中..."
npm install

# 既存のプロセスを停止
echo "既存のプロセスを停止中..."
pkill -f "react-scripts start" 2>/dev/null || true

# Reactアプリの起動
echo "Reactアプリを起動中..."
export HOST=0.0.0.0
nohup npm start > react.log 2>&1 &

# 起動確認
sleep 5
if pgrep -f "react-scripts start" > /dev/null; then
    echo "Reactアプリが正常に起動しました"
    
    # API接続テスト
    echo "API接続をテスト中..."
    curl -s http://$API_SERVER_IP:3001/api/data && echo " - API接続成功" || echo " - API接続失敗"
else
    echo "Reactアプリの起動に失敗しました"
    tail react.log
fi
ENDSSH

echo "フロントエンドのデプロイが完了しました！"
echo ""
echo "アクセス情報:"
echo "  React アプリ: http://$WEB_SERVER_IP:3000"
