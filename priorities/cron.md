# Cron Jobs — 22 Active

All use `claude-sonnet-4` via OpenRouter on the same VPS.

## Solstein Pipeline (16 jobs)
Every 3 hours: RED-GREEN shift (fix tests), then 5 min later FEATURE shift (implement features).

| Job | Schedule | Type | Status |
|-----|----------|------|--------|
| sol-rg-00 | 00:00 | RED-GREEN | ERROR |
| sol-rg-03 | 03:00 | RED-GREEN | ERROR |
| sol-rg-06 | 06:00 | RED-GREEN | ERROR |
| sol-rg-09 | 09:00 | RED-GREEN | ERROR |
| sol-rg-12 | 12:00 | RED-GREEN | ERROR |
| sol-rg-15 | 15:00 | RED-GREEN | ERROR |
| sol-rg-18 | 18:00 | RED-GREEN | ERROR |
| sol-rg-21 | 21:00 | RED-GREEN | ERROR |
| sol-ft-00 | 00:05 | FEATURE | ERROR |
| sol-ft-03 | 03:05 | FEATURE | ERROR |
| sol-ft-06 | 06:05 | FEATURE | ERROR |
| sol-ft-09 | 09:05 | FEATURE | ERROR |
| sol-ft-12 | 12:05 | FEATURE | ERROR |
| sol-ft-15 | 15:05 | FEATURE | ERROR |
| sol-ft-18 | 18:05 | FEATURE | ERROR |
| sol-ft-21 | 21:05 | FEATURE | ERROR |

## Incident Commander (3 jobs)
| Job | Schedule | Purpose | Status |
|-----|----------|---------|--------|
| ic-health-check | Every 5 min | CPU/mem/disk | ERROR |
| ic-hourly-audit | Every hour | Full system audit | ERROR |
| ic-morning-briefing | Daily 08:00 | Daily summary | ERROR |

## Business (1 job)
| Job | Schedule | Purpose | Status |
|-----|----------|---------|--------|
| lead-scout-weekly | Mon 08:00 | Weekly lead scan → WhatsApp | ERROR |

## Planning & Metrics (2 jobs)
| Job | Schedule | Purpose | Status |
|-----|----------|---------|--------|
| sol-planning | Sun 02:00 | Weekly planning | ERROR |
| sol-metrics | Sun 08:00 | Weekly health report | ERROR |
