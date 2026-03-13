# FBR-LEADS — PRD Backend v2.0
> **Stack:** OpenClaw + n8n + FastAPI + PostgreSQL + Redis  
> **Versão:** 2.0 — migração completa de CrewAI para OpenClaw  
> **Empresa:** Facebrasil · Fevereiro 2026 · Confidencial

---

## 1. Visão do Produto

### 1.1 Problema

Times comerciais de empresas de médio porte perdem horas por semana em prospecção manual: buscar empresas no LinkedIn, validar e-mails, pesquisar contexto para personalizar mensagens e controlar cadências de follow-up. O trabalho é repetitivo, pouco escalável e gera leads de baixa qualidade por falta de enriquecimento adequado.

### 1.2 Solução

FBR-Leads automatiza o ciclo completo de prospecção outbound: **captação → enriquecimento → validação → aquecimento → handoff**. O time de vendas só recebe SQLs — leads que já responderam ou demonstraram interesse, com contexto completo no FBR-Click.

### 1.3 Público-alvo

Times de vendas e marketing de empresas brasileiras (10–200 colaboradores), especialmente em segmentos B2B. Caso de uso inicial: Facebrasil — time comercial que vende espaços publicitários e serviços digitais para empresas brasileiras nos EUA.

### 1.4 Métricas de Sucesso do MVP

| Métrica | Meta |
|---------|------|
| Leads novos por semana por ICP ativo | ≥ 500 |
| Leads com e-mail válido | ≥ 85% |
| Taxa de resposta na cadência | ≥ 3% |
| Taxa de bounce por domínio | < 2% |
| SQLs entregues via agente no FBR-Click | 100% |

---

## 2. Stack Tecnológica

| Camada | Tecnologia | Detalhe |
|--------|-----------|---------|
| Frontend | Next.js 15 + TypeScript | strict mode + Tailwind + shadcn/ui |
| Proxy | Next.js API Routes | frontend NUNCA fala direto com backend |
| Backend | FastAPI + Python 3.11+ | todas as rotas async |
| Agentes | OpenClaw Gateway | Node.js · MIT · porta 3500 |
| Orquestração | n8n | instância dedicada fbr-leads |
| Banco de dados | PostgreSQL 16 | RLS em todas as tabelas |
| Cache e Filas | Redis 7 | BullMQ-style queues |
| Mail Server | Postal | open source · self-hosted |
| Scraping | Firecrawl + Playwright | sites institucionais + scraping especializado |
| LLM Camada 1 | Ollama (Mac Mini M4) | via Tailscale · timeout 15s |
| LLM Camada 2 | Claude claude-sonnet-4-6 | timeout 30s · fallback automático |
| LLM Camada 3 | GPT-4o | reserva · contingência total |
| Rede | Tailscale | VPS ↔ Mac Mini M4 32GB |
| Infra | VPS Hetzner | 8 vCores / 32GB / 200GB NVMe · Ubuntu 24.04 |
| Containers | Docker Compose | toda a stack containerizada |
| Proxy reverso | Nginx + Certbot | SSL automático |

### Estrutura de Pastas do Backend

```
fbr-leads-backend/
├── app/
│   ├── main.py                  # FastAPI app factory + lifespan
│   ├── core/
│   │   ├── config.py            # pydantic-settings (.env)
│   │   ├── database.py          # asyncpg pool
│   │   ├── redis.py             # Redis client + filas
│   │   ├── llm.py               # cascade Ollama→Claude→GPT-4o
│   │   └── security.py          # JWT validation + rate limiting
│   ├── domains/                 # Time 1 — Guardiões
│   │   ├── routes.py
│   │   ├── service.py
│   │   └── schemas.py
│   ├── leads/                   # Times 2, 3 — Garimpeiros + Analistas
│   │   ├── routes.py
│   │   ├── service.py
│   │   ├── enrichment.py
│   │   ├── scorer.py
│   │   └── schemas.py
│   ├── campaigns/               # Times 4, 5 — Redatores + Cadenciadores
│   │   ├── routes.py
│   │   ├── service.py
│   │   ├── writer.py            # geração de e-mail via Claude API
│   │   ├── dispatcher.py        # seleção de domínio por capacidade
│   │   └── schemas.py
│   ├── intelligence/            # Time 6 — Inteligência
│   │   ├── routes.py
│   │   ├── service.py
│   │   └── schemas.py
│   ├── webhooks/
│   │   ├── postal.py            # bounce/abertura/clique
│   │   └── fbr_click.py         # feedback deal.won/lost
│   └── agents/
│       ├── openclaw_bridge.py   # proxy interno para o Gateway
│       └── action_logger.py     # wrapper de audit log para toda ação
├── agents/                      # repositórios dos 7 Markdowns
│   ├── guardiao-dominios/
│   ├── garimpeiro-linkedin/
│   ├── garimpeiro-cnpj/
│   ├── analista-enriquecedor/
│   ├── redator-principal/
│   ├── cadenciador/
│   └── inteligencia/
├── .env.example
├── docker-compose.yml
└── requirements.txt
```

---

## 3. Database

### 3.1 Tabelas e Relações

| Tabela | Descrição | Relações chave |
|--------|-----------|----------------|
| workspaces | Multi-tenant — cada empresa é um workspace isolado | 1:N com todas as outras |
| domains | Domínios de e-mail com métricas de aquecimento e reputação | N:1 workspace · 1:N email_sends |
| icp_profiles | Perfil de cliente ideal: setor, porte, cargos, região, keywords | N:1 workspace · 1:N campaigns |
| leads | Perfil completo: dados pessoais, empresa, score, estágio no funil | N:1 workspace · 1:N interactions |
| campaigns | Configuração de campanha com ICP e domínios ativos | N:1 workspace · 1:N leads |
| email_sequences | Template de cadência de 4 toques | N:1 campaign |
| email_sends | Registro de cada e-mail enviado | N:1 lead · N:1 domain |
| interactions | Abertura, clique, resposta, opt-out, bounce | N:1 lead · N:1 email_sends |
| agent_action_logs | Audit log imutável (append-only) de toda ação de agente | N:1 workspace · append-only |
| intelligence_reports | Relatórios semanais do Time 6 | N:1 workspace · N:1 campaign |

### 3.2 Schema SQL — Tabelas Principais

```sql
-- ══ WORKSPACES ══
CREATE TABLE workspaces (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  slug        TEXT UNIQUE NOT NULL,
  owner_id    UUID NOT NULL REFERENCES auth.users(id),
  settings    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ══ DOMAINS ══
CREATE TABLE domains (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id     UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  domain           TEXT NOT NULL,
  warm_phase       SMALLINT DEFAULT 1 CHECK (warm_phase BETWEEN 1 AND 4),
  daily_limit      SMALLINT DEFAULT 10,
  sends_today      SMALLINT DEFAULT 0,
  reputation_score SMALLINT DEFAULT 100 CHECK (reputation_score BETWEEN 0 AND 100),
  bounce_rate      NUMERIC(5,2) DEFAULT 0,
  is_blacklisted   BOOLEAN DEFAULT FALSE,
  is_active        BOOLEAN DEFAULT TRUE,
  warm_started_at  TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

-- ══ ICP_PROFILES ══
CREATE TABLE icp_profiles (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  sectors       TEXT[] DEFAULT '{}',
  company_sizes TEXT[] DEFAULT '{}',
  target_roles  TEXT[] DEFAULT '{}',
  regions       TEXT[] DEFAULT '{}',
  keywords      TEXT[] DEFAULT '{}',
  min_score     SMALLINT DEFAULT 60,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- ══ LEADS ══
CREATE TABLE leads (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id    UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  campaign_id     UUID REFERENCES campaigns(id),
  icp_profile_id  UUID REFERENCES icp_profiles(id),
  -- Dados pessoais
  name            TEXT,
  email           TEXT,
  email_valid     BOOLEAN,
  role            TEXT,
  linkedin_url    TEXT,
  -- Dados da empresa
  company_name    TEXT,
  company_cnpj    TEXT,
  company_sector  TEXT,
  company_size    TEXT,
  company_website TEXT,
  -- Qualificação
  score           SMALLINT DEFAULT 0 CHECK (score BETWEEN 0 AND 100),
  funnel_stage    TEXT DEFAULT 'captured' CHECK (funnel_stage IN
                  ('captured','enriching','validated','warming','qualified','sql','discard')),
  source          TEXT,  -- linkedin|cnpj|maps|scraping|trigger
  enrichment_data JSONB DEFAULT '{}',
  discard_reason  TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ══ CAMPAIGNS ══
CREATE TABLE campaigns (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id    UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  icp_profile_id  UUID REFERENCES icp_profiles(id),
  name            TEXT NOT NULL,
  status          TEXT DEFAULT 'draft' CHECK (status IN ('draft','active','paused','completed')),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ══ EMAIL_SEQUENCES ══
CREATE TABLE email_sequences (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  touch_number SMALLINT NOT NULL CHECK (touch_number BETWEEN 1 AND 4),
  day_offset  SMALLINT NOT NULL,  -- 1, 4, 9, 16
  subject     TEXT,
  body        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ══ EMAIL_SENDS ══
CREATE TABLE email_sends (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id      UUID NOT NULL REFERENCES leads(id),
  domain_id    UUID NOT NULL REFERENCES domains(id),
  sequence_id  UUID REFERENCES email_sequences(id),
  status       TEXT DEFAULT 'pending' CHECK (status IN ('pending','sent','bounced','opened','clicked','replied')),
  sent_at      TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- ══ INTERACTIONS ══
CREATE TABLE interactions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id      UUID NOT NULL REFERENCES leads(id),
  email_send_id UUID REFERENCES email_sends(id),
  type         TEXT NOT NULL CHECK (type IN ('open','click','reply','opt_out','bounce')),
  metadata     JSONB DEFAULT '{}',
  occurred_at  TIMESTAMPTZ DEFAULT now()
);

-- ══ INTELLIGENCE_REPORTS ══
CREATE TABLE intelligence_reports (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id),
  campaign_id  UUID REFERENCES campaigns(id),
  content      JSONB NOT NULL DEFAULT '{}',
  insights     TEXT,
  generated_at TIMESTAMPTZ DEFAULT now()
);

-- ══ AGENT_ACTION_LOGS (append-only · audit) ══
CREATE TABLE agent_action_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id),
  agent_id      TEXT NOT NULL,
  team          TEXT NOT NULL,  -- guardiao|garimpeiro|analista|redator|cadenciador|inteligencia
  action_type   TEXT NOT NULL,
  trigger_type  TEXT NOT NULL,  -- heartbeat|event|manual
  payload       JSONB NOT NULL DEFAULT '{}',
  result        JSONB,
  error         TEXT,
  executed_at   TIMESTAMPTZ DEFAULT now()
  -- SEM updated_at — append-only
);
```

### 3.3 RLS — Policies Obrigatórias

> **🔒 OBRIGATÓRIO:** RLS habilitado em TODAS as tabelas, sem exceção (`securitycoderules.md`)

```sql
-- Habilitar em TODAS as tabelas
ALTER TABLE workspaces        ENABLE ROW LEVEL SECURITY;
ALTER TABLE domains           ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads             ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns         ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_sequences   ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_sends       ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_action_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE icp_profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE intelligence_reports ENABLE ROW LEVEL SECURITY;

-- Isolamento por workspace (aplicar em cada tabela com workspace_id)
CREATE POLICY workspace_isolation ON leads
  FOR ALL USING (
    workspace_id IN (SELECT id FROM workspaces WHERE owner_id = auth.uid())
  );

-- Repetir para: domains, campaigns, email_sends, interactions, icp_profiles, intelligence_reports

-- Audit log: apenas INSERT — imutável
CREATE POLICY audit_insert_only ON agent_action_logs FOR INSERT WITH CHECK (true);
CREATE POLICY audit_select_workspace ON agent_action_logs FOR SELECT USING (
  workspace_id IN (SELECT id FROM workspaces WHERE owner_id = auth.uid())
);
-- NÃO criar policies de UPDATE ou DELETE em agent_action_logs
```

### 3.4 Triggers e Indexes

```sql
-- updated_at automático
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql;

CREATE TRIGGER leads_updated_at     BEFORE UPDATE ON leads     FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER domains_updated_at   BEFORE UPDATE ON domains   FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER campaigns_updated_at BEFORE UPDATE ON campaigns FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Reset diário de sends_today (00:00 UTC via pg_cron)
SELECT cron.schedule('reset-sends-today', '0 0 * * *',
  'UPDATE domains SET sends_today = 0 WHERE is_active = true');

-- Indexes de performance
CREATE INDEX idx_leads_workspace  ON leads(workspace_id);
CREATE INDEX idx_leads_funnel     ON leads(workspace_id, funnel_stage);
CREATE INDEX idx_leads_score      ON leads(workspace_id, score DESC);
CREATE INDEX idx_domains_active   ON domains(workspace_id, is_active);
CREATE INDEX idx_sends_lead       ON email_sends(lead_id, sent_at DESC);
CREATE INDEX idx_logs_workspace   ON agent_action_logs(workspace_id, executed_at DESC);
CREATE INDEX idx_logs_agent       ON agent_action_logs(agent_id, executed_at DESC);
```

---

## 4. Endpoints FastAPI

> **🔒 Autenticação:** Todos os endpoints `/api/*` requerem header `X-Agent-Id` (JWT do agente OpenClaw). Sem esse header → 401 automático.

| Método | Path | Descrição | Time |
|--------|------|-----------|------|
| GET | /health | Status do sistema, LLM ativo, conexão Tailscale | — |
| GET | /api/domains | Listar domínios com métricas de saúde | T1 |
| POST | /api/domains | Cadastrar novo domínio | T1 |
| PATCH | /api/domains/{id}/phase | Avançar fase de aquecimento manualmente | T1 |
| POST | /api/domains/{id}/check-blacklist | Verificação imediata em blacklists | T1 |
| POST | /api/leads/ingest | Ingerir batch de leads brutos dos Garimpeiros | T2 |
| POST | /api/leads/{id}/enrich | Triggar enriquecimento de lead específico | T3 |
| POST | /api/leads/{id}/validate-email | Chamar ZeroBounce e salvar resultado | T3 |
| POST | /api/leads/{id}/score | Calcular score via LLM e persistir | T3 |
| GET | /api/leads | Listar leads com filtros (stage, score, campaign) | T3 |
| GET | /api/leads/{id} | Detalhe completo com histórico de interações | T3 |
| POST | /api/campaigns | Criar campanha com ICP e sequência | T4 |
| POST | /api/campaigns/{id}/write-email | Gerar e-mail personalizado via Claude API | T4 |
| POST | /api/campaigns/{id}/dispatch | Dispatcher seleciona domínio e agenda envio | T5 |
| POST | /api/webhooks/postal | Receber bounce/abertura/clique (HMAC-SHA256) | T5 |
| POST | /api/webhooks/fbr-click | Receber feedback deal.won/lost (HMAC-SHA256) | T6 |
| GET | /api/intelligence/report | Buscar relatório semanal mais recente | T6 |
| POST | /api/intelligence/generate | Triggar geração de relatório manualmente | T6 |
| GET | /api/logs | Listar audit log com filtros por agente e período | — |
| GET | /api/icp | Listar perfis ICP do workspace | — |
| POST | /api/icp | Criar ou atualizar perfil ICP | — |

---

## 5. Cascata de LLM — app/core/llm.py

> Pressuposto 4 da Bíblia FBR: indisponibilidade de qualquer camada não interrompe a operação — degrada de forma controlada.

| Camada | Modelo | Uso no FBR-Leads | Timeout | Fallback |
|--------|--------|------------------|---------|----------|
| 1 — Primária | Ollama · Mac Mini M4 via Tailscale | Scoring de leads (volume alto), classificação de ICP, deduplicação | 15s | → Camada 2 |
| 2 — Secundária | Claude claude-sonnet-4-6 | Geração de e-mails personalizados, análise de resposta, relatórios de inteligência | 30s | → Camada 3 |
| 3 — Reserva | GPT-4o API | Contingência total — ativada automaticamente, alerta para owner | 30s | Alerta crítico |

```python
# app/core/llm.py — Comportamento esperado

# 1. n8n faz health check nas 3 camadas a cada 60s → publica no Redis:
#    redis.set("llm:layer1:status", "ok"|"error")
#    redis.set("llm:layer2:status", "ok"|"error")
#    redis.set("llm:layer3:status", "ok"|"error")

# 2. llm.py lê o status do Redis antes de cada chamada (sem latência de health check)

# 3. Lógica de roteamento:
#    Se layer1 ok  → Ollama (timeout 15s)
#    Se layer1 err → Claude API (timeout 30s)
#    Se layer2 err → GPT-4o (timeout 30s)
#    Se layer3 err → raise LLMUnavailableError + alerta crítico para owner

# 4. GET /health deve retornar:
#    {"status": "ok", "llm_layer": 1, "model": "llama3.1:8b"}
```

---

## 6. Os 6 Times de Agentes OpenClaw

> **Pressuposto 1 (Bíblia FBR):** Todo agente FBR é definido por exatamente **7 arquivos Markdown** versionados em Git:
> `SOUL.md` · `IDENTITY.md` · `TASKS.md` · `AGENTS.md` · `MEMORY.md` · `TOOLS.md` · `USER.md`

### Time 1 — Guardiões do Mail Server

**Missão:** Proteger e maximizar a reputação de cada domínio. Fundação de toda a operação.

| Agente | LLM | Heartbeat | Requer Aprovação |
|--------|-----|-----------|------------------|
| Auditor de Domínios | Ollama | A cada 30min | — |
| Gestor de Aquecimento | Ollama | A cada 30min | Pausar domínio definitivamente |
| Monitor de Reputação | Ollama | A cada 30min | — |
| Controlador de Rotação | Ollama | Contínuo (Redis) | Alterar fase de aquecimento manualmente |

**Protocolo de Aquecimento:**

| Fase | Período | Volume/dia | Atividade |
|------|---------|-----------|-----------|
| 1 | Dias 1–30 | Interno apenas | Troca de e-mails entre contas do sistema |
| 2 | Dias 31–60 | 10–20 e-mails | Primeiros contatos externos (leads alto score) |
| 3 | Dias 61–90 | 30–50 e-mails | Volume controlado com cadências completas |
| 4 | Dia 90+ | 50–100 e-mails | Operação plena com monitoramento contínuo |

### Time 2 — Garimpeiros

**Missão:** Captar dados brutos de múltiplas fontes e transformar em registros estruturados.

| Agente | LLM | Heartbeat | Fonte de dados |
|--------|-----|-----------|----------------|
| Scraper Web | Ollama | Sob demanda (n8n) | Firecrawl em sites institucionais |
| Scraper Especializado | Ollama | Sob demanda (n8n) | Python/Playwright para fontes específicas |
| Coletor CNPJ | Ollama | A cada 4h | CNPJ.biz + Receita Federal |
| Minerador LinkedIn | Ollama (deduplicação) | A cada 2h | Apify — rate limiting respeitado |
| Agente de Gatilhos | Ollama | A cada 6h | Google Alerts, RSS, portais de vagas |

**Regras:** Deduplicação automática por CNPJ/domínio antes de inserir no banco. LinkedIn tratado como fonte "premium mas instável" — sistema funciona sem ela.

### Time 3 — Analistas

**Missão:** Enriquecer, validar e qualificar leads. Pipeline rígido em 3 etapas obrigatórias.

**Pipeline de validação (ordem imutável):**

```
1. Validar e-mail via ZeroBounce → se inválido: discard imediato
2. Verificar aderência ao ICP   → se fora do perfil: archive
3. Calcular score 0-100 via LLM → se abaixo de min_score: discard
         ↓
   Lead entra na fila de aquecimento
```

| Agente | LLM | Heartbeat |
|--------|-----|-----------|
| Enriquecedor | Ollama | Contínuo (fila Redis) |
| Validador de E-mail | — (API ZeroBounce) | Contínuo (fila Redis) |
| Analista de ICP | Ollama | Contínuo (fila Redis) |
| Scorer | Ollama → Claude | Contínuo (fila Redis) |

### Time 4 — Redatores

**Missão:** Criar mensagens altamente personalizadas. Personalização é o que separa prospecção de spam.

| Agente | LLM | Heartbeat | Requer Aprovação |
|--------|-----|-----------|------------------|
| Pesquisador de Contexto | Ollama | Junto com Redator | — |
| Redator Principal | **Claude (obrigatório)** | Sob demanda (campanha) | — |
| Revisor | Ollama | Junto com Redator | Reprovar e-mail (retorna com feedback) |
| Testador A/B | Ollama | Junto com Redator | — |

**Regras de redação para proteção de domínio:**

Obrigatório:
- Mencionar contexto específico da empresa do lead
- Texto curto (3–5 parágrafos)
- Um único CTA claro
- Tom de conversa, não de vendas

Proibido:
- Links no primeiro e-mail
- Anexos de qualquer tipo
- Palavras-gatilho: GRÁTIS, PROMOÇÃO, CLIQUE AQUI
- Mais de uma pergunta no mesmo e-mail

### Time 5 — Cadenciadores

**Missão:** Controlar timing e sequência de envio respeitando limites de cada domínio.

**Cadência padrão:**

| Toque | Timing | Objetivo |
|-------|--------|----------|
| #1 | Dia 1 | Primeiro contato — contexto específico, sem oferta |
| #2 | Dia 4 | Reforçar com valor — conteúdo relevante para o setor |
| #3 | Dia 9 | Criar urgência leve — referência a cliente similar |
| #4 | Dia 16 | Breakup — tom direto, porta aberta |

| Agente | LLM | Heartbeat | Requer Aprovação |
|--------|-----|-----------|------------------|
| Dispatcher | Ollama | Contínuo (fila Redis) | Cancelar envio de toda uma campanha |
| Agendador | Ollama | Contínuo (fila Redis) | — |
| Monitor de Respostas | Ollama | A cada 15min | — |
| Registrador | — | Contínuo (fila Redis) | — |

**Regras do Dispatcher:**
- Selecionar domínio com `sends_today < daily_limit`
- Respeitar horário comercial do fuso do lead
- Sem envios em fins de semana
- Pausa automática se bounce detectado
- Resposta positiva → aciona handoff para FBR-Click imediatamente

### Time 6 — Inteligência

**Missão:** Retroalimentar os outros cinco times com aprendizados. Cérebro estratégico do sistema.

| Agente | LLM | Heartbeat |
|--------|-----|-----------|
| Analista de Campanha | Claude | Domingo 18h UTC-5 |
| Otimizador de Mensagens | Claude | Domingo 18h UTC-5 |
| Analista de ICP | Claude | Domingo 18h UTC-5 |
| Gerador de Relatórios | Claude | Domingo 18h UTC-5 |

---

## 7. Segurança

### 7.1 Autenticação — Dashboard Next.js

> **🔒 Regra Absoluta:** Frontend NUNCA se comunica diretamente com o FastAPI backend. Todo request passa pelo proxy Next.js API Routes.

- ✅ iron-session com cookie `httpOnly + secure + sameSite=lax` para sessão do dashboard
- ✅ `SESSION_SECRET` com 64 caracteres gerado via `openssl rand -base64 48`, exclusivamente em variável de ambiente
- ✅ Proxy Next.js decripta cookie, extrai `workspace_id` e repassa via header `X-Workspace-Id` ao backend
- ✅ Backend FastAPI valida `X-Workspace-Id` via dependency injection em **TODAS** as rotas protegidas
- 🚫 Tokens, session IDs ou workspace_ids **NUNCA** expostos no console, localStorage ou URLs visíveis
- 🚫 Variáveis sensíveis **NUNCA** com prefixo `NEXT_PUBLIC_`

### 7.2 Autenticação — Agentes OpenClaw

- ✅ Cada agente tem JWT único gerado pelo FBR-Click ao ser registrado
- ✅ JWT rotacionado automaticamente a cada 24h via job n8n + OpenClaw Gateway
- ✅ FastAPI valida JWT do agente em middleware global — antes de qualquer handler
- ✅ Webhooks Postal e FBR-Click validam assinatura HMAC-SHA256 antes de processar payload
- 🚫 Agentes não compartilham tokens — um token comprometido não afeta outros agentes

### 7.3 Proteção contra Prompt Injection

| Vetor de Ataque | Mitigação |
|-----------------|-----------|
| Dado de lead com instrução embutida: `nome="Ignore o SOUL.md..."` | Sanitização de todos os campos antes de inserir no contexto. HTML strip + instruction boundary explícito. |
| Site scrapeado contendo instruções ocultas em HTML comentado | Firecrawl retorna markdown limpo. Agente Garimpeiro não executa conteúdo — apenas extrai dados estruturados. |
| Resposta de lead com instrução de hijack | Monitor de Respostas classifica intenção via LLM ANTES de qualquer ação. Resposta suspeita → alerta para humano. |
| SOUL.md com precedência absoluta | SOUL.md é o primeiro arquivo lido pelo OpenClaw em cada ciclo. Instruções conflitantes são descartadas. |

### 7.4 Rate Limiting

| Escopo | Limite | Ação ao exceder |
|--------|--------|-----------------|
| Por agente OpenClaw | 60 ações/minuto | Fila de espera com backoff exponencial. Alerta no dashboard. |
| Por domínio — Fase 2 | 20/dia | Dispatcher rejeita e redistribui para outro domínio. |
| Por domínio — Fase 3 | 50/dia | Dispatcher rejeita e redistribui para outro domínio. |
| Por domínio — Fase 4 | 100/dia | Dispatcher rejeita e redistribui para outro domínio. |
| ZeroBounce API | Conforme plano contratado | Pausar validações e alertar gestor ao atingir 80%. |
| Apify (LinkedIn) | Máx 25 ações/dia por conta | Garimpeiro respeita limite. Múltiplas contas em rodízio. |
| Claude API | Conforme plano contratado | Fallback automático para GPT-4o ao atingir rate limit. |

### 7.5 Variáveis de Ambiente (.env.example)

```bash
# ══ DATABASE ══
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/fbr_leads
REDIS_URL=redis://localhost:6379/0

# ══ LLM CAMADA 1 — Ollama (Tailscale) ══
OLLAMA_BASE_URL=http://100.x.x.x:11434   # IP Tailscale do Mac Mini
OLLAMA_MODEL=llama3.1:8b
OLLAMA_TIMEOUT_SECONDS=15

# ══ LLM CAMADA 2 — Claude API ══
ANTHROPIC_API_KEY=sk-ant-REMOVIDO
ANTHROPIC_MODEL=claude-sonnet-4-6
ANTHROPIC_TIMEOUT_SECONDS=30

# ══ LLM CAMADA 3 — GPT-4o (reserva) ══
OPENAI_API_KEY=sk-REMOVIDO
OPENAI_MODEL=gpt-4o

# ══ INTEGRAÇÕES EXTERNAS ══
ZEROBOUNCE_API_KEY=zb-REMOVIDO
APIFY_API_TOKEN=apify_REMOVIDO
FIRECRAWL_API_KEY=fc-REMOVIDO

# ══ POSTAL MAIL SERVER ══
POSTAL_API_URL=https://postal.fbr.internal
POSTAL_API_KEY=postal-REMOVIDO
POSTAL_WEBHOOK_SECRET=REMOVIDO

# ══ FBR-CLICK INTEGRATION ══
FBR_CLICK_API_URL=https://fbr-click.com/api
FBR_CLICK_WEBHOOK_SECRET=REMOVIDO
FBR_CLICK_CHANNEL_LEADS=chn_...           # ID do canal #leads-qualificados

# ══ OPENCLAW GATEWAY ══
OPENCLAW_GATEWAY_URL=http://localhost:3500
OPENCLAW_WORKSPACE_ID=ws_...              # ID do workspace no FBR-Click

# ══ DASHBOARD ══
SESSION_SECRET=...                        # 64 chars · openssl rand -base64 48
BACKEND_URL=http://localhost:8000         # Proxy Next.js → FastAPI (interno)
```

---

## 8. Integração FBR-Click

### 8.1 Canal Dedicado: #leads-qualificados

O Cadenciador Bot é o membro responsável pelo canal e aparece na sidebar do FBR-Click como qualquer outro membro do time. Quando um SQL é gerado, o bot cria o deal, abre o canal do deal, posta o contexto e notifica o vendedor. O vendedor **nunca** precisa acessar o dashboard do FBR-Leads.

### 8.2 Payload do Handoff SQL

```json
{
  "event": "sql_handoff",
  "lead": {
    "name": "Rafael Souza",
    "role": "Diretor de Marketing",
    "company": "TechCorp Brasil",
    "cnpj": "12.345.678/0001-99",
    "email": "rafael@techcorp.com.br",
    "linkedin": "linkedin.com/in/rafaelsouza",
    "score": 87,
    "source": "linkedin",
    "icp_match": "Empresas brasileiras nos EUA · Porte médio · Marketing",
    "enrichment_notes": "Empresa abriu escritório em Miami em jan/26.",
    "interaction_summary": "3 e-mails enviados. Respondeu ao Toque #2 com interesse."
  },
  "action": {
    "create_deal": true,
    "notify_user_id": "usr_julia_manager",
    "post_to_channel": "chn_leads_qualificados"
  }
}
```

### 8.3 Feedback Loop FBR-Click → FBR-Leads

| Evento FBR-Click | Ação no FBR-Leads | Impacto no modelo |
|------------------|-------------------|-------------------|
| deal.won | Marcar lead como convertido · Registrar em intelligence_reports | Reforça padrões do ICP e scoring |
| deal.lost (preço) | Marcar lost + registrar razão | Ajusta peso de variáveis de budget |
| deal.lost (não era decisor) | Marcar lost + registrar razão | Refina filtragem de cargos no ICP |
| deal.lost (sem resposta) | Marcar lost | Otimiza padrões de mensagem para o Redator |

---

## 9. Requisitos Não-Funcionais

| Categoria | Requisito | Referência |
|-----------|-----------|------------|
| Performance | Endpoints FastAPI respondem em < 500ms para 95% das requisições | securitycoderules.md |
| Performance | Streaming de respostas de IA via SSE — nunca aguardar resposta completa | securitycoderules.md |
| Performance | Redis gerencia filas — picos de carga não degradam o sistema principal | Bíblia FBR Cap.8 |
| Segurança | RLS habilitado em todas as tabelas PostgreSQL sem exceção | securitycoderules.md |
| Segurança | JWT rotacionado a cada 24h para cada agente OpenClaw | Bíblia FBR Cap.9 |
| Segurança | iron-session com cookie httpOnly + secure + sameSite=lax no dashboard | securitycoderules.md |
| Segurança | Todo input sanitizado antes de enviar ao OpenClaw Gateway | Bíblia FBR Cap.9 |
| Disponibilidade | Fallback automático de LLM em cascata: Ollama → Claude → GPT-4o | Bíblia FBR Pressuposto 4 |
| Disponibilidade | Detecção de indisponibilidade do Mac Mini em ≤ 30s com redirecionamento | Bíblia FBR Pressuposto 4 |
| Auditoria | Toda ação de agente logada com payload, resultado, trigger e timestamp | Bíblia FBR Cap.9 |
| Auditoria | Audit log imutável — nenhum agente pode deletar seus próprios logs | securitycoderules.md |
| Código | Todas as rotas FastAPI async. Zero chamadas bloqueantes. | securitycoderules.md |
| Código | Type hints obrigatórios em todo o Python. Sem `Any` genérico. | securitycoderules.md |
| Código | Máximo 20 linhas por função. Máximo 3 argumentos — agrupar em Pydantic model. | securitycoderules.md |

---

## 10. Dependências

### requirements.txt

```
fastapi==0.115.0
uvicorn[standard]==0.31.0
asyncpg==0.30.0          # Async PostgreSQL driver
redis[asyncio]==5.1.0    # Async Redis client
pydantic==2.9.0          # Schemas + settings
pydantic-settings==2.5.0 # .env loading
anthropic==0.40.0        # Claude API (Camada 2 LLM)
openai==1.55.0           # GPT-4o fallback (Camada 3)
httpx==0.28.0            # Async HTTP client (Ollama, ZeroBounce, Postal)
python-jose==3.3.0       # JWT validation
python-multipart==0.0.12 # File upload (se necessário)
apify-client==1.8.0      # LinkedIn scraping via Apify
firecrawl-py==1.4.0      # Web scraping
playwright==1.49.0       # Custom scraping (CNPJ.biz, Google Maps)
slowapi==0.1.9            # Rate limiting por user/agent
```

---

## 11. Gestão de Riscos

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| Domínio incluído em blacklist | Alto | Média | Guardião monitora 2x/dia. Rotação automática em < 5min. |
| Taxa de bounce > 2% | Alto | Média | Pausa automática do domínio. Revisão da fonte de leads. |
| Mac Mini M4 offline (Camada 1 LLM) | Médio | Baixa | Fallback automático para Claude API em ≤ 30s. |
| Conta Apify suspensa (LinkedIn) | Médio | Alta | Múltiplas contas em rodízio. Garimpeiros Web e CNPJ cobrem. |
| Rate limit Claude API | Médio | Baixa | Fallback automático para GPT-4o. Alerta a 80% do limite. |
| Prompt injection via dados de lead | Alto | Baixa | Sanitização + instruction boundary + SOUL.md carregado primeiro. |
| Saturação da VPS sob carga | Baixo | Baixa | Redis gerencia filas. Upgrade Hetzner disponível em < 1h. |

---

*FBR-Leads · PRD Backend v2.0 · Fevereiro 2026 · Facebrasil · Confidencial*
