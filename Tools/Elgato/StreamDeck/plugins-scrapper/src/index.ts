import { config, pluginURLs } from "./config";
import { logger } from "./utils/logger";
import { FileSystemHelper } from "./utils/filesystem";
import { BrowserService } from "./services/BrowserService";
import { AuthService } from "./services/AuthService";
import { PluginScraperService } from "./services/PluginScraperService";

async function main() {
  if (!config.email) {
    logger.error("Please provide an email address in process.env.EMAIL");
    process.exit(1);
  }
  if (!config.password) {
    logger.error("Please provide a password in process.env.PASSWORD");
    process.exit(1);
  }

  let userDataDir = "";

  try {
    userDataDir = FileSystemHelper.setupUserDataDir();

    const browserService = new BrowserService();
    await browserService.launch(userDataDir);
    const page = browserService.getPage();

    logger.info("Navigating to Elgato Marketplace...");
    await page.goto("https://marketplace.elgato.com/", {
      waitUntil: "domcontentloaded",
      timeout: config.timeout.navigation,
    });

    const authService = new AuthService(page);
    await authService.login();

    const scraperService = new PluginScraperService(page);
    const results = await scraperService.scrapeMultiple(pluginURLs);

    logger.section("Scraping Results");
    const successful = results.filter((r) => r.success).length;
    const failed = results.filter((r) => !r.success).length;

    logger.success(`Successfully processed: ${successful} plugins`);
    if (failed > 0) {
      logger.error(`Failed to process: ${failed} plugins`);
      results
        .filter((r) => !r.success)
        .forEach((r) => {
          logger.error(`  - ${r.url}: ${r.error}`);
        });
    }

    await browserService.close();
  } catch (error) {
    logger.error("Fatal error:", error);
    process.exit(1);
  } finally {
    if (userDataDir) {
      FileSystemHelper.cleanupUserDataDir(userDataDir);
    }
  }
}

main().catch((error) => {
  logger.error("Unhandled error:", error);
  process.exit(1);
});
