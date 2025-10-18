# Dockerfile (at repo root)
FROM python:3.11-slim

WORKDIR /app

# (optional) system deps for any wheels that need compiling
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# leverage layer cache: install deps first
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# if you ALSO have service-specific requirements:
# COPY services/app/requirements.txt /app/requirements-app.txt
# RUN pip install --no-cache-dir -r /app/requirements-app.txt

# now copy just the code (avoid copying infra/results/etc with .dockerignore)
COPY services /app/services

EXPOSE 8080
# add a few workers for stability under load
CMD ["uvicorn", "services.app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "4"]
