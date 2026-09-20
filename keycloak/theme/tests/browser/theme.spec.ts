import { expect, test } from "@playwright/test";

test("login uses semantic landmarks and preserves remember-me for conditional passkeys", async ({ page }) => {
  await page.goto("/?page=login.ftl");

  await expect(page.getByRole("banner", { name: "SKY LAB kimlik hizmeti" })).toBeVisible();
  await expect(page.getByRole("main")).toBeVisible();
  await expect(page.getByRole("contentinfo")).toContainText("Yıldız Teknik Üniversitesi");
  await expect(page.getByRole("heading", { level: 1 })).toContainText("SKY LAB");
  await expect(page.getByRole("button", { name: "Giriş yap", exact: true })).toBeVisible();

  const rememberMe = page.locator("#rememberMe");
  const passkeyRememberMe = page.locator("#sl-passkey-remember-me");
  await expect(rememberMe).toBeChecked();
  await expect(passkeyRememberMe).toBeEnabled();

  await rememberMe.uncheck();
  await expect(passkeyRememberMe).toBeDisabled();
  await rememberMe.check();
  await expect(passkeyRememberMe).toBeEnabled();
});

test("keyboard navigation exposes skip link and native locale menu", async ({ page }) => {
  await page.goto("/?page=login.ftl");

  const skipLink = page.locator(".sl-skip-link");
  await skipLink.focus();
  await expect(skipLink).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.locator("#sl-main-content")).toBeFocused();

  const languageMenu = page.locator(".sl-language");
  await languageMenu.locator("summary").focus();
  await page.keyboard.press("Enter");
  await expect(languageMenu).toHaveAttribute("open", "");
  await expect(languageMenu.getByRole("link", { name: "English" })).toBeVisible();

  await languageMenu.getByRole("link", { name: "English" }).click();
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(page.getByRole("banner", { name: "SKY LAB identity service" })).toBeVisible();
  await expect(page.locator(".sl-card__eyebrow")).toContainText("Secure account action");
  await expect(page.getByRole("heading", { name: "Sign in to your SKY LAB account" })).toBeVisible();
  await expect(page.getByRole("contentinfo")).toContainText("Yıldız Technical University");
});

test("known-username pages keep a labelled landmark and page heading", async ({ page }) => {
  await page.goto("/?page=login-password.ftl");

  await expect(page.locator(".sl-card")).toHaveAttribute("aria-labelledby", "kc-page-title");
  await expect(page.locator("#kc-page-title")).toBeVisible();
  await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
});

test("reduced motion and secondary-button contrast survive hover", async ({ browser }) => {
  const context = await browser.newContext({ reducedMotion: "reduce", locale: "tr-TR" });
  const page = await context.newPage();
  await page.goto("/?page=login-update-password.ftl");

  const glow = page.locator(".sl-glow").first();
  await expect(glow).toHaveCSS("animation-name", "none");

  const secondary = page.locator(".sl-button--secondary").first();
  await expect(secondary).toHaveCSS("background-color", "rgb(41, 44, 57)");
  await secondary.hover();
  await expect(secondary).toHaveCSS("background-color", "rgb(56, 60, 75)");

  await context.close();
});

test("WebAuthn registration carries the Keycloak 26.7 resident-key contract", async ({ page }) => {
  await page.goto("/?page=webauthn-register.ftl");

  await expect(page.locator("#authenticatorAttachment")).toHaveAttribute("name", "authenticatorAttachment");
  const moduleSource = await page.locator('script[type="module"]:not([src])').allTextContents();
  const source = moduleSource.join("\n");
  expect(source).toContain("authenticatorAttachment");
  expect(source).toContain("requireResidentKey");
  expect(source).toContain("residentKey");
  expect(source).toContain('"required"');
});

test("WebAuthn retry submits the actual execution and AIA screens expose cancel", async ({ page }) => {
  await page.goto("/?page=webauthn-error.ftl");
  await page.locator("#kc-error-credential-form").evaluate(form => {
    form.addEventListener("submit", event => event.preventDefault(), { once: true });
  });
  await page.locator("#kc-try-again").click();
  await expect(page.locator("#executionValue")).toHaveValue("webauthn-execution-fixture");
  await expect(page.locator("#isSetRetry")).toHaveValue("retry");
  await expect(page.locator("#cancelWebAuthnAIA")).toBeVisible();

  await page.goto("/?page=login-config-totp.ftl");
  await expect(page.locator("#saveTOTPBtn")).toBeVisible();
  await expect(page.locator("#cancelTOTPBtn")).toBeVisible();

  await page.goto("/?page=login-update-password.ftl");
  await expect(page.locator('button[name="cancel-aia"]')).toBeVisible();
});
