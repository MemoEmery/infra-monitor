FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Instala dependências primeiro, para aproveitar o cache de camadas
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Usuário sem privilégios
RUN useradd --system --no-create-home --uid 10001 appuser

COPY app.py .

USER appuser

EXPOSE 80

# A rota "/" é a única existente, então o healthcheck consulta ela
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:80/', timeout=4)" || exit 1

CMD ["python", "app.py"]