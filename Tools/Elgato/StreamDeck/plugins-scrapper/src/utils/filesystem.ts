import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { logger } from "./logger";

export class FileSystemHelper {
  static setupUserDataDir(): string {
    const userDataDir = path.join(
      os.tmpdir(),
      `playwright-streamdeck-${Date.now()}`
    );
    const preferencesDir = path.join(userDataDir, "Default");

    fs.mkdirSync(preferencesDir, { recursive: true });

    const preferencesSourcePath = path.join(
      __dirname,
      "..",
      "context",
      "Preferences"
    );
    const preferencesDestPath = path.join(preferencesDir, "Preferences");

    try {
      fs.copyFileSync(preferencesSourcePath, preferencesDestPath);
      logger.info(`UserData directory created at: ${userDataDir}`);
    } catch (error) {
      logger.error("Failed to copy Preferences file:", error);
      throw error;
    }

    return userDataDir;
  }

  static cleanupUserDataDir(userDataDir: string): void {
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
      logger.info("UserData directory cleaned up");
    } catch (error) {
      logger.warn("Failed to clean up userData directory:", error);
    }
  }
}
