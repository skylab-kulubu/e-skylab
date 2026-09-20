import { createHmac } from "node:crypto";
import { readFileSync } from "node:fs";
import { expect, test, type Browser, type BrowserContext, type Page, type Request } from "@playwright/test";

type IntegrationConfig = {
  baseUrl: string;
  callbackUrl: string;
  clientId: string;
  clientSecret: string;
  username: string;
  password: string;
  changedPassword: string;
};

const configPath = process.env.REAL_KEYCLOAK_BROWSER_CONFIG;
if (configPath === undefined) {
  throw new Error("REAL_KEYCLOAK_BROWSER_CONFIG must point to the ephemeral integration config");
}

const config = JSON.parse(readFileSync(configPath, "utf8")) as IntegrationConfig;
const callback = new URL(config.callbackUrl);
let requestSequence = 0;

type BrowserPage = {
  callbackReached: Promise<string>;
  context: BrowserContext;
  page: Page;
};

async function withTimeout<T>(promise: Promise<T>, message: string, timeoutMs = 45_000): Promise<T> {
  let timeout: ReturnType<typeof setTimeout> | undefined;
  return Promise.race([
    promise,
    new Promise<never>((_resolve, reject) => {
      timeout = setTimeout(() => reject(new Error(message)), timeoutMs);
    })
  ]).finally(() => {
    if (timeout !== undefined) {
      clearTimeout(timeout);
    }
  });
}

function waitForCallbackRequest(page: Page): Promise<string> {
  return new Promise(resolve => {
    const onRequest = (request: Request) => {
      const requestUrl = new URL(request.url());
      if (requestUrl.origin !== callback.origin || requestUrl.pathname !== callback.pathname) {
        return;
      }
      page.off("request", onRequest);
      resolve(request.url());
    };
    page.on("request", onRequest);
  });
}

function waitForCallbackNavigation(page: Page): Promise<void> {
  return page.waitForEvent("framenavigated", {
    predicate: frame => {
      if (frame !== page.mainFrame()) {
        return false;
      }
      const navigationUrl = new URL(frame.url());
      return (
        (navigationUrl.origin === callback.origin && navigationUrl.pathname === callback.pathname) ||
        navigationUrl.protocol === "chrome-error:"
      );
    },
    timeout: 45_000
  }).then(() => undefined);
}

async function createAuthorizationUrl(kcAction?: string): Promise<{ state: string; url: string }> {
  const state = `real-browser-${++requestSequence}`;
  const body = new URLSearchParams({
    client_id: config.clientId,
    response_type: "code",
    scope: "openid",
    redirect_uri: config.callbackUrl,
    code_challenge: "QWxhZGRpbjpPcGVuU2VzYW1lMTIzNDU2Nzg5MDEyMzQ1Njc",
    code_challenge_method: "S256",
    state,
    nonce: `${state}-nonce`,
    ui_locales: "tr"
  });
  if (kcAction !== undefined) {
    body.set("kc_action", kcAction);
  }

  const response = await fetch(
    `${config.baseUrl}/realms/e-skylab-test/protocol/openid-connect/ext/par/request`,
    {
      method: "POST",
      headers: {
        authorization: `Basic ${Buffer.from(`${config.clientId}:${config.clientSecret}`).toString("base64")}`,
        "content-type": "application/x-www-form-urlencoded"
      },
      body
    }
  );
  const responseBody = await response.text();
  expect(response.ok, responseBody).toBe(true);
  const payload = JSON.parse(responseBody) as { request_uri: string };

  return {
    state,
    url: `${config.baseUrl}/realms/e-skylab-test/protocol/openid-connect/auth?client_id=${encodeURIComponent(config.clientId)}&request_uri=${encodeURIComponent(payload.request_uri)}`
  };
}

async function createPage(browser: Browser): Promise<BrowserPage> {
  const context = await browser.newContext();
  const page = await context.newPage();
  const callbackReached = waitForCallbackRequest(page);
  return { callbackReached, context, page };
}

async function openAction(page: Page, kcAction?: string): Promise<string> {
  const authorization = await createAuthorizationUrl(kcAction);
  await page.goto(authorization.url);
  await expect(page.locator(".sl-shell")).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("lang", "tr");
  return authorization.state;
}

async function signIn(page: Page, password = config.password): Promise<void> {
  await page.locator("#username").fill(config.username);
  await page.locator("#password").fill(password);
  await page.locator("#kc-login").click();
}

async function expectCallback(
  callbackReached: Promise<string>,
  state: string,
  actionStatus?: "success" | "cancelled"
): Promise<void> {
  const callbackUrl = await withTimeout(
    callbackReached,
    "Keycloak did not redirect to the registered callback within 45 seconds"
  );
  const result = new URL(callbackUrl);
  expect(result.origin).toBe(callback.origin);
  expect(result.pathname).toBe(callback.pathname);
  expect(result.searchParams.get("state")).toBe(state);
  expect(result.searchParams.get("code")).toEqual(expect.any(String));
  expect(result.searchParams.get("code")).not.toBe("");
  if (actionStatus !== undefined) {
    expect(result.searchParams.get("kc_action_status")).toBe(actionStatus);
  }
}

function decodeBase32(input: string): Buffer {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  let bits = "";
  for (const character of input.toUpperCase().replace(/[^A-Z2-7]/g, "")) {
    const value = alphabet.indexOf(character);
    if (value < 0) {
      throw new Error("TOTP secret contains a non-base32 character");
    }
    bits += value.toString(2).padStart(5, "0");
  }

  const bytes: number[] = [];
  for (let offset = 0; offset + 8 <= bits.length; offset += 8) {
    bytes.push(Number.parseInt(bits.slice(offset, offset + 8), 2));
  }
  return Buffer.from(bytes);
}

function generateTotp(secret: string): string {
  const counter = Math.floor(Date.now() / 30_000);
  const counterBuffer = Buffer.alloc(8);
  counterBuffer.writeBigUInt64BE(BigInt(counter));
  const digest = createHmac("sha1", decodeBase32(secret)).update(counterBuffer).digest();
  const offset = digest[digest.length - 1] & 0x0f;
  const binary =
    ((digest[offset] & 0x7f) << 24) |
    ((digest[offset + 1] & 0xff) << 16) |
    ((digest[offset + 2] & 0xff) << 8) |
    (digest[offset + 3] & 0xff);
  return String(binary % 1_000_000).padStart(6, "0");
}

test("real Keycloak 26.7 login and AIA contracts", async ({ browser }) => {
  test.setTimeout(300_000);

  await test.step("password login, theme locale and keyboard", async () => {
    const { callbackReached, context, page } = await createPage(browser);
    const state = await openAction(page);

    await page.locator(".sl-skip-link").focus();
    await page.keyboard.press("Enter");
    await expect(page.locator("#sl-main-content")).toBeFocused();
    await page.locator(".sl-language summary").click();
    await page.getByRole("link", { name: "English" }).click();
    await expect(page.locator("html")).toHaveAttribute("lang", "en");
    await expect(page.getByRole("banner", { name: "SKY LAB identity service" })).toBeVisible();
    await expect(page.locator("#kc-login")).toHaveCSS("background-color", "rgb(217, 31, 109)");

    await signIn(page);
    await expectCallback(callbackReached, state);
    await context.close();
  });

  await test.step("UPDATE_PASSWORD cancel", async () => {
    const { callbackReached, context, page } = await createPage(browser);
    const state = await openAction(page, "UPDATE_PASSWORD");
    await signIn(page);
    await expect(page.locator("#kc-passwd-update-form")).toBeVisible();
    await page.locator('button[name="cancel-aia"]').click();
    await expectCallback(callbackReached, state, "cancelled");
    await context.close();
  });

  await test.step("CONFIGURE_TOTP cancel", async () => {
    const { callbackReached, context, page } = await createPage(browser);
    const state = await openAction(page, "CONFIGURE_TOTP");
    await signIn(page);
    await expect(page.locator("#kc-totp-settings-form")).toBeVisible();
    await page.locator("#cancelTOTPBtn").click();
    await expectCallback(callbackReached, state, "cancelled");
    await context.close();
  });

  await test.step("WebAuthn failure and actual retry execution", async () => {
    const { context, page } = await createPage(browser);
    await context.addInitScript(() => {
      if (typeof CredentialsContainer !== "undefined") {
        Object.defineProperty(CredentialsContainer.prototype, "create", {
          configurable: true,
          value: async () => {
            throw new DOMException("Deterministic integration rejection", "NotAllowedError");
          }
        });
      }
    });
    page.on("dialog", dialog => dialog.accept("CI rejected passkey"));

    await openAction(page, "webauthn-register-passwordless");
    await signIn(page);
    await page.locator("#authenticateWebAuthnButton").click();
    await expect(page.locator("#kc-try-again")).toBeVisible();
    await page.locator("#kc-try-again").click();
    await expect(page.locator("#authenticateWebAuthnButton")).toBeVisible();
    await page.locator("#authenticateWebAuthnButton").click();
    await expect(page.locator("#kc-try-again")).toBeVisible();
    await context.close();
  });

  await test.step("WebAuthn AIA cancel", async () => {
    const { callbackReached, context, page } = await createPage(browser);
    const state = await openAction(page, "webauthn-register-passwordless");
    await signIn(page);
    await expect(page.locator("#cancelWebAuthnAIA")).toBeVisible();
    await page.locator("#cancelWebAuthnAIA").click();
    await expectCallback(callbackReached, state, "cancelled");
    await context.close();
  });

  await test.step("WebAuthn registration with a Chromium virtual authenticator", async () => {
    const { callbackReached, context, page } = await createPage(browser);
    type CredentialGetProbe = { mediation: string | null };
    let resolveNextCredentialGet: ((probe: CredentialGetProbe) => void) | undefined;
    let explicitPasskeyClickCount = 0;
    await context.exposeBinding("__skyLabCredentialGetStarted", (_source, mediation: unknown) => {
      resolveNextCredentialGet?.({ mediation: typeof mediation === "string" ? mediation : null });
      resolveNextCredentialGet = undefined;
    });
    await context.exposeBinding("__skyLabExplicitPasskeyClicked", () => {
      explicitPasskeyClickCount += 1;
    });
    await context.addInitScript(() => {
      if (typeof CredentialsContainer !== "undefined") {
        const originalGet = CredentialsContainer.prototype.get;
        CredentialsContainer.prototype.get = function (...args: Parameters<CredentialsContainer["get"]>) {
          const notify = (globalThis as typeof globalThis & {
            __skyLabCredentialGetStarted?: (mediation: CredentialMediationRequirement | null) => Promise<void>;
          }).__skyLabCredentialGetStarted;
          void notify?.(args[0]?.mediation ?? null);
          return Reflect.apply(originalGet, this, args) as ReturnType<CredentialsContainer["get"]>;
        };
      }

      addEventListener(
        "click",
        event => {
          const target = event.target;
          if (!(target instanceof HTMLElement) || target.id !== "authenticateWebAuthnButton") {
            return;
          }
          const notify = (globalThis as typeof globalThis & {
            __skyLabExplicitPasskeyClicked?: () => Promise<void>;
          }).__skyLabExplicitPasskeyClicked;
          void notify?.();
        },
        { capture: true }
      );
    });
    const cdp = await context.newCDPSession(page);
    await cdp.send("WebAuthn.enable");
    const { authenticatorId } = await cdp.send("WebAuthn.addVirtualAuthenticator", {
      options: {
        protocol: "ctap2",
        transport: "internal",
        hasResidentKey: true,
        hasUserVerification: true,
        isUserVerified: true,
        automaticPresenceSimulation: true
      }
    });
    page.on("dialog", dialog => dialog.accept("CI virtual passkey"));

    const state = await openAction(page, "webauthn-register-passwordless");
    await signIn(page);
    const registrationNavigationSettled = waitForCallbackNavigation(page);
    await page.locator("#authenticateWebAuthnButton").click();
    await Promise.all([
      expectCallback(callbackReached, state, "success"),
      registrationNavigationSettled
    ]);

    await context.clearCookies();
    // The registration submit deliberately uses the same Keycloak element id;
    // only clicks from the following passwordless-authentication ceremony count.
    explicitPasskeyClickCount = 0;
    const nextCredentialGet = new Promise<CredentialGetProbe>(resolve => {
      resolveNextCredentialGet = resolve;
    });
    const credentialAsserted = new Promise<{ authenticatorId: string }>(resolve => {
      cdp.once("WebAuthn.credentialAsserted", payload => resolve(payload));
    });
    const passwordlessAuthorization = await createAuthorizationUrl();
    const passwordlessCallbackReached = waitForCallbackRequest(page);
    await page.goto(passwordlessAuthorization.url);

    const conditionalMediationAvailable = await page.evaluate(async () =>
      typeof PublicKeyCredential !== "undefined" &&
      typeof PublicKeyCredential.isConditionalMediationAvailable === "function" &&
      (await PublicKeyCredential.isConditionalMediationAvailable())
    );
    if (conditionalMediationAvailable) {
      // A supported browser must enter the conditional ceremony. If KC fails to
      // invoke credentials.get, fail instead of masking that regression with an
      // explicit click. The init-script probe is installed before navigation,
      // so this remains deterministic even under slow emulation.
      const credentialGetProbe = await withTimeout(
        nextCredentialGet,
        "Keycloak did not start conditional WebAuthn mediation within 45 seconds"
      );
      expect(credentialGetProbe.mediation).toBe("conditional");
    } else {
      const passkeyButton = page.locator("#authenticateWebAuthnButton");
      await expect(passkeyButton).toBeVisible();
      await passkeyButton.click();
    }
    const [assertedCredential] = await Promise.all([
      withTimeout(
        credentialAsserted,
        "Chromium did not emit WebAuthn.credentialAsserted within 45 seconds"
      ),
      expectCallback(passwordlessCallbackReached, passwordlessAuthorization.state)
    ]);
    expect(assertedCredential.authenticatorId).toBe(authenticatorId);
    expect(explicitPasskeyClickCount).toBe(conditionalMediationAvailable ? 0 : 1);

    await cdp.send("WebAuthn.removeVirtualAuthenticator", { authenticatorId });
    await cdp.send("WebAuthn.disable");
    await context.close();
  });

  await test.step("UPDATE_PASSWORD complete", async () => {
    const { callbackReached, context, page } = await createPage(browser);
    const state = await openAction(page, "UPDATE_PASSWORD");
    await signIn(page);
    await page.locator("#password-new").fill(config.changedPassword);
    await page.locator("#password-confirm").fill(config.changedPassword);
    await page.locator('#kc-passwd-update-form input[type="submit"]').click();
    await expectCallback(callbackReached, state, "success");
    await context.close();
  });

  await test.step("updated password authenticates", async () => {
    const { callbackReached, context, page } = await createPage(browser);
    const state = await openAction(page);
    await signIn(page, config.changedPassword);
    await expectCallback(callbackReached, state);
    await context.close();
  });

  // Keep this last: completing TOTP changes all later login ceremonies by adding
  // an OTP challenge. The success assertion still exercises the real KC action.
  await test.step("CONFIGURE_TOTP complete", async () => {
    const { callbackReached, context, page } = await createPage(browser);
    const state = await openAction(page, "CONFIGURE_TOTP");
    await signIn(page, config.changedPassword);
    await page.locator("#mode-manual").click();
    const secret = (await page.locator("#kc-totp-secret-key").innerText()).trim().replace(/\s+/g, "");
    expect(secret).toMatch(/^[A-Z2-7]{16,}$/);
    await page.locator("#totp").fill(generateTotp(secret));
    await page.locator("#userLabel").fill("CI virtual authenticator");
    await page.locator("#saveTOTPBtn").click();
    await expectCallback(callbackReached, state, "success");
    await context.close();
  });
});
