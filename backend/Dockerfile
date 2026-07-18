FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
# JWT_SECRET must be set in the host's environment for tokens to survive restarts.
# BODYX_DB can point at a mounted volume for persistence (e.g. /data/bodyx.db).
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
