import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS for dashboard
  app.enableCors({
    origin: process.env.DASHBOARD_URL || 'http://localhost:3001',
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('AI-Whisperers Org OS Jobs API')
    .setDescription('Backend job service for repository management')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  const port = process.env.JOBS_PORT || 4000;
  await app.listen(port);
  console.log(`🚀 Jobs service running on http://localhost:${port}`);
  console.log(`📚 API documentation: http://localhost:${port}/api`);
}

bootstrap();