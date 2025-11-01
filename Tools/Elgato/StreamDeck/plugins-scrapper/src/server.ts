import playwright from "rebrowser-playwright";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import {
  cookiesButtonId,
  installPluginOrConfirmLoginButtonsClassName,
  loginButtonClassName,
  pluginNameClassName,
  URLs,
} from "./constants";

(async () => {
  if (!process.env.EMAIL) {
    console.error("Please provide an email address in process.env");
    process.exit(1);
  }
  if (!process.env.PASSWORD) {
    console.error("Please provide a password in process.env");
    process.exit(1);
  }

  const userDataDir = path.join(os.tmpdir(), 'playwright-streamdeck-' + Date.now());
  const preferencesDir = path.join(userDataDir, 'Default');
  fs.mkdirSync(preferencesDir, { recursive: true });
  
  const preferencesSourcePath = path.join(__dirname, 'context', 'Preferences');
  const preferencesDestPath = path.join(preferencesDir, 'Preferences');
  fs.copyFileSync(preferencesSourcePath, preferencesDestPath);
  
  console.info(`UserData directory created at: ${userDataDir}`);
  console.info("Starting the Playwright browser with persistent context");
  
  const context = await playwright.chromium.launchPersistentContext(userDataDir, {
    headless: process.env.HEADLESS !== 'false',
    viewport: { width: 1200, height: 800 },
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    args: [
        '--no-sandbox',
        '--mute-audio',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-blink-features=AutomationControlled',
        '--ignore-certificate-errors',
        '--ignore-certificate-errors-spki-list',
        '--ignore-ssl-errors'
    ]
  });

  const page = context.pages()[0] || await context.newPage();
  
  page.on('pageerror', error => {
    console.error('Page error:', error);
  });
  
  page.on('crash', () => {
    console.error('Page crashed!');
  });

  console.info("Navigating to Elgato Marketplace...");
  await page.goto("https://marketplace.elgato.com/", { 
    waitUntil: 'domcontentloaded',
    timeout: 30000 
  });

  async function acceptCookies() {
    try {
      console.info("Waiting for cookie banner...");
      const acceptCookiesButton = await page.waitForSelector(`button#${cookiesButtonId}`, {
        timeout: 10000,
      });
      await acceptCookiesButton.click();
      console.info("Cookies accepted");
    } catch (error) {
      console.warn("Cookie banner not found or already accepted");
    }
  }

  async function login() {
    await acceptCookies();

    console.info("Clicking login button...");
    const loginButton = page.locator(`xpath=//button[contains(@class, '${loginButtonClassName}')]`);
    await loginButton.click();
    
    console.info("Filling email...");
    const emailField = page.locator('#email');
    await emailField.waitFor({ timeout: 10000 });
    await emailField.fill(process.env.EMAIL!);
    
    console.info("Filling password...");
    const passwordField = page.locator('#password');
    await passwordField.waitFor({ timeout: 10000 });
    await passwordField.fill(process.env.PASSWORD!);
    
    console.info("Submitting login form...");
    const confirmLoginButton = page.locator(`xpath=//button[contains(@class, '${installPluginOrConfirmLoginButtonsClassName}')]`);
    await confirmLoginButton.click();
    
    await page.waitForTimeout(3000);
    console.info("Login completed");
  }

  async function scrapPlugin(url: string) {
    console.info(`Navigating to: ${url}`);
    await page.goto(url, { 
      waitUntil: 'domcontentloaded',
      timeout: 30000 
    });
    
    const installPluginButton = page.locator(`xpath=//button[contains(@class, '${installPluginOrConfirmLoginButtonsClassName}')]`).first();

    await installPluginButton.waitFor({ state: 'visible', timeout: 10000 });
    
    console.info("Waiting for 'Open in Stream Deck' button...");
    await page.waitForFunction(
      () => {
        const buttons = Array.from(document.querySelectorAll('button'));
        return buttons.some(btn => btn.innerText.includes('Open in Stream Deck'));
      },
      { timeout: 10000 }
    );
    
    console.info("Clicking install button...");
    await installPluginButton.click();
    
    console.info("Plugin installation triggered, waiting...");
    await page.waitForTimeout(3000);
  }

  try {
    await login();
    console.info(`\nStarting to scrape ${URLs.length} plugins...\n`);
    
    for await (const url of URLs) {
      try {
        await scrapPlugin(url);
      } catch (error) {
        console.error(`Failed to scrape plugin at ${url}:`, error);
      }
    }
    
    console.info("\n✓ All plugins processed!");
  } catch (error) {
    console.error("Fatal error:", error);
  } finally {
    console.info("Closing browser...");
    await context.close();
    
    // Limpar diretório temporário userData
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
      console.info("UserData directory cleaned up");
    } catch (error) {
      console.warn("Failed to clean up userData directory:", error);
    }
  }
})();
