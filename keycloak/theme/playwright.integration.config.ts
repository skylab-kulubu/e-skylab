import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/integration",
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 120_000,
  use: {
    browserName: "chromium",
    headless: true,
    trace: "retain-on-failure"
  }
});
