# Infra Monitor — Deploy e Automação de Infraestrutura (CI/CD)

Projeto da disciplina **Infraestrutura de Software — 2ª V.A.**

**Equipe (Grupo 1):** Emerson Oliveira · Igor Pereira

## 1. Descrição

O **Infra Monitor** é uma aplicação web em Flask, fornecida pelo professor, que mostra a telemetria do servidor onde roda (hostname/ID do container, arquitetura, uso de CPU e de RAM) e consome uma API externa (Advice Slip) para exibir um "Conselho DevOps do Dia".

O objetivo do trabalho não é a aplicação em si, e sim a **infraestrutura ao redor dela**: empacotar em Docker, publicar em uma VM Ubuntu na nuvem e automatizar a atualização com um pipeline de CI/CD. Um `git push` na branch `main` atualiza a aplicação no servidor sem intervenção manual.

## 2. Objetivo acadêmico

- Containerizar uma aplicação com Docker.
- Provisionar e proteger uma VM Linux em nuvem (Azure for Students).
- Configurar autenticação SSH por chaves, sem senhas.
- Criar um pipeline com GitHub Actions que implanta automaticamente.
- Documentar e demonstrar o fluxo completo.

## 3. Arquitetura

```text
Desenvolvedor (git push na main)
        │
        ▼
GitHub (repositório público)
        │  dispara o workflow
        ▼
GitHub Actions (.github/workflows/deploy.yml)
        │  SSH com chave dedicada + host key verificada
        ▼
VM Ubuntu 24.04 (Azure) ── usuário "deploy" ──► scripts/deploy.sh
        │     1. atualiza o código em /opt/infra-monitor
        │     2. constrói a imagem Docker (tag = commit)
        │     3. testa a imagem nova em porta temporária (8081)
        │     4. troca o container de produção; rollback se falhar
        ▼
Container Docker (porta 80 → 80)  ──►  Internet (http://IP_PUBLICO_DA_VM)
```

A VM obtém o código do repositório público e constrói a imagem localmente. Não há registry de imagens, o que mantém a solução simples.

## 4. Tecnologias

Python 3.12 · Flask · psutil · requests · Docker Engine · Ubuntu Server 24.04 LTS · Microsoft Azure (VM) · Git/GitHub · GitHub Actions · OpenSSH (chaves ed25519).

## 5. Estrutura do repositório

```text
infra-monitor/
├── app.py                      # aplicação fornecida pelo professor (não alterada, exceto a variável EQUIPE)
├── requirements.txt            # flask, psutil, requests (versões fixas)
├── Dockerfile                  # imagem python:3.12-slim, usuário sem privilégios, healthcheck
├── .dockerignore
├── .gitignore
├── .gitattributes              # força LF em scripts .sh
├── scripts/
│   └── deploy.sh               # lógica de deploy executada na VM
└── .github/
    └── workflows/
        └── deploy.yml          # pipeline CI/CD
```

## 6. Pré-requisitos

- Git.
- Docker (Docker Desktop no Windows, com WSL 2 e virtualização habilitada na BIOS).
- Conta no GitHub e conta Azure for Students.
- Cliente SSH (OpenSSH, já incluso no Windows 10/11).

## 7. Execução local

```bash
git clone https://github.com/MemoEmery/infra-monitor.git
cd infra-monitor

# construir a imagem
docker build -t infra-monitor:local .

# executar (porta do host : porta do container)
docker run -d --name infra-monitor -p 80:80 infra-monitor:local

# verificar
docker ps
docker logs infra-monitor
```

Abra **http://localhost**. O hostname exibido deve ser igual ao `CONTAINER ID` do `docker ps`. Após cerca de 40 segundos o container aparece como `(healthy)`.

Par
