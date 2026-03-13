# Plano de Implementacao Final - FBR-Leads

Documento consolidado para execucao, deploy e homologacao do FBR-Leads.

Fonte de verdade usada nesta consolidacao:
- `prd/plano-implantacao.md`
- `prd/prd-backend-fbrleads.md`
- `prd/prd-frontend-fbrleads.md`
- estado atual do repositorio
- topologia final definida para a infraestrutura FBR

## 1. Topologia oficial

### Arquitetura macro
- VPS1: frontend Next.js, FastAPI, n8n, Grafana, Prometheus e Nginx
- VPS2: OpenClaw Gateway e runtime dos agentes
- VPS3: Postal e infraestrutura de mail server
- LLM Server: Ollama
- Banco principal: Supabase Cloud

### Responsabilidade por host

#### VPS1
Responsavel por:
- servir o dashboard web do FBR-Leads
- expor a API FastAPI principal
- executar n8n
- centralizar observabilidade basica
- atuar como ponto principal de entrada HTTP/HTTPS via Nginx

Servicos previstos:
- `frontend`
- `fastapi`
- `n8n`
- `prometheus`
- `grafana`
- `nginx`
- `redis` se mantido localmente na VPS1

#### VPS2
Responsavel por:
- hospedar o OpenClaw Gateway real
- hospedar runtime e operacao dos agentes
- concentrar as chamadas de automacao agentica
- isolar processamento autonomo da aplicacao principal

Servicos previstos:
- `openclaw-gateway`
- possiveis workers auxiliares dos agentes

#### VPS3
Responsavel por:
- operar o Postal
- expor painel e API do Postal
- controlar a infraestrutura de envio de emails
- isolar reputacao, mail queues e DNS de envio

Servicos previstos:
- `postal`
- banco/servicos auxiliares que o Postal exigir
- endpoints de painel e API do Postal

#### LLM Server
Responsavel por:
- servir o Ollama
- responder para o FBR-Leads via rede privada/Tailscale

#### Supabase Cloud
Responsavel por:
- banco principal do sistema
- credenciais e conexoes persistentes
- possiveis recursos complementares do ecossistema Supabase quando necessario

## 2. Estado atual do repositorio

### Concluido em codigo
- bootstrap do backend FastAPI
- migrations SQL base
- rotas de domains
- rotas de leads
- rotas de campaigns
- webhooks com HMAC
- audit log append-only basico
- handoff SQL base para FBR-Click
- intelligence report endpoint inicial
- scaffold do OpenClaw Gateway
- repositorios dos agentes com os 7 markdowns obrigatorios
- frontend Next.js separado em `frontend/`
- login com `iron-session`
- middleware do dashboard
- proxy `/api/proxy`
- paginas base do dashboard
- frontend validado com `typecheck` e `build`
- observabilidade bootstrapada com Prometheus e Grafana
- script de backup inicial
- runbook e checklists iniciais

### Nao concluido em infraestrutura real
- provisionamento das VPSs
- OpenClaw real em producao
- Postal real em producao
- DNS/TLS final
- FBR-Click real
- homologacao ponta a ponta
- carga real e handoff operacional final

## 3. Dependencias externas obrigatorias

### Ja definidas
- Supabase Cloud como banco principal
- LLM server externo com Ollama

### Ainda dependentes de criacao/implantacao
- VPS1
- VPS2
- VPS3
- Postal real
- FBR-Click real
- dominios finais e certificados TLS

## 4. Batch por Batch

---

## Batch 1 - Fundacao

### Objetivo
Colocar a infraestrutura minima necessaria para o sistema existir com separacao adequada entre aplicacao, agentes, mail server e LLM.

### O que ja foi feito
- estrutura de projeto criada
- `docker-compose.yml` base criado
- `Dockerfile` do backend criado
- `.env.example` criado
- `nginx/default.conf` inicial criado
- health checks basicos preparados

### O que falta fazer
- provisionar VPS1, VPS2 e VPS3
- instalar Docker e Docker Compose plugin nas VPSs
- instalar Tailscale nas VPSs
- conectar VPSs e LLM server na mesma tailnet
- validar conectividade entre VPS1 e LLM server
- configurar dominio final do sistema
- configurar TLS real com certificados validos
- subir os servicos base na VPS1

### Dependencias externas
- acesso ao provedor de VPS
- acesso ao DNS do dominio
- acesso ao LLM server

### Critério de conclusao
Batch 1 so pode ser considerado concluido quando:
- todas as VPSs estiverem provisionadas
- Docker e Tailscale estiverem funcionando em cada host necessario
- o backend responder em dominio real com TLS valido
- o LLM server responder pela rede privada

### Bloqueios atuais
- VPSs ainda nao provisionadas
- DNS/TLS final ainda nao configurados

---

## Batch 2 - Database

### Objetivo
Garantir schema, isolamento, triggers e indexes no banco principal.

### O que ja foi feito
- migrations SQL escritas
- schema principal modelado
- RLS configurado no codigo SQL
- triggers e cron configurados no SQL
- indexes adicionados
- seed inicial adicionado

### O que falta fazer
- validar a estrategia final de execucao das migrations no ambiente de producao
- validar compatibilidade exata com Supabase Cloud
- confirmar se `pg_cron` sera usado localmente, no banco gerenciado ou substituido por job externo
- testar migrations em banco final vazio
- testar seed em ambiente real de homologacao

### Dependencias externas
- Supabase Cloud configurado
- decisao operacional sobre cron e jobs

### Critério de conclusao
Batch 2 so pode ser considerado concluido quando:
- migrations executarem com sucesso no banco final
- schema estiver visivel e valido
- policies estiverem efetivamente aplicadas
- seed de homologacao estiver funcional

### Bloqueios atuais
- banco final precisa ser validado com as migrations reais
- estrategia final de cron precisa ser confirmada

---

## Batch 3 - Backend Core

### Objetivo
Entregar a API principal do sistema com autenticacao, dominios, leads, campanhas, webhooks e trilha de auditoria.

### O que ja foi feito
- app factory do FastAPI pronta
- seguranca por `X-Agent-Id` e `X-Workspace-Id`
- rotas de domains
- rotas de leads
- rotas de campaigns
- webhooks Postal e FBR-Click com HMAC
- intelligence report endpoint inicial
- action logger append-only
- payload inicial de handoff SQL

### O que falta fazer
- homologar rotas em ambiente com banco e servicos reais
- integrar writer real com Claude quando a camada final for ligada
- sofisticar dispatcher com regras mais proximas do PRD
- testar webhooks reais
- confirmar tempos de resposta e comportamento assincrono em carga real
- expandir possiveis rotas ainda simplificadas de ICP, logs e intelligence generation

### Dependencias externas
- Supabase Cloud funcional
- FBR-Click real
- Postal real
- LLMs reais

### Critério de conclusao
Batch 3 so pode ser considerado concluido quando:
- API estiver implantada na VPS1
- endpoints responderem no dominio real
- webhooks validarem com servicos reais
- logs de auditoria forem gerados em fluxo real

### Bloqueios atuais
- falta homologacao real de integracoes
- parte do comportamento ainda esta simplificada para scaffold

---

## Batch 4 - OpenClaw Agents

### Objetivo
Ter a camada de agentes operando com repositorios versionados, gateway real e registro operacional.

### O que ja foi feito
- scaffold do gateway local criado
- oito repositorios base de agentes criados
- todos com os 7 markdowns obrigatorios

### O que falta fazer
- implantar o OpenClaw real na VPS2
- substituir o scaffold pelo gateway oficial/real
- registrar agentes no ecossistema operacional real
- expandir dos repositorios base para cobertura completa dos 13 agentes descritos no PRD
- definir owners humanos por agente
- documentar limites de aprovacao reais por agente
- validar heartbeat, kill switch e operacao assistida
- conectar agentes ao FBR-Click real

### Dependencias externas
- VPS2 provisionada
- OpenClaw real disponivel
- FBR-Click real criado

### Critério de conclusao
Batch 4 so pode ser considerado concluido quando:
- gateway real estiver no ar na VPS2
- os 13 agentes previstos estiverem definidos e registrados
- limites de aprovacao estiverem documentados
- kill switch estiver operacional
- heartbeat e logs reais estiverem funcionando

### Bloqueios atuais
- FBR-Click ainda nao existe
- OpenClaw real ainda nao foi implantado
- operacao final dos 13 agentes ainda nao foi refinada

---

## Batch 5 - Postal + Aquecimento

### Objetivo
Subir a camada de envio real e iniciar aquecimento de dominios com seguranca.

### O que ja foi feito
- webhooks do Postal ja estao previstos no backend
- variaveis de ambiente do Postal ja estao mapeadas

### O que falta fazer
- instalar Postal na VPS3
- definir hostname publico do Postal
- gerar `POSTAL_API_KEY`
- gerar `POSTAL_WEBHOOK_SECRET`
- cadastrar dominios de envio
- configurar SPF
- configurar DKIM
- configurar DMARC
- validar os registros DNS
- conectar webhooks do Postal ao backend
- iniciar fase 1 de aquecimento
- definir alertas por bounce alto

### Dependencias externas
- VPS3 provisionada
- dominio e DNS controlados
- certificados TLS validos
- contas e dominios de email reais

### Critério de conclusao
Batch 5 so pode ser considerado concluido quando:
- painel do Postal estiver acessivel
- API do Postal responder com chave real
- DNS do mail server estiver validado
- webhooks chegarem ao backend
- aquecimento fase 1 estiver iniciado em dominio real

### Bloqueios atuais
- Postal ainda nao implantado
- DNS de email ainda nao configurado
- dominios de envio ainda nao aquecidos

---

## Batch 6 - Frontend Dashboard

### Objetivo
Entregar o dashboard operacional do FBR-Leads com sessao protegida e consumo do backend via proxy.

### O que ja foi feito
- frontend separado em `frontend/`
- Next.js 15 configurado
- TypeScript strict configurado
- `iron-session` configurado
- middleware de protecao configurado
- proxy `/api/proxy` configurado
- paginas base do dashboard implementadas
- ligacao inicial com endpoints reais do backend
- `typecheck` validado
- `build` validado
- Dockerfile do frontend criado

### O que falta fazer
- subir o frontend de producao na VPS1
- validar cookies em dominio real
- validar proxy atraves do Nginx com backend real
- evoluir componentes visuais finais conforme design system completo
- adicionar tempo real real onde o PRD pede WebSocket/SSE nas telas finais

### Dependencias externas
- VPS1 provisionada
- dominio real apontando para Nginx
- backend real no ar

### Critério de conclusao
Batch 6 so pode ser considerado concluido quando:
- frontend responder no dominio real
- login funcionar em producao
- proxy entregar dados reais do backend
- telas principais carregarem dados reais sem falhas

### Bloqueios atuais
- falta deploy/homologacao real em VPS1

---

## Batch 7 - Integracao FBR-Click

### Objetivo
Entregar SQLs ao FBR-Click e receber feedback do comercial para retroalimentar o sistema.

### O que ja foi feito
- rota dedicada de handoff SQL criada
- payload de handoff estruturado conforme PRD
- envio HTTP assincrono para o endpoint do FBR-Click preparado
- feedback `deal.won/lost` enriquecendo inteligencia implementado no backend

### O que falta fazer
- criar o projeto FBR-Click
- definir `FBR_CLICK_API_URL` real
- gerar `FBR_CLICK_WEBHOOK_SECRET` real
- criar o canal `#leads-qualificados`
- registrar Cadenciador Bot
- validar retorno real de `deal_id`
- validar ponta a ponta do fluxo de deal criado
- publicar relatorios no canal real

### Dependencias externas
- FBR-Click existir
- canal de leads existir
- bots/agentes registrados no ecossistema real

### Critério de conclusao
Batch 7 so pode ser considerado concluido quando:
- o FBR-Click estiver no ar
- o handoff SQL criar deals reais
- o vendedor receber contexto completo no canal certo
- feedback `deal.won/lost` atualizar inteligencia em fluxo real

### Bloqueios atuais
- FBR-Click ainda nao foi criado

---

## Batch 8 - Producao e Entrega

### Objetivo
Fechar monitoramento, backup, validacao operacional, resiliencia e handoff final.

### O que ja foi feito
- Prometheus no compose
- Grafana no compose
- provisionamento inicial do Grafana
- dashboard inicial do Grafana
- script inicial de backup
- runbook operacional criado
- checklist de deploy criado

### O que falta fazer
- subir Grafana e Prometheus na VPS1
- validar dashboards e datasources em runtime
- executar backup real com credenciais/ambiente corretos
- executar restore real em ambiente isolado
- criar rotina agendada de backup no servidor
- executar teste de carga de 1000 leads
- validar fallback real Ollama -> Claude -> GPT-4o
- registrar evidencias operacionais
- produzir handoff final para o time

### Dependencias externas
- VPS1 provisionada
- stack real no ar
- credenciais finais configuradas
- FBR-Click e Postal reais para testes ponta a ponta

### Critério de conclusao
Batch 8 so pode ser considerado concluido quando:
- monitoring estiver operacional
- backup e restore estiverem testados
- carga de homologacao estiver aprovada
- fallback LLM estiver comprovado
- handoff operacional final estiver documentado e aprovado

### Bloqueios atuais
- falta infraestrutura real
- falta teste de carga real
- falta validacao operacional completa

## 5. Variaveis e sistemas externos ainda pendentes

### Ja podem ser consideradas definidas
- Supabase Cloud
- LLM server com Ollama

### Dependem de criacao futura
- `POSTAL_API_URL`
- `POSTAL_API_KEY`
- `POSTAL_WEBHOOK_SECRET`
- `FBR_CLICK_API_URL`
- `FBR_CLICK_WEBHOOK_SECRET`
- `FBR_CLICK_CHANNEL_LEADS`
- `OPENCLAW_WORKSPACE_ID` final real

## 6. Ordem recomendada de execucao daqui para frente

1. Provisionar VPS1, VPS2 e VPS3.
2. Ajustar dominios e DNS reais.
3. Subir a stack da VPS1.
4. Implantar o OpenClaw real na VPS2.
5. Implantar o Postal real na VPS3.
6. Criar o FBR-Click.
7. Validar handoff SQL real.
8. Executar homologacao completa.
9. Executar go-live controlado.

## 7. Definicao honesta do status do projeto

### O que ja existe de verdade
- base tecnica forte
- codigo principal de backend e frontend pronto para evolucao
- deploy distribuido mapeado
- observabilidade e backup bootstrapados
- integracao do FBR-Click desenhada e parcialmente implementada

### O que ainda nao existe de verdade
- infraestrutura final online
- OpenClaw real em producao
- Postal real em producao
- FBR-Click real
- homologacao final
- go-live

## 8. Documentos complementares neste repositorio

- `tasklist.md`
- `CHECKLIST_DEPLOY.md`
- `DEPLOY_SERVER.md`
- `docs-runbook.md`

Este documento deve ser tratado como o plano consolidado final do FBR-Leads ate a criacao e integracao do FBR-Click real.
