.PHONY: help dev-up dev-down dev-logs dev-restart db-setup db-migrate db-rollback db-seed test test-coverage clean shell lint security-scan

# デフォルトターゲット
help: ## このヘルプメッセージを表示
	@echo "利用可能なコマンド:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# 開発環境管理
dev-up: ## 開発環境を起動
	docker-compose up --build -d
	@echo "🚀 開発環境が起動しました: http://localhost:3000"

dev-down: ## 開発環境を停止
	docker-compose down
	@echo "🛑 開発環境を停止しました"

dev-logs: ## 開発環境のログを表示
	docker-compose logs -f

dev-restart: dev-down dev-up ## 開発環境を再起動

# データベース管理
db-setup: ## データベースを初期化（作成・マイグレーション・シード）
	docker-compose exec web rails db:create
	docker-compose exec web rails db:migrate
	docker-compose exec web rails db:seed
	@echo "📊 データベースの初期化が完了しました"

db-migrate: ## マイグレーションを実行
	docker-compose exec web rails db:migrate
	@echo "📈 マイグレーションが完了しました"

db-rollback: ## マイグレーションを1つ戻す
	docker-compose exec web rails db:rollback
	@echo "📉 マイグレーションを戻しました"

db-seed: ## シードデータを投入
	docker-compose exec web rails db:seed
	@echo "🌱 シードデータを投入しました"

db-console: ## データベースコンソールを起動
	docker-compose exec web rails db:console

# テスト
test: ## テストを実行
	docker-compose exec web bundle exec rspec
	@echo "✅ テストが完了しました"

test-coverage: ## カバレッジ付きテストを実行
	docker-compose exec web bundle exec rspec --require spec_helper
	@echo "📊 テストカバレッジレポートを確認してください: coverage/index.html"

test-watch: ## テストを監視モードで実行
	docker-compose exec web bundle exec guard

# 開発ツール
shell: ## Railsコンテナのシェルに接続
	docker-compose exec web bash

rails-console: ## Rails consoleを起動
	docker-compose exec web rails console

rails-routes: ## ルーティング情報を表示
	docker-compose exec web rails routes

# コード品質
lint: ## コードリンターを実行
	docker-compose exec web bundle exec rubocop
	@echo "🔍 リンターチェックが完了しました"

lint-fix: ## リンターで自動修正可能な問題を修正
	docker-compose exec web bundle exec rubocop -a
	@echo "🔧 自動修正が完了しました"

security-scan: ## セキュリティスキャンを実行
	docker-compose exec web bundle exec brakeman
	@echo "🛡️ セキュリティスキャンが完了しました"

# プロダクション環境
prod-up: ## プロダクション環境を起動
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
	@echo "🏭 プロダクション環境が起動しました"

prod-down: ## プロダクション環境を停止
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
	@echo "🛑 プロダクション環境を停止しました"

# メンテナンス
clean: ## 不要なDockerイメージとボリュームを削除
	docker-compose down -v
	docker system prune -f
	docker volume prune -f
	@echo "🧹 クリーンアップが完了しました"

logs: ## すべてのサービスのログを表示
	docker-compose logs -f

ps: ## 実行中のコンテナを表示
	docker-compose ps

# 依存関係管理
bundle-install: ## Gemを再インストール
	docker-compose exec web bundle install
	@echo "💎 Gemのインストールが完了しました"

bundle-update: ## Gemをアップデート
	docker-compose exec web bundle update
	@echo "⬆️ Gemのアップデートが完了しました"

# 初回セットアップ
setup: dev-up db-setup ## 初回セットアップ（開発環境起動＋DB初期化）
	@echo "🎉 セットアップが完了しました！http://localhost:3000 でアクセスできます"

# Docker管理
docker-rebuild: ## Dockerイメージを完全に再ビルド
	docker-compose build --no-cache
	@echo "🔄 Dockerイメージの再ビルドが完了しました"

# バックアップ
backup-db: ## データベースをバックアップ
	docker-compose exec db pg_dump -U postgres postgres > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "💾 データベースバックアップが作成されました"