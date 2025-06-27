# Simple EC2 Web Application

![名称未設定ファイル drawio (1)](https://github.com/user-attachments/assets/85e66bb8-d5d4-4190-b8d1-f817323e8f48)

## 前提条件

- AWS CLIが設定済みであること
- AWS CDKがインストール済みであること  
- 必要なAWS権限が設定されていること

## デプロイ手順

### 1. インフラストラクチャのデプロイ

AWS CDKを使用してインフラストラクチャをデプロイします。

```bash
cdk deploy
```

### 2. SSH キーの設定

EC2インスタンスへのSSH接続に必要なキーペアを設定します。

```bash
# キーペアIDの取得
aws ec2 describe-key-pairs --key-names simple-web-app-keypair --include-public-key --query 'KeyPairs[0].KeyPairId' --output text

# 秘密キーの取得とローカル保存
aws ssm get-parameter --name "/ec2/keypair/${keypairID}" --with-decryption --query 'Parameter.Value' --output text > ~/.ssh/simple-web-app-keypair.pem

# キーファイルの権限設定
chmod 400 ~/.ssh/simple-web-app-keypair.pem
```

### 3. IPアドレスの設定

環境変数とIPアドレスの設定を行います。

```bash
# プロジェクトディレクトリに移動
cd simple-ec2-web-application

# セットアップスクリプトに実行権限を付与
chmod +x scripts/setup-env.sh

# 環境設定の実行
./scripts/setup-env.sh
```

### 4. アプリケーションのデプロイ
```bash
# バックエンドのデプロイ
./scripts/deploy-backend.sh

# フロントエンドのデプロイ
./scripts/deploy-frontend.sh

# Proxyサーバーのデプロイ
./scripts/deploy-proxy-server.sh
```

## 注意事項

- SSH接続時は適切なキーペアを使用してください
- デプロイ前に必要なAWS権限が設定されていることを確認してください
