import { Controller, Get } from '@nestjs/common';
import { PrismaService } from './db/prisma.service';

@Controller()
export class HealthController {
  private startTime = Date.now();

  constructor(private prisma: PrismaService) {}

  @Get('health')
  async getHealth() {
    const checks = await this.performHealthChecks();
    const isHealthy = checks.database && checks.memory;

    return {
      status: isHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      service: 'org-os-jobs',
      version: '0.1.0',
      uptime: Math.floor((Date.now() - this.startTime) / 1000),
      checks,
    };
  }

  @Get('api/health')
  async getApiHealth() {
    return this.getHealth();
  }

  @Get()
  getRoot() {
    return {
      message: 'AI-Whisperers Org OS Jobs Service',
      docs: '/api',
      health: '/health',
      apiHealth: '/api/health',
    };
  }

  private async performHealthChecks() {
    const memoryUsage = process.memoryUsage();
    const memoryUsageMB = {
      rss: Math.round(memoryUsage.rss / 1024 / 1024),
      heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024),
      heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024),
      external: Math.round(memoryUsage.external / 1024 / 1024),
    };

    // Check database connection
    let databaseStatus = false;
    let databaseError: string | null = null;
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      databaseStatus = true;
    } catch (error) {
      databaseError = error.message;
    }

    // Memory health check (unhealthy if using > 512MB heap)
    const memoryHealthy = memoryUsageMB.heapUsed < 512;

    return {
      database: databaseStatus,
      databaseError,
      memory: memoryHealthy,
      memoryUsage: memoryUsageMB,
      environment: process.env.NODE_ENV || 'development',
      nodeVersion: process.version,
    };
  }
}