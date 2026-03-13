# Runbook de Operacao

## Monitoring

- Grafana: `http://localhost:3001`
- Prometheus: `http://localhost:9090`
- Health checks bootstrapados para `fastapi` e `openclaw-gateway`

## Backup

- Script: `scripts/backup.ps1`
- Requer `pg_dump` disponivel no PATH local
- Usa `POSTGRES_DB`, `POSTGRES_USER` e `POSTGRES_PASSWORD` do ambiente atual

## Restauracao basica

1. Criar banco vazio no PostgreSQL de destino.
2. Executar `psql -h localhost -U <user> -d <db> -f <arquivo.sql>`.
3. Validar tabelas e contagens principais.

## Checks manuais de entrega

- `docker compose config`
- `python -m compileall app`
- `cd frontend && npm run typecheck`
- `cd frontend && npm run build`
