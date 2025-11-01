import type { Config, Selectors } from "../types";

export const config: Config = {
  email: process.env.EMAIL || "",
  password: process.env.PASSWORD || "",
  headless: process.env.HEADLESS !== "false",
  timeout: {
    navigation: 30000,
    selector: 10000,
    cookie: 10000,
  },
  viewport: {
    width: 1200,
    height: 800,
  },
};

export const selectors: Selectors = {
  cookiesButtonId: "onetrust-accept-btn-handler",
  loginButtonClassName:
    "text-body-m inline-grid grid-flow-col items-center justify-center gap-x-[var(--button-gap)] border-transparent hover:cursor-pointer focus-visible:outline-none hover:transition-colors hover:duration-100 focus-visible:ring-2 focus-visible:ring-focus-selected focus-visible:ring-offset-2 focus-visible:ring-offset-focus-inset bg-button-standard-surface-default text-button-standard-content-color hover:bg-button-standard-surface-hover active:bg-button-standard-surface-pressed rounded-[var(--button-rounding-default)] w-fit min-h-[var(--button-m-size)] px-[var(--button-m-padding-x)]",
  pluginNameClassName:
    "typography-heading-l text-content-primary text-left",
  installButtonClassName:
    "text-body-m inline-grid grid-flow-col items-center justify-center gap-x-[var(--button-gap)] border-transparent hover:cursor-pointer focus-visible:outline-none hover:transition-colors hover:duration-100 focus-visible:ring-2 focus-visible:ring-focus-selected focus-visible:ring-offset-2 focus-visible:ring-offset-focus-inset bg-button-accent-surface-default text-button-accent-content-color hover:bg-button-accent-surface-hover active:bg-button-accent-surface-pressed rounded-[var(--button-rounding-default)] w-full min-h-[var(--button-m-size)] px-[var(--button-m-padding-x)]",
};

export const pluginURLs = [
  "https://marketplace.elgato.com/product/obs-studio-35615969-830f-45c9-ba0a-1a295bba7fec",
  "https://marketplace.elgato.com/product/obs-tools-1736515e-1452-41a3-9548-d2b3a689076f",
  "https://marketplace.elgato.com/product/stream-counter-ab18c97d-4b52-442e-a903-fcfe21801b45",
  "https://marketplace.elgato.com/product/twitch-54e38b3b-89ab-4400-b55f-645378785709",
  "https://marketplace.elgato.com/product/pulsoid-heart-rate-tracking-332570f3-2411-459a-a4a4-7b8d92025922",
  "https://marketplace.elgato.com/product/volume-controller-34d9aa59-a41a-4a4c-a853-202ca91409e1",
  "https://marketplace.elgato.com/product/spotify-integration-windows-5e3a6d60-570a-40f3-b186-dbcd122216a2",
  "https://marketplace.elgato.com/product/soundpad-integration-9b5c4dee-11a8-4ef3-950c-18c1027e3735",
  "https://marketplace.elgato.com/product/voicemeeter-integration-f879a66f-4b9b-42de-9635-539797e5b5a7",
  "https://marketplace.elgato.com/product/advanced-launcher-d9a289e4-9f61-4613-9f86-0069f5897125",
  "https://marketplace.elgato.com/product/supermacro-62195fec-7bcb-403d-b650-c342e9dfec67",
  "https://marketplace.elgato.com/product/win-tools-c17abe0e-f565-4d86-a80a-73b1d31c0c7d",
  "https://marketplace.elgato.com/product/windows-mover-resizer-5fa50346-eff5-4c75-b5e6-a8e377d694dc",
  "https://marketplace.elgato.com/product/speed-test-b493077c-ac84-4dc7-9f9f-0561d3007772",
  "https://marketplace.elgato.com/product/cpu-58f3a1f4-dd4d-43bb-9b79-ec95700568a4",
  "https://marketplace.elgato.com/product/discord-e3559f36-d31d-4529-ab1f-739955e2ac7a",
  "https://marketplace.elgato.com/product/visual-studio-code-61254b24-a60c-4a87-acae-70c39eda8a19",
  "https://marketplace.elgato.com/product/4k-capture-utility-bcfca6c2-66eb-49c0-8d43-dbf5d40844e1",
  "https://marketplace.elgato.com/product/stream-deck-games-5610386b-e778-4b58-9c5d-f4499a986106",
  "https://marketplace.elgato.com/product/advanced-screen-saver-7fc6ca9f-f576-4606-8c27-51e68925d5f3",
];
