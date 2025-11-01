import playwright, { type BrowserContext, type Page } from "rebrowser-playwright";
import { config } from "../config";
import { logger } from "../utils/logger";

export class BrowserService {
  private context: BrowserContext | null = null;
  private page: Page | null = null;

  async launch(userDataDir: string): Promise<void> {
    logger.info("Starting the Playwright browser with persistent context");

    this.context = await playwright.chromium.launchPersistentContext(
      userDataDir,
      {
        headless: config.headless,
        viewport: config.viewport,
        userAgent:
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        args: [
          "--no-sandbox",
          "--mute-audio",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
          "--disable-blink-features=AutomationControlled",
          "--ignore-certificate-errors",
          "--ignore-certificate-errors-spki-list",
          "--ignore-ssl-errors",
        ],
      }
    );

    this.page = this.context.pages()[0] || (await this.context.newPage());

    this.page.on("pageerror", (error) => {
      logger.error("Page error:", error);
    });

    this.page.on("crash", () => {
      logger.error("Page crashed!");
    });

    logger.success("Browser launched successfully");
  }

  getPage(): Page {
    if (!this.page) {
      throw new Error("Browser not launched. Call launch() first.");
    }
    return this.page;
  }

  async close(): Promise<void> {
    if (this.context) {
      logger.info("Closing browser...");
      await this.context.close();
      logger.success("Browser closed");
    }
  }
}
