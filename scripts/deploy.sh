#!/usr/bin/env bash
# Deploy do Infra Monitor: build da imagem nova, teste em porta temporária,
# e só então troca o container em produção. Faz rollback se algo falhar.
set -euo pipefail

REPO_URL="https://github.com/MemoEmery/infra-monitor.git"
APP_DIR="/opt/infra-monitor"
APP_NAME="infra-monitor"
BRANCH="main"
TEST_PORT=8081

# 1. Atualiza o código (sem apagar nada fora do repositório)
if [ ! -d "$APP_DIR/.git" ]; then
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi
cd "$APP_DIR"
git fetch origin "$BRANCH"
git reset --hard "origin/$BRANCH"

COMMIT="$(git rev-parse --short HEAD)"
NEW_IMAGE="${APP_NAME}:${COMMIT}"
echo ">> Commit a implantar: $COMMIT"

# 2. Constrói a imagem nova (o container antigo continua no ar)
docker build -t "$NEW_IMAGE" .

# 3. Testa a imagem nova em porta temporária
docker rm -f "${APP_NAME}-test" >/dev/null 2>&1 || true
docker run -d --name "${APP_NAME}-test" -p "${TEST_PORT}:80" "$NEW_IMAGE" >/dev/null

ok=0
for i in $(seq 1 20); do
  if curl -fsS "http://127.0.0.1:${TEST_PORT}/" >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 2
done
docker rm -f "${APP_NAME}-test" >/dev/null 2>&1 || true

if [ "$ok" -ne 1 ]; then
  echo "ERRO: a imagem nova nao respondeu no teste. O container atual foi mantido."
  exit 1
fi

# 4. Troca o container (guarda o antigo para rollback)
OLD_IMAGE="$(docker inspect --format '{{.Config.Image}}' "$APP_NAME" 2>/dev/null || true)"
docker rm -f "$APP_NAME" >/dev/null 2>&1 || true
docker run -d --name "$APP_NAME" --restart unless-stopped -p 80:80 "$NEW_IMAGE" >/dev/null

# 5. Verifica a versao em producao
ok=0
for i in $(seq 1 20); do
  if curl -fsS "http://127.0.0.1:80/" >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 2
done

if [ "$ok" -ne 1 ]; then
  echo "ERRO: producao nao respondeu. Tentando rollback."
  docker rm -f "$APP_NAME" >/dev/null 2>&1 || true
  if [ -n "$OLD_IMAGE" ]; then
    docker run -d --name "$APP_NAME" --restart unless-stopped -p 80:80 "$OLD_IMAGE" >/dev/null
    echo "Rollback para $OLD_IMAGE concluido."
  fi
  exit 1
fi

# 6. Limpa imagens antigas (mantem as 3 mais recentes)
docker images "$APP_NAME" --format '{{.Tag}}' | tail -n +4 | xargs -r -I{} docker rmi "${APP_NAME}:{}" >/dev/null 2>&1 || true

echo ">> Deploy concluido: $NEW_IMAGE"