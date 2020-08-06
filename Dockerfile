FROM python:3.7-alpine

WORKDIR /app

# モジュールをインポートするとデフォでインタープリターがソースコードをbytecodeに変換した結果をpycファイルに書き出す
# このファイルは__pycache__に出力される
# このpycファイルを生成しないように設定する設定
ENV PYTHONDONTWRITEBYTECODE 1

# 環境変数に空でない文字列を設定すると、-uオプションを指定したときと同様の効果が得られる
# 特定のマシンで起動されるpythonをすべてバッファリングなしにしたい設定のときにこの設定をする
ENV PYTHONUNBUFFERED 1

ENV DEBUG 0

RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev \
    && apk add postgresql-dev \
    && pip install psycopg2 \
    && apk del build-deps

# requirements.txtを元にインストールする
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# プロジェクトのコピー
COPY . .

RUN python manage.py collectstatic --noinput

# ROOTユーザーじゃない状態で実行？
RUN adduser -D myuser
USER myuser

# herokuにデプロイしたときにこのコマンドが実行されて、gunicornの起動が起動する
CMD gunicorn server.wsgi:application --bind 0.0.0.0:$PORT