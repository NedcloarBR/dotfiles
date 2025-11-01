import chalk from "chalk";

type LogLevel = "info" | "warn" | "error" | "success" | "debug";

class Logger {
  private getTimestamp(): string {
    return new Date().toISOString().split("T")[1].split(".")[0];
  }

  private formatPrefix(level: LogLevel, icon: string, color: typeof chalk.blue): string {
    const timestamp = chalk.gray(`[${this.getTimestamp()}]`);
    const coloredIcon = color(icon);
    return `${timestamp} ${coloredIcon}`;
  }

  info(message: string, ...args: any[]): void {
    console.log(
      this.formatPrefix("info", "ℹ", chalk.blue),
      chalk.white(message),
      ...args
    );
  }

  warn(message: string, ...args: any[]): void {
    console.warn(
      this.formatPrefix("warn", "⚠", chalk.yellow),
      chalk.yellow(message),
      ...args
    );
  }

  error(message: string, ...args: any[]): void {
    console.error(
      this.formatPrefix("error", "✗", chalk.red),
      chalk.red(message),
      ...args
    );
  }

  success(message: string, ...args: any[]): void {
    console.log(
      this.formatPrefix("success", "✓", chalk.green),
      chalk.green(message),
      ...args
    );
  }

  debug(message: string, ...args: any[]): void {
    if (process.env.DEBUG === "true") {
      console.log(
        this.formatPrefix("debug", "🐛", chalk.magenta),
        chalk.magenta(message),
        ...args
      );
    }
  }

  section(title: string): void {
    const border = chalk.cyan("=".repeat(50));
    console.log(`\n${border}`);
    console.log(chalk.cyan.bold(`  ${title}`));
    console.log(`${border}\n`);
  }

  plugin(name: string): void {
    console.log(chalk.blue("📦"), chalk.white.bold(name));
  }

  url(url: string): void {
    console.log(chalk.gray("  →"), chalk.cyan.underline(url));
  }

  step(step: string): void {
    console.log(chalk.gray("  •"), chalk.white(step));
  }

  divider(): void {
    console.log(chalk.gray("-".repeat(50)));
  }
}

export const logger = new Logger();
