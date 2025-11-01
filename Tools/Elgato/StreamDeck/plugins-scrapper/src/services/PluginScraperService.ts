import type { Page } from "rebrowser-playwright";
import { config, selectors } from "../config";
import { logger } from "../utils/logger";
import type { PluginResult } from "../types";

export class PluginScraperService {
  constructor(private page: Page) {}

  async scrapePlugin(url: string): Promise<PluginResult> {
    try {
      logger.url(url);
      await this.page.goto(url, {
        waitUntil: "domcontentloaded",
        timeout: config.timeout.navigation,
      });

      const installPluginButton = this.page
        .locator(
          `xpath=//button[contains(@class, '${selectors.installButtonClassName}')]`
        )
        .first();

      await installPluginButton.waitFor({
        state: "visible",
        timeout: config.timeout.selector,
      });

      const pluginNameElement = this.page
        .locator(
          `xpath=//h2[contains(@class, '${selectors.pluginNameClassName}')]`
        )
        .first();
      const pluginName = await pluginNameElement.innerText();
      logger.plugin(pluginName);

      logger.step("Waiting for 'Open in Stream Deck' button...");
      await this.page.waitForFunction(
        () => {
          const buttons = Array.from(document.querySelectorAll("button"));
          return buttons.some((btn) =>
            btn.innerText.includes("Open in Stream Deck")
          );
        },
        { timeout: config.timeout.selector }
      );

      logger.step("Clicking install button...");
      await installPluginButton.click();

      logger.step("Plugin installation triggered");
      await this.page.waitForTimeout(3000);

      logger.success(`Plugin "${pluginName}" processed successfully`);

      return {
        url,
        name: pluginName,
        success: true,
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`Failed to scrape plugin:`, errorMessage);

      return {
        url,
        success: false,
        error: errorMessage,
      };
    }
  }

  async scrapeMultiple(urls: string[]): Promise<PluginResult[]> {
    logger.section(`Starting to scrape ${urls.length} plugins`);

    const results: PluginResult[] = [];

    for (const url of urls) {
      const result = await this.scrapePlugin(url);
      results.push(result);
      logger.divider();
    }

    return results;
  }
}
