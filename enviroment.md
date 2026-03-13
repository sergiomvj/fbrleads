# DATABASE
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=REMOVIDO
DATABASE_URL=postgresql://postgres:REMOVIDO@db.bihawleooakpksfslrrc.supabase.co:5432/postgres
DATABASE_URL_ASYNCPG=postgres://postgres:REMOVIDO@db.bihawleooakpksfslrrc.supabase.co:6543/postgres
SUPABASE_URL=https://bihawleooakpksfslrrc.supabase.co
SUPABASE_ANON_KEY=REMOVIDO
SUPABASE_SERVICE_ROLE_KEY=REMOVIDO
REDIS_URL=redis://redis:6379/0

# LLM LAYER 1
OLLAMA_BASE_URL=http://192.168.60.104:8080/ # temos um ollama local
OLLAMA_MODEL=qwen2.5-coder:latest # temos o qwen2.5-coder:latest instalado localmente
OLLAMA_TIMEOUT_SECONDS=15

# LLM LAYER 2
OPENAI_API_KEY=sk-REMOVIDO
OPENAI_MODEL=gpt-4o
OPENAI_TIMEOUT_SECONDS=30

# LLM LAYER 3
ANTHROPIC_API_KEY=sk-ant-REMOVIDO
ANTHROPIC_MODEL=claude-sonnet-4-6
ANTHROPIC_TIMEOUT_SECONDS=30


# EXTERNAL INTEGRATIONS
ZEROBOUNCE_API_KEY=REMOVIDO
APIFY_API_TOKEN=apify_REMOVIDO
FIRECRAWL_API_KEY=fc-REMOVIDO

# POSTAL
POSTAL_API_URL=https://postal.fbrapps.com/api
POSTAL_API_KEY=
POSTAL_WEBHOOK_SECRET=replace-me

# FBR-CLICK
FBR_CLICK_API_URL=https://click.fbrapps.com/api
FBR_CLICK_WEBHOOK_SECRET=replace-me
FBR_CLICK_CHANNEL_LEADS=chn_replace_me

# OPENCLAW
OPENCLAW_GATEWAY_URL=http://openclaw.fbrapps.com # OPENCLAW_WORKSPACE_ID=ws_replace_me

# DASHBOARD
SESSION_SECRET=replace-with-64-char-secret
BACKEND_URL=http://fastapi:8000
APP_ENV=development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost
DASHBOARD_EMAIL=info@fbrapps.com
DASHBOARD_PASSWORD=TeamFBR1234@
DASHBOARD_USER_ID=owner-facebrasil
DASHBOARD_WORKSPACE_ID=10000000-0000-0000-0000-000000000001

# NGINX / DOMAIN
APP_DOMAIN=leads.fbr.internal
TLS_CERT_PATH=/etc/letsencrypt/live/leads.fbr.internal/fullchain.pem
TLS_KEY_PATH=/etc/letsencrypt/live/leads.fbr.internal/privkey.pem

# N8N
N8N_HOST=localhost
N8N_WEBHOOK_URL=http://localhost:5678/
