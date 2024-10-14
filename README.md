# Rails-Docker

このリポジトリは、RailsアプリケーションをDocker上で構築・運用するためのテンプレートです。ローカル環境から本番環境まで一貫した環境を提供し、簡単にセットアップできます。

## 前提条件

以下がインストールされている必要があります：
- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.jp/compose/toc.html)

---

## セットアップ手順

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/yosukeSugimura/rails-docker.git
   cd rails-docker
   ```

2. **Dockerイメージのビルド**
   ```bash
   docker-compose build
   ```

3. **コンテナの起動**
   ```bash
   docker-compose up -d
   ```

4. **データベースの作成**
   ```bash
   docker-compose run web rake db:create
   docker-compose run web rake db:migrate
   ```

5. **アプリケーションにアクセス**
   ブラウザで `http://localhost:3000` にアクセスしてください。
