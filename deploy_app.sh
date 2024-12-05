#!/bin/bash

# 必須の引数を確認
if [ $# -ne 4 ]; then
    echo "Usage: $0 <app_name> <repository_url> <subdomain> <port>"
    exit 1
fi

APP_NAME=$1                # アプリケーション名
REPO_URL=$2                # GitHubリポジトリURL
SUBDOMAIN=$3               # 使用するサブドメイン
PORT=$4                    # 使用するポート番号
APP_DIR="/var/www/$APP_NAME"
SSH_KEY_PATH="$HOME/.ssh/${APP_NAME}_deploy_key"

# ドメイン名を読み込む
if [ -f ~/vps_config.env ]; then
    source ~/vps_config.env
else
    echo "Domain name configuration not found. Run init_vps.sh first."
    exit 1
fi

echo "=== 新しいアプリケーションをデプロイします: $APP_NAME ==="

# リポジトリをClone
if [ ! -d "$APP_DIR" ]; then
    echo "=== リポジトリをクローンします ==="
    git clone $REPO_URL $APP_DIR
else
    echo "=== ディレクトリが既に存在します: $APP_DIR ==="
    echo "リポジトリを更新します..."
    cd $APP_DIR && git pull origin main
fi

# 仮想環境のセットアップ
echo "=== 仮想環境をセットアップします ==="
python3 -m venv $APP_DIR/venv
source $APP_DIR/venv/bin/activate
pip install -r $APP_DIR/requirements.txt
deactivate

# Nginx設定
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
if [ ! -f "$NGINX_CONF" ]; then
    echo "=== Nginxの設定を作成します ==="
    sudo tee $NGINX_CONF > /dev/null <<EOL
server {
    server_name $SUBDOMAIN.$DOMAIN_NAME;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL
    sudo ln -s $NGINX_CONF /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl restart nginx
else
    echo "=== Nginx設定は既に存在します ==="
fi

# Let's EncryptでHTTPSを有効化
echo "=== Let's EncryptでHTTPSを有効化します ==="
sudo certbot --nginx -d $SUBDOMAIN.$DOMAIN_NAME

# 自動更新の設定
echo "=== Let's Encryptの自動更新を確認します ==="
if ! sudo systemctl is-enabled certbot.timer > /dev/null 2>&1; then
    echo "=== Certbotタイマーを有効化します ==="
    sudo systemctl enable certbot.timer
    sudo systemctl start certbot.timer
fi

# GitHub Actions用のSSH鍵を作成
echo "=== GitHub Actions用のSSH鍵を作成します ==="
if [ ! -f "$SSH_KEY_PATH" ]; then
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "github-actions@$DOMAIN_NAME" -f "$SSH_KEY_PATH" -N ""
    echo "=== 公開鍵を以下に表示します。この鍵をGitHubに登録してください ==="
    cat "${SSH_KEY_PATH}.pub"

    echo "=== 鍵の権限を設定します ==="
    chmod 600 "$SSH_KEY_PATH"
else
    echo "=== SSH鍵は既に存在します: $SSH_KEY_PATH ==="
fi

# Systemdサービス設定
SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "=== Systemdサービスを設定します ==="
    sudo tee $SERVICE_FILE > /dev/null <<EOL
[Unit]
Description=$APP_NAME FastAPI Application
After=network.target

[Service]
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port $PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl daemon-reload
    sudo systemctl start $APP_NAME
    sudo systemctl enable $APP_NAME
else
    echo "=== Systemdサービスは既に存在します ==="
fi

echo "=== 新しいアプリケーションのデプロイが完了しました！ ==="
echo "=== GitHub Actions用のSSH公開鍵: ${SSH_KEY_PATH}.pub ==="
