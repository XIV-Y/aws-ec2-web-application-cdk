#!/bin/bash

echo "CDKデプロイ後、以下の手順でIPアドレスを確認してください："
echo ""
echo "1. CDKデプロイ出力を確認："
echo "   - WebServerPublicIP"
echo "   - APIServerPrivateIP"
echo ""
echo "2. IPアドレスを入力してください："

read -p "WebサーバーのパブリックIP: " WEB_IP
read -p "APIサーバーのプライベートIP: " API_IP

echo ""
echo "デプロイスクリプトを更新中..."

# deploy-backend.shを更新
sed -i.bak "s/WEB_SERVER_IP=\"\"/WEB_SERVER_IP=\"$WEB_IP\"/" scripts/deploy-backend.sh
sed -i.bak "s/API_SERVER_IP=\"\"/API_SERVER_IP=\"$API_IP\"/" scripts/deploy-backend.sh

# deploy-nginx.shを更新
sed -i.bak "s/WEB_SERVER_IP=\"\"/WEB_SERVER_IP=\"$WEB_IP\"/" scripts/deploy-nginx.sh
sed -i.bak "s/API_SERVER_IP=\"\"/API_SERVER_IP=\"$API_IP\"/" scripts/deploy-nginx.sh

# 実行権限を付与
chmod +x scripts/deploy-backend.sh
chmod +x scripts/deploy-nginx.sh

echo "設定完了！"
echo ""
echo "次のコマンドでデプロイできます："
echo "   ./scripts/deploy-backend.sh    # APIサーバーをデプロイ"
echo "   ./scripts/deploy-nginx.sh      # Nginx + Reactアプリをデプロイ"
