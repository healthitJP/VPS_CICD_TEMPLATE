#!/bin/bash

# ドメイン名を設定
read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    echo "Domain name is required. Exiting."
    exit 1
fi

# ドメイン名を保存する
echo "DOMAIN_NAME=$DOMAIN_NAME" > ~/vps_config.env

echo "=== VPS 初期設定開始 ==="

# 必要なソフトウェアのインストール
echo "=== パッケージを更新し、必要なツールをインストールします ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv nginx git certbot python3-certbot-nginx

# SSHキーの生成
echo "=== SSHキーを生成します ==="
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519 -N ""
    echo "=== 公開鍵を以下に表示します。このキーをGitHubに登録してください ==="
    cat ~/.ssh/id_ed25519.pub
else
    echo "=== SSHキーは既に存在します ==="
    cat ~/.ssh/id_ed25519.pub
fi

# サービス用ディレクトリ作成
echo "=== アプリケーション用ディレクトリを作成します ==="
sudo mkdir -p /var/www
sudo chown $USER:$USER /var/www

echo "=== 初期設定完了！次にGitHubの設定を確認し、アプリケーションをデプロイしてください ==="
