FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
RUN useradd app
USER app
# --timeout-keep-alive: how long an idle connection stays open (default 5s).
CMD uvicorn app:app --host 0.0.0.0 --port 3000 --timeout-keep-alive $KEEPALIVE_TIMEOUT_S
