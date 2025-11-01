import type { Page } from "rebrowser-playwright";
import { config, selectors } from "../config";
import { logger } from "../utils/logger";

export class AuthService {
  constructor(private page: Page) {}

  async acceptCookies(): Promise<void> {
    try {
      logger.step("Waiting for cookie banner...");
      const acceptCookiesButton = await this.page.waitForSelector(
        `button#${selectors.cookiesButtonId}`,
        {
          timeout: config.timeout.cookie,
        }
      );
      await acceptCookiesButton.click();
      logger.success("Cookies accepted");
    } catch (error) {
      logger.warn("Cookie banner not found or already accepted");
    }
  }

  async login(): Promise<void> {
    logger.section("Starting Login Process");

    await this.acceptCookies();

    logger.step("Clicking login button...");
    const loginButton = this.page.locator(
      `xpath=//button[contains(@class, '${selectors.loginButtonClassName}')]`
    );
    await loginButton.click();

    logger.step("Filling email...");
    const emailField = this.page.locator("#email");
    await emailField.waitFor({ timeout: config.timeout.selector });
    await emailField.fill(config.email);

    logger.step("Filling password...");
    const passwordField = this.page.locator("#password");
    await passwordField.waitFor({ timeout: config.timeout.selector });
    await passwordField.fill(config.password);

    logger.step("Submitting login form...");
    const confirmLoginButton = this.page.locator(
      `xpath=//button[contains(@class, '${selectors.installButtonClassName}')]`
    );
    await confirmLoginButton.click();

    await this.page.waitForTimeout(3000);
    logger.success("Login completed");
  }
}
