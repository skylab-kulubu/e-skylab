import { createGetKcContextMock } from "keycloakify/login/KcContext";
import { kcEnvDefaults, themeNames } from "./kc.gen";
import type {
  KcContext,
  KcContextExtension,
  KcContextExtensionPerPage
} from "./login/KcContext";

const { getKcContextMock } = createGetKcContextMock({
  kcContextExtension: {
    themeName: themeNames[0],
    properties: { ...kcEnvDefaults }
  } satisfies KcContextExtension,
  kcContextExtensionPerPage: {
    "passkey-offer.ftl": {}
  } satisfies KcContextExtensionPerPage,
  overrides: {
    realm: {
      name: "e-skylab",
      displayName: "SKY LAB",
      displayNameHtml: "SKY LAB",
      internationalizationEnabled: true
    },
    locale: {
      currentLanguageTag: "tr",
      supported: [
        { languageTag: "tr", label: "Türkçe", url: "?lang=tr" },
        { languageTag: "en", label: "English", url: "?lang=en" }
      ]
    },
    client: {
      clientId: "account-center",
      name: "SKY LAB Hesap",
      attributes: {}
    },
    isAppInitiatedAction: true
  },
  overridesPerPage: {
    "login.ftl": {
      enableWebAuthnConditionalUI: true,
      realm: { rememberMe: true },
      login: { rememberMe: "on" },
      social: {
        displayInfo: true,
        providers: [
          {
            alias: "microsoft",
            displayName: "Microsoft",
            providerId: "microsoft",
            loginUrl: "#microsoft"
          }
        ]
      },
      authenticatorAttachment: "platform",
      mediation: "conditional"
    },
    "login-username.ftl": {
      enableWebAuthnConditionalUI: true,
      realm: { rememberMe: true },
      login: { rememberMe: "on" },
      authenticatorAttachment: "platform",
      mediation: "conditional"
    },
    "webauthn-register.ftl": {
      authenticatorAttachment: "platform",
      requireResidentKey: "true",
      residentKey: "required",
      userVerificationRequirement: "required"
    },
    "webauthn-error.ftl": {
      execution: "webauthn-execution-fixture"
    }
  }
});

const allowedPages = new Set<KcContext["pageId"]>([
  "login.ftl",
  "login-username.ftl",
  "login-password.ftl",
  "login-update-password.ftl",
  "login-config-totp.ftl",
  "webauthn-register.ftl",
  "webauthn-error.ftl",
  "login-passkeys-conditional-authenticate.ftl",
  "passkey-offer.ftl"
]);

export function getDevKcContext(): KcContext {
  const searchParams = new URLSearchParams(window.location.search);
  const requestedPage = searchParams.get("page") as KcContext["pageId"] | null;
  const pageId = requestedPage !== null && allowedPages.has(requestedPage) ? requestedPage : "login.ftl";
  const languageTag = searchParams.get("lang") === "en" ? "en" : "tr";

  return getKcContextMock({
    pageId,
    overrides: {
      locale: {
        currentLanguageTag: languageTag,
        supported: [
          { languageTag: "tr", label: "Türkçe", url: `?page=${pageId}&lang=tr` },
          { languageTag: "en", label: "English", url: `?page=${pageId}&lang=en` }
        ]
      }
    }
  }) as KcContext;
}
