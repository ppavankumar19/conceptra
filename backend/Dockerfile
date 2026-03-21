FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .
RUN useradd -r -s /bin/false conceptra && chown -R conceptra:conceptra /app
USER conceptra
EXPOSE 8000
CMD ["sh", "-c", "gunicorn app.main:app -w ${WEB_CONCURRENCY:-1} -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:${PORT:-8000} --timeout ${GUNICORN_TIMEOUT:-120}"]
