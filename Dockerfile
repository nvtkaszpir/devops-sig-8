FROM python:3.7.3-alpine3.9

# install curl to use it with health check under docker itself
RUN apk update --no-cache && apk add curl=7.64.0-r2 && rm -rf /var/cache/apk/*
HEALTHCHECK \
	--interval=10s \
	--timeout=1s \
  	CMD curl -f http://localhost:8000/const || exit 1

COPY requirements.txt app.py /
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000
CMD gunicorn -b 0.0.0.0:8000 --log-level debug app:api
