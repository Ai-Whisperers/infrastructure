# Infrastructure Map
## ParaguAI VPS — Docker Swarm Network Architecture

```
Internet
  │
  ▼
Cloudflare (DNS + proxy for *.paragu-ai.com)
  │
  ▼
Traefik (port 80 → 443 redirect, Let's Encrypt SSL)
  │
  ▼
  ├── paragu-ai-builder (3x)  → paragu-ai.com
  │
  ├── Client Sites (2x each)
  │   ├── dayah.paragu-ai.com
  │   ├── viajero.paragu-ai.com
  │   ├── nexa.paragu-ai.com
  │   ├── nudo.paragu-ai.com
  │   ├── ozmontania.paragu-ai.com
  │   ├── fun4me.paragu-ai.com
  │   ├── superspuma.paragu-ai.com
  │   ├── goldenvisa.paragu-ai.com
  │   ├── cabral.paragu-ai.com
  │   ├── duerksen.paragu-ai.com
  │   ├── mant ra-spa.paragu-ai.com
  │   ├── magnolia-peluqueria.paragu-ai.com
  │   ├── maiyu.paragu-ai.com
  │   ├── villamayor.paragu-ai.com
  │   ├── 30vcs.paragu-ai.com
  │   ├── brahm.paragu-ai.com
  │   └── nicolas-duarte.paragu-ai.com
  │
  ├── space.sunstein.cloud (Space Agent)
  ├── gyro.sunstein.cloud (Gyro)
  │
  └── Postgres (shared DB)
```

## Monitoring Stack
```
node-exporter → Prometheus → Grafana (?)
Hermes IC (every 5 min checks) → ~/.hermes/incidents/
```

## Build Pipeline
```
paragu-ai-builder → builds static sites → /root/sites/{client}/
                  → Docker builds per client → Docker Swarm deploy
```
