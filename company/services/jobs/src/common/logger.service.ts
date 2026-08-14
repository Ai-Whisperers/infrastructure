import { Injectable, LoggerService as NestLoggerService } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class LoggerService implements NestLoggerService {
  private logDir = path.join(__dirname, '../../../logs');

  constructor() {
    // Create logs directory if it doesn't exist
    if (!fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true });
    }
  }

  log(message: string, context?: string) {
    this.writeLog('INFO', message, context);
    console.log(`[${context || 'App'}] ${message}`);
  }

  error(message: string, trace?: string, context?: string) {
    this.writeLog('ERROR', message, context, trace);
    console.error(`[${context || 'App'}] ${message}`, trace || '');
  }

  warn(message: string, context?: string) {
    this.writeLog('WARN', message, context);
    console.warn(`[${context || 'App'}] ${message}`);
  }

  debug(message: string, context?: string) {
    if (process.env.NODE_ENV !== 'production') {
      this.writeLog('DEBUG', message, context);
      console.debug(`[${context || 'App'}] ${message}`);
    }
  }

  verbose(message: string, context?: string) {
    if (process.env.LOG_LEVEL === 'verbose') {
      this.writeLog('VERBOSE', message, context);
      console.log(`[${context || 'App'}] ${message}`);
    }
  }

  private writeLog(level: string, message: string, context?: string, trace?: string) {
    // Only write to file in production or if explicitly enabled
    if (process.env.NODE_ENV !== 'production' && !process.env.ENABLE_FILE_LOGGING) {
      return;
    }

    const timestamp = new Date().toISOString();
    const contextStr = context ? `[${context}]` : '';
    const logEntry = `${timestamp} [${level}] ${contextStr} ${message}${trace ? `\n${trace}` : ''}\n`;

    // Write to dated log file
    const date = new Date().toISOString().split('T')[0];
    const logFile = path.join(this.logDir, `${date}.log`);

    try {
      fs.appendFileSync(logFile, logEntry);

      // Also write errors to dedicated error log
      if (level === 'ERROR') {
        const errorLog = path.join(this.logDir, `${date}-errors.log`);
        fs.appendFileSync(errorLog, logEntry);
      }
    } catch (err) {
      // Fail silently to not disrupt application
      console.error('Failed to write to log file:', err.message);
    }
  }

  /**
   * Log structured error with additional metadata
   */
  logError(error: Error, context?: string, metadata?: Record<string, any>) {
    const errorDetails = {
      message: error.message,
      stack: error.stack,
      name: error.name,
      ...metadata,
    };

    this.error(
      JSON.stringify(errorDetails, null, 2),
      error.stack,
      context
    );

    // In production, this is where you'd send to Sentry/DataDog/etc.
    if (process.env.SENTRY_DSN) {
      // TODO: Integrate with Sentry
      // Sentry.captureException(error, { contexts: { custom: metadata } });
    }
  }
}
