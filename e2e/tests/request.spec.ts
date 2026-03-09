import { test, expect } from '@playwright/test';
import { RequestPage } from '../pages/RequestPage';

test('should send a GET request', async ({ page }) => {
  const requestPage = new RequestPage(page);
  
  await page.goto('http://localhost:1420');
  await requestPage.setUrl('https://httpbin.org/get');
  await requestPage.clickSend();
  
  await expect(requestPage.responseStatus).toContainText('200');
});
