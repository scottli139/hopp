import { Page, Locator } from '@playwright/test';

export class RequestPage {
  readonly page: Page;
  readonly urlInput: Locator;
  readonly methodSelect: Locator;
  readonly sendButton: Locator;
  readonly responseStatus: Locator;

  constructor(page: Page) {
    this.page = page;
    this.urlInput = page.locator('[data-testid="url-input"]');
    this.methodSelect = page.locator('[data-testid="method-select"]');
    this.sendButton = page.locator('[data-testid="send-button"]');
    this.responseStatus = page.locator('[data-testid="response-status"]');
  }

  async setUrl(url: string): Promise<void> {
    await this.urlInput.fill(url);
  }

  async clickSend(): Promise<void> {
    await this.sendButton.click();
  }
}
