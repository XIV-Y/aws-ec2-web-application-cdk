#!/bin/bash

echo "デプロイ環境の設定"
echo ""

echo "CDKデプロイ後、以下の手順でIPアドレスを確認してください："
echo ""
echo "1. CDKデプロイ出力を確認："
echo "   cdk deploy の出力から以下の値をコピー"
echo "   - WebServerPublicIP"
echo "   - APIServerPublicIP"
echo ""
echo "2. IPアドレスを入力してください："

read -p "WebサーバーのIP: " WEB_IP
read -p "APIサーバーのIP: " API_IP

echo ""
echo "デプロイスクリプトを更新中..."

# deploy-frontend.shを更新
sed -i.bak "s/WEB_SERVER_IP=\"\"/WEB_SERVER_IP=\"$WEB_IP\"/" scripts/deploy-frontend.sh
sed -i.bak "s/API_SERVER_IP=\"\"/API_SERVER_IP=\"$API_IP\"/" scripts/deploy-frontend.sh

# deploy-backend.shを更新
sed -i.bak "s/API_SERVER_IP=\"\"/API_SERVER_IP=\"$API_IP\"/" scripts/deploy-backend.sh

# 実行権限を付与
chmod +x scripts/deploy-frontend.sh
chmod +x scripts/deploy-backend.sh

echo "設定完了！"
echo ""
echo "次のコマンドでデプロイできます："
echo "   ./scripts/deploy-backend.sh   # APIサーバーをデプロイ"
echo "   ./scripts/deploy-frontend.sh  # Webサーバーをデプロイ"
