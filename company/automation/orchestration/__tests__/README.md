# Orchestration System Tests

This directory contains comprehensive tests for the multi-agent orchestration system.

## Test Structure

```
__tests__/
├── core/__tests__/              # Unit tests for core components
│   ├── plugin-loader.spec.ts    # Plugin loading and management
│   ├── agent-executor.spec.ts   # Agent execution engine
│   ├── workflow-runner.spec.ts  # Workflow orchestration
│   └── orchestrator.spec.ts     # Main orchestrator
└── workflows/__tests__/         # Integration tests
    └── integration.spec.ts      # End-to-end workflow tests
```

## Running Tests

### All Tests
```bash
cd automation
npm test
```

### Unit Tests Only
```bash
npm run test:unit
```

### Integration Tests Only
```bash
npm run test:integration
```

### Watch Mode (Development)
```bash
npm run test:watch
```

### Coverage Report
```bash
npm run test:coverage
```

### CI Mode
```bash
npm run test:ci
```

## Test Coverage

Current coverage targets:
- **Branches:** 70%
- **Functions:** 70%
- **Lines:** 70%
- **Statements:** 70%

## Writing Tests

### Unit Test Example

```typescript
import { PluginLoader } from '../plugin-loader';

describe('PluginLoader', () => {
  let pluginLoader: PluginLoader;

  beforeEach(() => {
    pluginLoader = new PluginLoader('./config');
  });

  it('should load plugins', async () => {
    const results = await pluginLoader.loadPlugins();
    expect(results.length).toBeGreaterThan(0);
  });
});
```

### Integration Test Example

```typescript
import { orchestrator } from '../../core/orchestrator';

describe('Workflow Integration', () => {
  beforeAll(async () => {
    // Register mock services
    orchestrator.registerService('github.service', mockService);
    await orchestrator.initialize();
  });

  it('should execute workflow', async () => {
    const result = await orchestrator.runWorkflow('weekly-org-pulse');
    expect(result.success).toBe(true);
  });
});
```

## Test Files

### Core Components (Unit Tests)

#### plugin-loader.spec.ts
Tests for dynamic plugin loading:
- Loading all enabled plugins
- Loading specific plugins on demand
- Agent registration
- Plugin unloading
- Statistics gathering

#### agent-executor.spec.ts
Tests for agent execution:
- Service registration
- Agent execution with context
- Parallel execution
- Sequential execution with dependencies
- Error handling
- Capability mapping

#### workflow-runner.spec.ts
Tests for workflow orchestration:
- Workflow loading
- Workflow execution
- Phase-based execution
- Dependency management
- Output generation
- Trigger types

#### orchestrator.spec.ts
Tests for main orchestrator:
- System initialization
- Service registration
- Workflow execution
- Agent execution
- Plugin management
- Health checks
- Statistics

### Integration Tests

#### integration.spec.ts
End-to-end workflow tests:
- Weekly Org Pulse workflow
- Compliance Audit workflow
- PR Quality Gate workflow
- ADO Sync Cycle workflow
- Multi-workflow scenarios
- Error handling
- Performance validation

## Mocking Strategy

### Services
All NestJS services are mocked using Jest mocks:

```typescript
const mockService = {
  calculateHealthScore: jest.fn().mockResolvedValue({ score: 85 }),
  detectStalePRs: jest.fn().mockResolvedValue({ stalePRs: [] }),
};

orchestrator.registerService('github.service', mockService);
```

### File System
Configuration files are read from actual JSON files to ensure schema validation.

## Coverage Goals

- **Core Components:** 80%+ coverage
- **Integration Tests:** Cover all 4 workflows
- **Error Scenarios:** Test failure paths
- **Performance:** Validate SLOs

## CI Integration

Tests run automatically in CI:

```yaml
- name: Run Orchestration Tests
  run: |
    cd automation
    npm install
    npm run test:ci
```

## Troubleshooting

### Tests Failing

1. **Config files not found:**
   ```bash
   # Ensure you're in the automation directory
   cd automation
   npm test
   ```

2. **Module resolution errors:**
   ```bash
   # Clear jest cache
   npx jest --clearCache
   ```

3. **Timeout errors:**
   ```bash
   # Increase timeout in jest.config.js
   testTimeout: 30000
   ```

### Coverage Issues

1. **Low coverage:**
   - Check `coverage/lcov-report/index.html` for details
   - Add tests for uncovered branches

2. **Ignore files:**
   - Update `collectCoverageFrom` in jest.config.js

## Best Practices

1. **Descriptive test names:** Use clear, action-oriented names
2. **Arrange-Act-Assert:** Follow AAA pattern
3. **Mock external dependencies:** Don't call real APIs
4. **Test edge cases:** Include error scenarios
5. **Keep tests fast:** Unit tests < 100ms, integration < 1s
6. **Clean up:** Reset mocks after each test

## Next Steps

- [ ] Add performance benchmarks
- [ ] Add snapshot testing for outputs
- [ ] Add contract tests for service interfaces
- [ ] Increase coverage to 85%+
- [ ] Add mutation testing

---

**Last Updated:** 2025-10-24
**Maintained By:** AI-Whisperers Platform Team
