# Simple EC2 Web Application

![名称未設定ファイル drawio (2)](https://github.com/user-attachments/assets/5be88cab-c05f-417d-8dda-12c74df481a9)

## 前提条件

- AWS CLI が設定済みであること
- AWS CDK がインストール済みであること
- 必要な AWS 権限が設定されていること

## デプロイ手順

### 1. インフラストラクチャのデプロイ

AWS CDK を使用してインフラストラクチャをデプロイします。

```bash
cdk deploy
```

### 2. SSH キーの設定

EC2 インスタンスへの SSH 接続に必要なキーペアを設定します。

```bash
# キーペアIDの取得
aws ec2 describe-key-pairs --key-names simple-web-app-keypair --include-public-key --query 'KeyPairs[0].KeyPairId' --output text

# 秘密キーの取得とローカル保存
aws ssm get-parameter --name "/ec2/keypair/${keypairID}" --with-decryption --query 'Parameter.Value' --output text > ~/.ssh/simple-web-app-keypair.pem

# キーファイルの権限設定
chmod 400 ~/.ssh/simple-web-app-keypair.pem
```

### 3. IP アドレスの設定

環境変数と IP アドレスの設定を行います。

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

# Nginx + Reactアプリのデプロイ
./scripts/deploy-nginx.sh
```
