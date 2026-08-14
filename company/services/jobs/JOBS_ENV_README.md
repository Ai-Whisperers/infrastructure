# Environment Configuration for Jobs Service

## Important: No Local .env File Needed!

This service reads environment variables from the **ROOT .env file** (two levels up).

## Setup

1. Navigate to the project root:
   ```bash
   cd ../..  # From services/jobs/ to root
   ```

2. Create .env from template:
   ```bash
   cp .env.example .env
   ```

3. Edit the ROOT .env file with your actual values

4. Return to jobs service and run:
   ```bash
   cd services/jobs
   npm run dev
   ```

## How It Works

The `app.module.ts` ConfigModule is configured to read:
```typescript
envFilePath: [
  '../../../.env',        // ROOT .env (primary)
  '../../../.env.local',  // ROOT .env.local (overrides)
  '.env',                 // LOCAL .env (not recommended)
]
```

## DO NOT create services/jobs/.env

All configuration should be in the ROOT .env file to maintain a single source of truth across all services (jobs, dashboard, scripts).

## Required Variables

See ROOT `.env.example` for the complete list. Key variables for jobs service:
- `GITHUB_TOKEN`
- `DATABASE_URL`
- `REDIS_HOST` / `REDIS_PORT`
- `JOBS_PORT`
- `NODE_ENV`

## Troubleshooting

**Problem**: Service can't find environment variables
- **Solution**: Ensure ROOT .env exists (not services/jobs/.env)

**Problem**: Wrong database path
- **Solution**: Set `DATABASE_URL=file:./services/jobs/dev.db` in ROOT .env

**Problem**: Port conflicts
- **Solution**: Check `JOBS_PORT` in ROOT .env (should be 4000)
