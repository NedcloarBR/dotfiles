# Elgato Stream Deck Plugins Scraper

Automated tool to install Stream Deck plugins from Elgato Marketplace using Playwright.

## 📋 Features

- ✅ Automatic authentication to Elgato Marketplace
- ✅ Batch installation of multiple plugins
- ✅ Protocol handler support (`streamdeck://`)
- ✅ Structured and colored logging
- ✅ Robust error handling
- ✅ Detailed results reporting
- ✅ Modular and maintainable architecture

## 🚀 Installation

1. Clone the repository or navigate to the directory:
```bash
cd Tools/Elgato/StreamDeck/plugins-scrapper
```

2. Install dependencies:
```bash
yarn install
```

3. Configure environment variables:
```bash
cp .env.example .env
```

4. Edit the `.env` file with your credentials:
```env
EMAIL=your-email@example.com
PASSWORD=your-password
HEADLESS=false
```

## 📝 Configuration

### Add Plugin URLs

Edit the `src/config/index.ts` file and add/uncomment the URLs of the plugins you want to install:

```typescript
export const pluginURLs = [
  "https://marketplace.elgato.com/product/obs-studio-...",
  "https://marketplace.elgato.com/product/twitch-...",
  // Add more URLs here
];
```

### Adjust Timeouts

In the same file, you can adjust timeouts as needed:

```typescript
export const config: Config = {
  // ...
  timeout: {
    navigation: 30000,  // Time for navigation
    selector: 10000,    // Time to find elements
    cookie: 10000,      // Time for cookie banner
  },
};
```

## 🎯 Usage

### Production Mode
```bash
yarn start
```

### Development Mode (with watch)
```bash
yarn dev
```

### Legacy Mode (old code)
```bash
yarn legacy
```

## 📊 Example Output

```
[10:30:15] ℹ UserData directory created at: C:\Temp\playwright-streamdeck-1234567890
[10:30:15] ℹ Starting the Playwright browser with persistent context
[10:30:18] ✓ Browser launched successfully
[10:30:18] ℹ Navigating to Elgato Marketplace...

==================================================
  Starting Login Process
==================================================

[10:30:20] ℹ Waiting for cookie banner...
[10:30:21] ✓ Cookies accepted
[10:30:21] ℹ Clicking login button...
[10:30:22] ℹ Filling email...
[10:30:23] ℹ Filling password...
[10:30:24] ℹ Submitting login form...
[10:30:27] ✓ Login completed

==================================================
  Starting to scrape 3 plugins
==================================================

[10:30:28] ℹ Navigating to: https://marketplace.elgato.com/product/obs-studio-...
[10:30:30] ℹ Preparing to install plugin: OBS Studio
[10:30:31] ℹ Clicking install button...
[10:30:34] ✓ Plugin "OBS Studio" processed successfully

==================================================
  Scraping Results
==================================================

[10:30:45] ✓ Successfully processed: 3 plugins
[10:30:45] ℹ Closing browser...
[10:30:46] ✓ Browser closed
[10:30:46] ℹ UserData directory cleaned up
```

## 🏛️ Architecture

The project follows a modular architecture with clear separation of concerns:

- **Services**: Business logic (Browser, Auth, Plugin Scraper)
- **Utils**: Helper functions (Logger, Filesystem)
- **Types**: TypeScript definitions for type safety
- **Config**: Centralized configuration and constants

## 🐛 Troubleshooting

### Browser doesn't open
- Check if `HEADLESS=false` in the `.env` file
- Make sure Playwright is installed correctly

### Authentication error
- Confirm that email and password are correct in `.env`
- Verify that your account is active on Elgato Marketplace

### Plugins don't install
- Make sure Stream Deck is installed and running
- Check that plugin URLs are correct

## 📄 License

This project is for personal use in managing dotfiles.

## 🤝 Contributing

As this is a personal dotfiles project, modifications are made as needed for personal use. However, suggestions and improvements are always welcome!
