# 自动化测试方案

## 测试目标

| 指标 | 目标值 |
|------|--------|
| 单元测试覆盖率 | ≥ 80% |
| 集成测试覆盖率 | ≥ 60% |
| E2E 测试通过率 | 100% |
| 测试执行时间 | < 5 min |

## 测试分层

```
┌─────────────────────────────────────────┐
│  E2E Tests (Playwright)                 │
│  - 用户场景测试                          │
│  - 跨平台测试                            │
├─────────────────────────────────────────┤
│  Integration Tests                      │
│  - 组件测试 (Vitest + RTL)              │
│  - 后端集成测试 (Rust)                  │
├─────────────────────────────────────────┤
│  Unit Tests                             │
│  - 前端: Vitest                         │
│  - 后端: cargo test                     │
└─────────────────────────────────────────┘
```

## 前端单元测试

```typescript
// src/utils/variableResolver.test.ts
import { describe, it, expect } from 'vitest';
import { resolveVariables } from './variableResolver';

describe('resolveVariables', () => {
  it('should replace simple variables', () => {
    const result = resolveVariables('{{url}}/users', { url: 'api.example.com' });
    expect(result).toBe('api.example.com/users');
  });
});
```

## 后端单元测试

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_url() {
        let result = parse_url("https://example.com");
        assert!(result.is_ok());
    }
}
```

## E2E 测试

```typescript
// e2e/tests/request.spec.ts
test('should send a GET request', async ({ page }) => {
  await page.goto('http://localhost:1420');
  await page.fill('[data-testid="url-input"]', 'https://httpbin.org/get');
  await page.click('[data-testid="send-button"]');
  await expect(page.locator('[data-testid="response-status"]')).toContainText('200');
});
```
