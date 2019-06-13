# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
# rails-docker

## 初期設定

* 前提として、dockerとdocker-composeが入っていること
  * docker : https://www.docker.com/
  * docker-compose : http://docs.docker.jp/compose/toc.html

* git clone した環境で以下のコマンドを実行しbuildする

```
$docker-compose build
```

* docker-composeにて、imageを実行する

```
$docker-compose up
```

* 実行後に別のコンソールにて以下のコマンドでdbをCreateする

```
docker-compose run web rake db:create
```

`localhost:3000`によりアクセス
