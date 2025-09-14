# ベースイメージ
FROM ruby:3.2.5-alpine AS base

# 基本的な依存関係をインストール
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    npm \
    tzdata \
    bash \
    git \
    imagemagick \
    && rm -rf /var/cache/apk/*

# 非rootユーザーを作成
RUN adduser -D -s /bin/bash rails
USER rails

# 作業ディレクトリを設定
WORKDIR /app

# === 開発・テスト環境 ===
FROM base AS development

# Gemfileをコピー
COPY --chown=rails:rails Gemfile Gemfile.lock ./

# Bundlerを最新版に更新
RUN gem update bundler

# Gemをインストール（開発・テスト環境用）
RUN bundle config set --local deployment 'false' \
    && bundle config set --local without 'production' \
    && bundle install --jobs 4 --retry 3

# アプリケーションコードをコピー
COPY --chown=rails:rails . .

# ポート3000を公開
EXPOSE 3000

# エントリーポイントを設定
ENTRYPOINT ["./entrypoint.sh"]

# デフォルトコマンド
CMD ["rails", "server", "-b", "0.0.0.0"]

# === プロダクション環境 ===
FROM base AS production

# Gemfileをコピー
COPY --chown=rails:rails Gemfile Gemfile.lock ./

# Bundlerを最新版に更新
RUN gem update bundler

# プロダクション用Gemをインストール
RUN bundle config set --local deployment 'true' \
    && bundle config set --local without 'development test' \
    && bundle install --jobs 4 --retry 3 \
    && bundle clean --force

# アプリケーションコードをコピー
COPY --chown=rails:rails . .

# アセットをプリコンパイル
ENV RAILS_ENV=production
ENV NODE_ENV=production
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# 不要なファイルを削除
RUN rm -rf \
    tmp/cache \
    spec \
    test \
    .git \
    .github \
    node_modules \
    && find . -name "*.log" -delete

# ヘルスチェック用エンドポイント
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# ポート3000を公開
EXPOSE 3000

# エントリーポイントを設定
ENTRYPOINT ["./entrypoint.sh"]

# デフォルトコマンド
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]