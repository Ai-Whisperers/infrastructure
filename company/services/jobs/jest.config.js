module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.interface.ts',
    '!src/**/*.module.ts',
    '!src/main.ts',
    '!src/**/*.entity.ts',
    '!**/node_modules/**',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 80,
      statements: 80,
    },
  },
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@integrations/(.*)$': '<rootDir>/src/integrations/$1',
    '^@scanners/(.*)$': '<rootDir>/src/scanners/$1',
    '^@reporters/(.*)$': '<rootDir>/src/reporters/$1',
    '^@sync/(.*)$': '<rootDir>/src/sync/$1',
    '^@db/(.*)$': '<rootDir>/src/db/$1',
  },
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
  coverageDirectory: '<rootDir>/coverage',
  testTimeout: 10000,
}