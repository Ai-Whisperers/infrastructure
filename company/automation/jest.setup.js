// Jest setup file for orchestration tests

// Suppress console output during tests (optional)
global.console = {
  ...console,
  // Keep log/error for debugging, suppress info/debug
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: console.warn,
  error: console.error,
};

// Set test timeout
jest.setTimeout(10000);

// Mock file system operations if needed
jest.mock('fs', () => ({
  ...jest.requireActual('fs'),
  // Add mocks if needed
}));

// Clean up after each test
afterEach(() => {
  jest.clearAllMocks();
});
