export interface Config {
  email: string;
  password: string;
  headless: boolean;
  timeout: {
    navigation: number;
    selector: number;
    cookie: number;
  };
  viewport: {
    width: number;
    height: number;
  };
}

export interface PluginResult {
  url: string;
  name?: string;
  success: boolean;
  error?: string;
}

export interface Selectors {
  cookiesButtonId: string;
  loginButtonClassName: string;
  pluginNameClassName: string;
  installButtonClassName: string;
}
