# Deploy no Servidor

## Preparacao da VPS

1. Provisionar VPS Ubuntu 24.04 com disco, RAM e CPU do PRD.
2. Criar usuario de deploy e desabilitar login root por senha.
3. Instalar atualizacoes do sistema e utilitarios basicos.
4. Configurar firewall liberando 22, 80, 443, 3000, 3001, 5432, 5678, 9090 e 3500 apenas quando necessario.
5. Instalar Docker, Docker Compose plugin e validar permissao do usuario de deploy.
6. Instalar Tailscale e conectar a VPS a mesma tailnet do Mac Mini.
7. Validar conectividade com o Ollama no Mac Mini via Tailscale.

## Codigo e ambiente

1. Clonar o repositorio na VPS.
2. Criar `.env` de producao sem commitar secrets.
3. Preencher secrets de OpenAI, Anthropic, FBR-Click, Postal e dashboard.
4. Ajustar `APP_DOMAIN`, `BACKEND_URL`, `FBR_CLICK_API_URL` e `FRONTEND_URL` para o dominio real.
5. Garantir certificados TLS e paths montados pelo Nginx.
6. Confirmar que `frontend/package-lock.json` esta presente para build reprodutivel.

## DNS e dominios

1. Apontar dominio principal para a VPS.
2. Configurar subdominios ou paths necessarios para frontend, Grafana, n8n e Postal.
3. Criar registros SPF, DKIM e DMARC para os dominios de envio.
4. Validar DNS do Postal antes de iniciar aquecimento.

## Containers e servicos

1. Buildar e subir `postgres`, `redis`, `openclaw-gateway`, `fastapi`, `frontend`, `n8n`, `prometheus`, `grafana` e `nginx`.
2. Validar `docker compose ps` e healthchecks.
3. Confirmar que migrations foram aplicadas na primeira subida.
4. Confirmar que o frontend responde atras do Nginx.
5. Confirmar Grafana em `/grafana/` e n8n em `/n8n/`.

## Integracoes externas

1. Validar webhook HMAC do Postal.
2. Validar webhook HMAC do FBR-Click.
3. Testar `POST /api/campaigns/{id}/handoff-sql` com endpoint real do FBR-Click.
4. Registrar Cadenciador Bot e demais agentes no FBR-Click.
5. Confirmar feedback `deal.won/lost` escrevendo em `intelligence_reports`.

## Operacao e seguranca

1. Rodar `python -m compileall app` antes do deploy.
2. Rodar `cd frontend && npm run typecheck` e `npm run build` antes do deploy.
3. Configurar rotina diaria de `scripts/backup.ps1` ou equivalente Linux.
4. Validar restore de backup em ambiente isolado.
5. Configurar dashboards e alertas basicos no Grafana.
6. Revisar kill switch dos agentes e owners responsaveis.

## Homologacao final

1. Testar login no dashboard.
2. Testar ingest de leads, dispatch e handoff SQL.
3. Testar feedback `deal.won` e `deal.lost`.
4. Testar observabilidade, backup e restore.
5. Registrar evidencias do go-live e handoff operacional.
