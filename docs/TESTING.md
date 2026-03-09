# Hopp 自动化测试方案

> 确保代码质量和功能正确性的测试策略与实施指南。

---

## 🎯 测试目标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 单元测试覆盖率 | ≥ 80% | 核心业务逻辑 |
| 集成测试覆盖率 | ≥ 60% | 关键流程 |
| E2E 测试通过率 | 100% | 核心用户场景 |
| 测试执行时间 | < 5 min | CI 流水线 |

---

## 🧪 测试分层

```
┌─────────────────────────────────────────────────────────┐
│  E2E Tests (Playwright)                                 │
│  - 用户场景测试                                          │
│  - 跨平台测试                                            │
│  - 耗时: ~2 min                                         │
├─────────────────────────────────────────────────────────┤
│  Integration Tests                                      │
│  - Frontend: Component Testing (Vitest + RTL)           │
│  - Backend: Integration Tests (Rust)                    │
│  - 耗时: ~1 min                                         │
├─────────────────────────────────────────────────────────┤
│  Unit Tests                                             │
│  - Frontend: Vitest (Utils/Hooks/Stores)                │
│  - Backend: cargo test                                  │
│  - 耗时: ~1 min                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 测试策略

### 1. 单元测试 (Unit Tests)

#### 前端 (Vitest)

**测试范围:**
- 工具函数 (`src/utils/`)
- 自定义 Hooks (`src/hooks/`)
- Store 逻辑 (`src/stores/`)
- 纯函数组件

**文件命名:**
```
src/
├── utils/
│   ├── formatDate.ts
│   └── formatDate.test.ts      # 测试文件
├── hooks/
│   ├── useRequest.ts
│   └── useRequest.test.ts
└── stores/
    ├── requestStore.ts
    └── requestStore.test.ts
```

**示例:**

```typescript
// src/utils/variableResolver.test.ts
import { describe, it, expect } from 'vitest';
import { resolveVariables } from './variableResolver';

describe('resolveVariables', () => {
  it('should replace simple variables', () => {
    const template = 'https://api.{{domain}}.com/users/{{id}}';
    const variables = { domain: 'example', id: '123' };
    
    const result = resolveVariables(template, variables);
    
    expect(result).toBe('https://api.example.com/users/123');
  });
  
  it('should handle missing variables gracefully', () => {
    const template = '{{missing}}';
    const variables = {};
    
    const result = resolveVariables(template, variables);
    
    expect(result).toBe('{{missing}}');
  });
  
  it('should escape special regex characters in values', () => {
    const template = '{{path}}';
    const variables = { path: 'api/v1/users' };
    
    const result = resolveVariables(template, variables);
    
    expect(result).toBe('api/v1/users');
  });
});
```

#### 后端 (Rust)

**测试范围:**
- 业务逻辑函数
- 数据结构序列化/反序列化
- 工具函数

**文件组织:**
```rust
// 内联测试
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_url_with_variables() {
        let url = "https://api.{{domain}}.com/users/{{id}}";
        let vars = vec![
            ("domain".to_string(), "example".to_string()),
            ("id".to_string(), "123".to_string()),
        ];
        
        let result = parse_url_with_variables(url, &vars);
        
        assert_eq!(result, "https://api.example.com/users/123");
    }
}
```

**集成测试:**
```
src-tauri/tests/
├── integration/
│   ├── http_client_tests.rs
│   ├── storage_tests.rs
│   └── mod.rs
└── common/
    ├── mod.rs
    └── test_utils.rs
```

### 2. 集成测试 (Integration Tests)

#### 前端组件测试

**使用:** Vitest + React Testing Library

```typescript
// src/components/request/MethodSelector.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MethodSelector } from './MethodSelector';

describe('MethodSelector', () => {
  it('should render all HTTP methods', () => {
    render(<MethodSelector value="GET" onChange={vi.fn()} />);
    
    expect(screen.getByText('GET')).toBeInTheDocument();
    expect(screen.getByText('POST')).toBeInTheDocument();
    // ...
  });
  
  it('should call onChange when selecting different method', () => {
    const onChange = vi.fn();
    render(<MethodSelector value="GET" onChange={onChange} />);
    
    fireEvent.click(screen.getByText('POST'));
    
    expect(onChange).toHaveBeenCalledWith('POST');
  });
  
  it('should highlight selected method', () => {
    render(<MethodSelector value="POST" onChange={vi.fn()} />);
    
    const postButton = screen.getByText('POST');
    expect(postButton).toHaveClass('bg-blue-600');
  });
});
```

#### 后端集成测试

```rust
// src-tauri/tests/integration/http_client_tests.rs
use hopp::services::HttpClient;
use hopp::models::{HttpRequest, Method};

#[tokio::test]
async fn test_send_get_request() {
    // 启动 mock server
    let mut server = mockito::Server::new_async().await;
    let mock = server.mock("GET", "/test")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body(r#"{"message": "success"}"#)
        .create();
    
    let client = HttpClient::new();
    let request = HttpRequest {
        method: Method::GET,
        url: format!("{}/test", server.url()),
        headers: vec![],
        body: None,
        timeout: Duration::from_secs(5),
    };
    
    let response = client.send(request).await.unwrap();
    
    assert_eq!(response.status, 200);
    mock.assert();
}
```

### 3. E2E 测试 (End-to-End)

**使用:** Playwright + Tauri Driver

**测试范围:**
- 核心用户流程
- 跨平台兼容性
- 性能基准

**测试文件:**
```
e2e/
├── fixtures/
│   └── sample-collection.json
├── tests/
│   ├── auth.setup.ts
│   ├── request.spec.ts
│   ├── collection.spec.ts
│   └── environment.spec.ts
├── pages/
│   ├── RequestPage.ts
│   ├── SidebarPage.ts
│   └── index.ts
└── playwright.config.ts
```

**示例:**

```typescript
// e2e/tests/request.spec.ts
import { test, expect } from '@playwright/test';
import { RequestPage } from '../pages/RequestPage';

test.describe('Request Flow', () => {
  test('should send a GET request and display response', async ({ page }) => {
    const requestPage = new RequestPage(page);
    
    // 1. 打开新标签页
    await requestPage.newTab();
    
    // 2. 输入 URL
    await requestPage.setUrl('https://httpbin.org/get');
    
    // 3. 点击发送
    await requestPage.clickSend();
    
    // 4. 验证响应
    await expect(requestPage.responseStatus).toContainText('200');
    await expect(requestPage.responseBody).toContainText('"url"');
  });
  
  test('should save request to collection', async ({ page }) => {
    const requestPage = new RequestPage(page);
    
    await requestPage.newTab();
    await requestPage.setUrl('https://httpbin.org/post');
    await requestPage.setMethod('POST');
    await requestPage.setBody('{"test": "data"}');
    
    // 保存到集合
    await requestPage.saveToCollection('Test Collection', 'My Request');
    
    // 验证侧边栏显示
    await expect(page.locator('[data-testid="sidebar"]')).toContainText('My Request');
  });
});
```

---

## 🔧 测试工具配置

### 前端测试 (Vitest)

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
      ],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom';
import { vi } from 'vitest';

// Mock Tauri API
global.__TAURI__ = {
  invoke: vi.fn(),
  event: {
    listen: vi.fn(),
  },
};
```

### 后端测试 (Cargo)

```toml
# Cargo.toml [dev-dependencies]
[dev-dependencies]
tokio-test = "0.4"
mockito = "1.0"
tempfile = "3.8"
assert_fs = "1.0"
predicates = "3.0"
```

### E2E 测试 (Playwright)

```typescript
// e2e/playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:1420',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'pnpm tauri dev',
    url: 'http://localhost:1420',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
```

---

## 📊 测试用例设计

### 按模块划分

| 模块 | 单元测试 | 集成测试 | E2E 测试 |
|------|----------|----------|----------|
| HTTP 请求 | ✅ | ✅ | ✅ |
| 集合管理 | ✅ | ✅ | ✅ |
| 环境变量 | ✅ | ✅ | ✅ |
| 历史记录 | ✅ | ✅ | ❌ |
| 导入/导出 | ✅ | ✅ | ✅ |
| WebSocket | ✅ | ✅ | ✅ |
| UI 交互 | ❌ | ✅ | ✅ |

### 核心测试场景

#### HTTP 请求模块

```gherkin
Feature: HTTP Request

  Scenario: Send GET request
    Given a valid GET request to "https://httpbin.org/get"
    When I send the request
    Then I should receive a 200 response
    And the response body should contain JSON data

  Scenario: Send POST request with JSON body
    Given a POST request to "https://httpbin.org/post"
    And the body is '{"key": "value"}'
    When I send the request
    Then I should receive a 200 response
    And the response should echo the request body

  Scenario: Handle timeout
    Given a request with 1ms timeout
    When I send the request to a slow endpoint
    Then I should see a timeout error
```

#### 环境变量模块

```gherkin
Feature: Environment Variables

  Scenario: Replace variables in URL
    Given an environment with variable "baseUrl" = "api.example.com"
    And a request to "https://{{baseUrl}}/users"
    When I send the request
    Then the actual URL should be "https://api.example.com/users"

  Scenario: Switch environments
    Given multiple environments (dev, prod)
    And I'm currently using "dev" environment
    When I switch to "prod" environment
    Then subsequent requests should use "prod" variables
```

---

## 🚀 CI/CD 集成

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  frontend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      
      - name: Install dependencies
        run: pnpm install
      
      - name: Lint
        run: pnpm lint
      
      - name: Type check
        run: pnpm type-check
      
      - name: Unit tests
        run: pnpm test:unit --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  backend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-action@stable
      
      - name: Check formatting
        run: cargo fmt -- --check
      
      - name: Clippy
        run: cargo clippy -- -D warnings
      
      - name: Unit tests
        run: cargo test --lib
      
      - name: Integration tests
        run: cargo test --test '*'
```

---

## 📈 覆盖率报告

### 生成报告

```bash
# 前端
pnpm test:unit --coverage

# 后端
cargo tarpaulin --out Html
```

### 覆盖率阈值

```yaml
# codecov.yml
coverage:
  status:
    project:
      default:
        target: 80%
        threshold: 2%
    patch:
      default:
        target: 80%
```

---

## 🐛 调试技巧

### 前端测试调试

```bash
# 交互式调试
pnpm vitest --reporter=verbose

# 特定测试文件
pnpm vitest src/utils/variableResolver.test.ts

# 带 UI
pnpm vitest --ui
```

### 后端测试调试

```bash
# 显示输出
cargo test -- --nocapture

# 特定测试
cargo test test_parse_url

# 集成测试
cargo test --test integration
```

### E2E 调试

```bash
# headed 模式
pnpm exec playwright test --headed

# 特定测试
pnpm exec playwright test request.spec.ts

# 调试模式
pnpm exec playwright test --debug

# 查看报告
pnpm exec playwright show-report
```

---

## ✅ 测试检查清单

### 新增功能时

- [ ] 编写对应的单元测试
- [ ] 复杂逻辑补充集成测试
- [ ] 用户流程补充 E2E 测试
- [ ] 测试覆盖率不降低
- [ ] 所有测试通过

### PR 提交时

- [ ] 本地测试通过
- [ ] CI 测试通过
- [ ] 覆盖率报告达标
- [ ] 无 flaky tests
