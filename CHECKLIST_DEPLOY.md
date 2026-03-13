# Checklist de Deploy - FBR-Leads

## VPS1 - Aplicacao

### Sistema
- [ ] Ubuntu 24.04 provisionado
- [ ] Usuario de deploy criado
- [ ] SSH endurecido
- [ ] Docker instalado
- [ ] Docker Compose plugin instalado
- [ ] Tailscale instalado e conectado

### Codigo
- [ ] Repositorio clonado
- [ ] `.env` de producao criado
- [ ] `SESSION_SECRET` gerado
- [ ] `DASHBOARD_EMAIL` e `DASHBOARD_PASSWORD` definidos
- [ ] `APP_DOMAIN` ajustado
- [ ] `BACKEND_URL` e `FRONTEND_URL` revisados

### Containers
- [ ] `postgres` ou conexao final com Supabase validada
- [ ] `redis` no ar
- [ ] `fastapi` no ar
- [ ] `frontend` no ar
- [ ] `n8n` no ar
- [ ] `prometheus` no ar
- [ ] `grafana` no ar
- [ ] `nginx` no ar

### Validacoes
- [ ] `docker compose config`
- [ ] `docker compose ps`
- [ ] `GET /health`
- [ ] login no dashboard
- [ ] `/api/proxy` funcionando
- [ ] Grafana acessivel
- [ ] n8n acessivel

## VPS2 - OpenClaw

### Sistema
- [ ] Ubuntu 24.04 provisionado
- [ ] Docker instalado
- [ ] Tailscale instalado e conectado

### Aplicacao
- [ ] Gateway OpenClaw real implantado
- [ ] Porta 3500 exposta apenas na rede correta
- [ ] `OPENCLAW_WORKSPACE_ID` definido
- [ ] agentes registrados

### Validacoes
- [ ] `/health` do gateway responde
- [ ] agentes autenticam no backend
- [ ] kill switch documentado

## VPS3 - Postal

### Sistema
- [ ] Ubuntu 24.04 provisionado
- [ ] Docker instalado
- [ ] DNS do subdominio do Postal apontado

### Aplicacao
- [ ] Postal instalado
- [ ] `POSTAL_API_URL` definido
- [ ] `POSTAL_API_KEY` gerado
- [ ] `POSTAL_WEBHOOK_SECRET` gerado
- [ ] dominio de envio cadastrado

### DNS de email
- [ ] SPF configurado
- [ ] DKIM configurado
- [ ] DMARC configurado
- [ ] validacao dos registros concluida

### Validacoes
- [ ] painel do Postal acessivel
- [ ] API do Postal responde
- [ ] webhook do Postal chega ao backend
- [ ] aquecimento fase 1 iniciado

## LLM Server

- [ ] Ollama acessivel pela tailnet
- [ ] modelo definido no `.env`
- [ ] timeout validado
- [ ] fallback para camada 2 testado

## Supabase Cloud

- [ ] `SUPABASE_URL` confirmado
- [ ] `SUPABASE_ANON_KEY` confirmado
- [ ] `SUPABASE_SERVICE_ROLE_KEY` confirmado
- [ ] `DATABASE_URL` confirmado
- [ ] `DATABASE_URL_ASYNCPG` confirmado
- [ ] politicas e schema revisados

## FBR-Click

- [ ] projeto criado
- [ ] `FBR_CLICK_API_URL` definido
- [ ] `FBR_CLICK_WEBHOOK_SECRET` gerado
- [ ] canal `#leads-qualificados` criado
- [ ] `FBR_CLICK_CHANNEL_LEADS` definido
- [ ] Cadenciador Bot registrado

## Homologacao final

- [ ] ingest de leads funcionando
- [ ] dispatch funcionando
- [ ] handoff SQL funcionando
- [ ] feedback `deal.won/lost` funcionando
- [ ] monitoring funcionando
- [ ] backup executado
- [ ] restore testado
- [ ] evidencias salvas
- [ ] go-live aprovado
