import { Browser, Builder, By, until } from "selenium-webdriver";
import edge from "selenium-webdriver/edge";
import {
  cookiesButtonId,
  installPluginOrConfirmLoginButtonsClassName,
  loginButtonClassName,
  pluginNameClassName,
  URLs,
} from "./constants";
import path from "node:path";

(async () => {
  if (!process.env.EMAIL) {
    console.error("Please provide an email address in process.env");
    process.exit(1);
  }
  if (!process.env.PASSWORD) {
    console.error("Please provide a password in process.env");
    process.exit(1);
  }

  console.info("Starting the selenium driver");
  const driverPath = path.resolve(__dirname, "drivers", "msedgedriver.exe");
  const service = new edge.ServiceBuilder(driverPath);
  service.loggingTo("selenium.log");
  const options = new edge.Options();
  options.addArguments(
    // "--headless",
    "--disable-extensions",
    "--window-size=1200,800"
  );

  const driver = new Builder()
    .forBrowser(Browser.EDGE)
    .setEdgeService(service)
    .setEdgeOptions(options)
    .build();

  async function acceptCookies() {
    const acceptCookiesButton = await driver.wait(
      until.elementLocated(By.id(cookiesButtonId)),
      10000
    );
    await acceptCookiesButton.click();
  }

  async function login() {
    await driver.get("https://marketplace.elgato.com/");
    await acceptCookies();
    const loginButton = await driver.wait(
      until.elementLocated(By.className(loginButtonClassName)),
      10000
    );
    await driver.wait(until.elementIsVisible(loginButton), 10000);
    await loginButton.click();
    const emailField = await driver.wait(until.elementLocated(By.id("email")));
    emailField.sendKeys(process.env.EMAIL!);
    const passwordField = await driver.wait(
      until.elementLocated(By.id("password")),
      10000
    );
    passwordField.sendKeys(process.env.PASSWORD!);
    const confirmLoginButton = await driver.wait(
      until.elementLocated(
        By.className(installPluginOrConfirmLoginButtonsClassName)
      ),
      10000
    );
    await confirmLoginButton.click();
  }

  async function scrapPlugin(url: string) {
    driver.navigate().to(url);
    const pluginName = await driver
      .findElement(By.className(pluginNameClassName))
      .getText();
    const installPluginButton = await driver.findElement(
      By.className(installPluginOrConfirmLoginButtonsClassName)
    );
    await driver.wait(
      until.elementTextIs(installPluginButton, "Open in Stream Deck"),
      10000
    );
    await installPluginButton.click();
    await driver.sleep(5000);
  }

  try {
    await login();
    for await (const url of URLs) {
      await scrapPlugin(url);
    }
  } catch (error) {
    console.error(error);
  } finally {
    await driver.quit();
  }
})();
