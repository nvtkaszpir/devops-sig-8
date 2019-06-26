FROM python:3
COPY requirements.txt app.py /
RUN pip install -r requirements.txt
CMD gunicorn -b 0.0.0.0 --log-level debug app:api
