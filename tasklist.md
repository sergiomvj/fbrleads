# Task List FBR-Leads

Fonte principal: `prd/plano-implantacao.md`, `prd/prd-backend-fbrleads.md` e `prd/prd-frontend-fbrleads.md`.

## Checklist de servidor

- [ ] Provisionar VPS Ubuntu 24.04 com CPU, RAM e disco do PRD
- [ ] Criar usuario de deploy e endurecer SSH
- [ ] Instalar Docker, Docker Compose plugin e Tailscale
- [ ] Validar conectividade da VPS com o Mac Mini e Ollama via Tailscale
- [ ] Clonar o repositorio na VPS
- [ ] Criar `.env` de producao com todos os secrets reais
- [ ] Ajustar `APP_DOMAIN`, `BACKEND_URL`, `FRONTEND_URL` e integracoes externas
- [ ] Publicar certificados TLS e confirmar os paths montados pelo Nginx
- [ ] Configurar DNS principal e registros SPF, DKIM e DMARC
- [ ] Subir `postgres`, `redis`, `openclaw-gateway`, `fastapi`, `frontend`, `n8n`, `prometheus`, `grafana` e `nginx`
- [ ] Validar migrations, healthchecks e proxy reverso
- [ ] Validar login do dashboard, proxy `/api/proxy` e handoff SQL
- [ ] Validar Grafana, Prometheus e backup
- [ ] Registrar bots/agentes no FBR-Click e validar feedback real
- [ ] Executar checklist de homologacao final descrito em `DEPLOY_SERVER.md`

## Skills locais selecionadas

| Skill local | Uso no projeto |
|-------------|----------------|
| `.agent/skills/backend-security-coder` | Autenticacao, headers obrigatorios, webhooks HMAC, secrets, hardening de API e banco |
| `.agent/skills/backend-dev-guidelines` | Organizacao de modulos backend, services, rotas e validacao |
| `.agent/skills/frontend-dev-guidelines` | Estrutura do dashboard Next.js, hooks, tipagem e carregamento de dados |
| `.agent/skills/firecrawl-scraper` | Futuras etapas de scraping institucional |
| `.agent/skills/machine-learning-ops-ml-pipeline` | Pipeline de scoring e operacao de modelos quando chegarmos no enrichment e scorer |
| `.agent/skills/ui-skills` | Apoio pontual na composicao visual do dashboard |

## Batch 1 - Fundacao

- [x] Criar bootstrap do repositorio com backend FastAPI, `docker-compose.yml`, `Dockerfile`, `.env`, `.env.example` e `nginx/default.conf`
- [ ] Provisionar VPS Hetzner Ubuntu 24.04
- [ ] Instalar Docker e Docker Compose na VPS
- [ ] Configurar Tailscale entre VPS e Mac Mini
- [ ] Validar conectividade com Ollama via Tailscale
- [ ] Ajustar SSL real com Certbot e dominio interno
- [ ] Subir stack completa e validar `GET /health`

## Batch 2 - Database

- [x] Criar pasta de migrations SQL
- [x] Implementar schema principal do PRD
- [x] Habilitar RLS em todas as tabelas
- [x] Criar triggers `updated_at` e rotina `pg_cron`
- [x] Criar indexes de performance
- [x] Adicionar seed inicial de workspace, dominio e ICP

## Batch 3 - Backend Core

- [x] Expandir app factory com routers por dominio
- [x] Implementar middleware global de autenticacao por agente
- [x] Construir CRUD inicial de domains
- [x] Construir ingest, listagem, detalhe, enrichment e scoring inicial de leads
- [x] Construir campaigns, writer e dispatcher inicial
- [x] Criar webhooks Postal e FBR-Click com HMAC
- [x] Implementar audit log append-only basico
- [x] Expor endpoint inicial de intelligence report

## Batch 4 - OpenClaw Agents

- [x] Criar pastas base dos agentes com os 7 markdowns obrigatorios
- [x] Configurar gateway scaffold no compose na porta 3500
- [ ] Registrar os agentes por time no gateway e no FBR-Click
- [ ] Refinar de 8 repositorios de time para a cobertura operacional completa dos 13 agentes
- [ ] Documentar limites de aprovacao e kill switch por agente conforme operacao real

## Batch 5 - Postal + Aquecimento

- [ ] Adicionar Postal ao compose de producao
- [ ] Configurar DNS SPF, DKIM e DMARC
- [ ] Implementar regras de pausa por bounce
- [ ] Ativar fase 1 de aquecimento

## Batch 6 - Frontend Dashboard

- [x] Separar o frontend em `frontend/` para nao conflitar com o backend Python
- [x] Criar app Next.js 15 com TypeScript strict
- [x] Configurar `iron-session`, login e middleware
- [x] Implementar proxy `/api/proxy/[...path]`
- [x] Aplicar design system em `layout.tsx` e `globals.css`
- [x] Implementar paginas base `domains`, `leads`, `icp`, `campaigns`, `agents`, `reports`
- [x] Conectar domains, leads, campaigns e reports aos endpoints reais do backend
- [x] Instalar dependencias e validar `typecheck` e `build` em `frontend/`
- [x] Preparar Dockerfile do frontend para deploy no servidor

## Batch 7 - Integracao FBR-Click

- [x] Criar rota de handoff SQL dedicada
- [x] Montar payload de SQL com contexto completo do lead
- [x] Enviar handoff para o FBR-Click via HTTP async
- [x] Processar feedback `deal.won` e `deal.lost` com `deal_id` e `reason`
- [ ] Registrar Cadenciador Bot no FBR-Click real
- [ ] Configurar publicacao de relatorios no canal dedicado em ambiente real
- [ ] Validar ponta a ponta com o endpoint real do FBR-Click

## Batch 8 - Producao e Entrega

- [x] Adicionar Prometheus e Grafana ao compose
- [x] Criar rotina de backup com `scripts/backup.ps1`
- [x] Documentar operacao basica em `docs-runbook.md`
- [x] Adicionar frontend ao compose para deploy integrado
- [ ] Executar teste de carga de 1000 leads
- [ ] Validar fallback das 3 camadas de LLM em runtime
- [ ] Atualizar handoff operacional final com evidencias de producao

## Ordem recomendada de execucao imediata

1. Preencher `.env` de producao e revisar `DEPLOY_SERVER.md`.
2. Subir a stack completa no servidor com `docker compose up --build -d`.
3. Validar frontend, API, Grafana, n8n e handoff SQL.
4. Partir para Postal e homologacao final com FBR-Click.
