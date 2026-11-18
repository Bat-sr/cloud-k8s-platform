# Small official Python image
FROM python:3.12-slim

# Don't write .pyc files, print logs immediately
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

# Install dependencies first (Docker caches this layer when requirements don't change)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the app code
COPY app.py .

# Run as a normal user, not root (security best practice)
RUN useradd --create-home appuser
USER appuser

EXPOSE 8080

# gunicorn is a production web server (better than Flask's dev server)
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
