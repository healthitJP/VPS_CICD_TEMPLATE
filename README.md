# 概要と使い方

---

以下に、修正版スクリプトを使用した場合の最終的なファイル構成を示します。この構成は、VPS上のディレクトリとリポジトリ内の構成、そしてスクリプトの配置場所を含みます。

---

## VPSの最終的なファイル構成

### 1. `/var/www/` ディレクトリ内（アプリケーションごとの構成）
```
/var/www/
├── app_name1/                  # アプリケーション1
│   ├── venv/                   # 仮想環境
│   ├── main.py                 # FastAPIアプリのエントリーポイント
│   ├── requirements.txt        # 依存パッケージ
│   ├── .git/                   # Gitリポジトリ
│   ├── その他のアプリコードファイル
├── app_name2/                  # アプリケーション2
│   ├── venv/                   # 仮想環境
│   ├── main.py                 # FastAPIアプリのエントリーポイント
│   ├── requirements.txt        # 依存パッケージ
│   ├── .git/                   # Gitリポジトリ
│   ├── その他のアプリコードファイル
```

---

### 2. ホームディレクトリ内（スクリプトとSSH鍵）
```
~/
├── init_vps.sh                 # 初期設定スクリプト
├── deploy_app.sh               # アプリケーションデプロイスクリプト
├── vps_config.env              # ドメイン名などの環境変数設定
├── .ssh/                       # SSH鍵
│   ├── app_name1_deploy_key      # アプリケーション1用SSH秘密鍵
│   ├── app_name1_deploy_key.pub  # アプリケーション1用SSH公開鍵
│   ├── app_name2_deploy_key      # アプリケーション2用SSH秘密鍵
│   ├── app_name2_deploy_key.pub  # アプリケーション2用SSH公開鍵
```

- **`vps_config.env` の内容例**
  ```
  DOMAIN_NAME=example.com
  ```

---

### 3. `/etc/nginx/` ディレクトリ内（Nginxの設定）
```
/etc/nginx/
├── sites-available/
│   ├── app_name1               # Nginx設定ファイル（アプリケーション1用）
│   ├── app_name2               # Nginx設定ファイル（アプリケーション2用）
├── sites-enabled/
│   ├── app_name1 -> /etc/nginx/sites-available/app_name1
│   ├── app_name2 -> /etc/nginx/sites-available/app_name2
```

---

### 4. `/etc/systemd/system/` ディレクトリ内（Systemdサービス設定）
```
/etc/systemd/system/
├── app_name1.service           # アプリケーション1のSystemdサービスファイル
├── app_name2.service           # アプリケーション2のSystemdサービスファイル
```

---

## GitHubリポジトリの構成例

```
root/
├── main.py                     # FastAPIアプリのエントリーポイント
├── requirements.txt            # 依存パッケージ一覧
├── .github/
│   ├── workflows/
│   │   ├── deploy.yml          # GitHub Actionsワークフローファイル
├── その他のアプリコードファイル
```

---

## ファイルの役割とポイント

### VPS内の主要ファイル
- **`/var/www/<app_name>`**
  - アプリケーションごとのコードと仮想環境を管理するディレクトリ。
- **`/etc/nginx/sites-available/<app_name>`**
  - サブドメインごとのNginx設定ファイル。
  - サブドメインごとに動的な設定を適用します。
- **`/etc/systemd/system/<app_name>.service`**
  - アプリケーションのSystemdサービス定義ファイル。
  - アプリケーションの自動起動と再起動を管理します。
- **`~/.ssh/<app_name>_deploy_key`**
  - GitHub Actions用のSSH鍵。アプリごとに生成してGitHubに登録します。

### GitHubリポジトリの主要ファイル
- **`main.py`**
  - FastAPIアプリケーションのエントリーポイント。
- **`requirements.txt`**
  - アプリケーションで使用するPythonパッケージの一覧。
- **`.github/workflows/deploy.yml`**
  - GitHub Actionsのデプロイメント設定。

---

## 運用フロー

0. **Python3.12にする**
   - Python3.12がインストールされていない場合は以下にそってインストール


Pythonをバージョン3.12にアップグレードするには、使用しているOSによって手順が異なります。以下に、主要なOS（Linux, macOS, Windows）でのアップグレード手順を説明します。

### Ubuntu/LinuxでPython 3.12にアップグレードする
1. **リポジトリを更新**:
   まず、システムパッケージを最新にするために以下のコマンドを実行します。

   ```sh
   sudo apt update
   sudo apt upgrade
   ```

2. **必要な依存パッケージをインストール**:
   Pythonのビルドに必要な依存パッケージをインストールします。

   ```sh
   sudo apt install software-properties-common -y
   sudo add-apt-repository ppa:deadsnakes/ppa
   sudo apt update
   ```

3. **Python 3.12のインストール**:
   Python 3.12をインストールします。

   ```sh
   sudo apt install python3.12
   ```

4. **Pythonのデフォルトバージョンを変更（オプション）**:
   デフォルトのPythonバージョンを3.12に変更したい場合、`update-alternatives`を使って設定します。

   ```sh
   sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
   ```

5. **バージョンを確認**:
   Python 3.12が正しくインストールされているか確認します。

   ```sh
   python3 --version
   ```

### 注意点
- **互換性の確認**:
  Pythonの新しいバージョンを使用する際は、既存のプロジェクトやパッケージが3.12と互換性があるかを確認する必要があります。一部のパッケージは、新しいPythonバージョンにまだ対応していない場合があります。
  
- **仮想環境の利用**:
  新しいPythonバージョンで環境を切り替えたい場合は、`virtualenv` や `venv` などの仮想環境を利用するのがおすすめです。例えば次のように仮想環境を作成できます。

  ```sh
  python3.12 -m venv myenv
  source myenv/bin/activate  # Linux/macOS
  myenv\Scripts\activate     # Windows
  ```

Python 3.12を導入することで、新機能やパフォーマンスの向上を享受することができますが、互換性の面でも注意が必要です。




1. **VPS初期設定**
   - `init_vps.sh`を実行して、基本環境をセットアップ。

2. **新しいアプリケーションのデプロイ**
   - `deploy_app.sh`を使用して、新しいアプリをデプロイ。
   - 例:
     ```bash
     ./deploy_app.sh myapp git@github.com:your-username/my-repo.git myapp 8001
     ```

3. **GitHub Actions用SSH鍵の登録**
   - `~/.ssh/myapp_deploy_key.pub`をGitHubリポジトリに登録。

4. **コード変更時の自動デプロイ**
   - GitHubリポジトリにコードをPushすると、`deploy.yml`がトリガーされ、自動的にVPSにデプロイされます。

---

## この構成のメリット

- **セキュリティ**
  - SSH鍵をアプリケーションごとに分離し、セキュリティリスクを最小化。
  - Let's EncryptでHTTPS化し、安全な通信を確保。

- **拡張性**
  - 複数のアプリケーションを異なるサブドメインとポート番号で簡単に管理。

- **自動化**
  - GitHub Actionsを使用して、デプロイを完全自動化。

---

## 構成全体のポイント

### 1. **ディレクトリ分離**
- アプリケーションごとに `/var/www/` 配下に専用ディレクトリを作成。
- NginxとSystemd設定ファイルもアプリごとに分離。

### 2. **動的なドメイン管理**
- `init_vps.sh` によって設定したドメイン名（例：`example.com`）がすべてのアプリで共有。

### 3. **自動化されたHTTPS管理**
- Let's Encryptの証明書は `certbot` を使用して自動更新。

### 4. **スクリプトでの効率化**
- `deploy_app.sh` を使用して新しいアプリケーションのデプロイを簡略化。

---

## メンテナンス時の主な操作

### 新しいアプリケーションの追加
1. GitHubリポジトリを作成。
2. `deploy_app.sh` を実行してデプロイ。
   ```bash
   ./deploy_app.sh myapp git@github.com:your-username/my-repo.git myapp 8001
   ```

### Nginxの設定確認
- 設定が正しいかテスト：
  ```bash
  sudo nginx -t
  ```
- 再起動：
  ```bash
  sudo systemctl restart nginx
  ```

### サービスの状態確認
- サービスの状態確認：
  ```bash
  sudo systemctl status app_name1
  ```
- サービスの再起動：
  ```bash
  sudo systemctl restart app_name1
  ```

### 証明書の更新テスト
- 自動更新の確認：
  ```bash
  sudo certbot renew --dry-run
  ```

---

## 初期スクリプトの準備と実行

VPSの環境をセットアップするスクリプトを使用します。

### 実行手順
1. スクリプトをサーバーにアップロード。
2. 実行権限を付与：
   ```bash
   chmod +x init_vps.sh
   ```
3. スクリプトを実行：
   ```bash
   ./init_vps.sh
   ```

4. スクリプト実行後、表示される公開鍵をコピーし、GitHubのSSHキー設定に登録します。


