import { i18nBuilder } from "keycloakify/login";
import type { ThemeName } from "../kc.gen";

const { useI18n, ofTypeI18n } = i18nBuilder
  .withThemeName<ThemeName>()
  .withCustomTranslations({
    tr: {
      doLogIn: "Giriş yap",
      doRegister: "Kayıt ol",
      doCancel: "Vazgeç",
      doSubmit: "Devam et",
      doTryAgain: "Tekrar dene",
      loginAccountTitle: "SKY LAB hesabına giriş yap",
      loginTitle: "SKY LAB hesabına giriş yap",
      usernameOrEmail: "Kullanıcı adı veya e-posta",
      password: "Parola",
      rememberMe: "Beni hatırla",
      doForgotPassword: "Parolanı mı unuttun?",
      loginTotpTitle: "Doğrulama uygulamasını ayarla",
      updatePasswordTitle: "Parolanı yenile",
      "webauthn-registration-title": "Passkey oluştur",
      "webauthn-error-title": "Passkey işlemi tamamlanamadı",
      "webauthn-error-registration": "Passkey kaydedilemedi.<br/> {0}",
      "webauthn-error-api-get": "Passkey ile doğrulama yapılamadı.<br/> {0}",
      "webauthn-error-different-user": "Bu passkey başka bir kullanıcıya ait.",
      "webauthn-error-auth-verification": "Passkey doğrulama sonucu geçersiz.<br/> {0}",
      "webauthn-error-register-verification": "Passkey kayıt sonucu geçersiz.<br/> {0}",
      "webauthn-error-user-not-found": "Passkey ile doğrulanan kullanıcı bulunamadı.",
      "webauthn-unsupported-browser-text": "Bu tarayıcı passkey kullanımını desteklemiyor.",
      "webauthn-doAuthenticate": "Passkey ile devam et",
      "webauthn-registration-init-label": "Passkey",
      "webauthn-registration-init-label-prompt": "Passkey için bir ad yaz",
      "passkey-login-title": "Passkey ile giriş",
      "passkey-available-authenticators": "Kullanılabilir passkeyler",
      "passkey-unsupported-browser-text": "Bu tarayıcı koşullu passkey kullanımını desteklemiyor.",
      "passkey-doAuthenticate": "Passkey ile giriş yap",
      "passkey-createdAt-label": "Oluşturulma: ",
      "passkey-autofill-select": "Passkeyini seç"
    },
    en: {
      doLogIn: "Sign in",
      doRegister: "Register",
      doCancel: "Cancel",
      doSubmit: "Continue",
      doTryAgain: "Try again",
      loginAccountTitle: "Sign in to your SKY LAB account",
      loginTitle: "Sign in to SKY LAB",
      usernameOrEmail: "Username or email",
      password: "Password",
      rememberMe: "Remember me",
      doForgotPassword: "Forgot your password?",
      loginTotpTitle: "Set up an authenticator app",
      updatePasswordTitle: "Update your password",
      "webauthn-registration-title": "Create a passkey",
      "webauthn-error-title": "The passkey action could not be completed",
      "webauthn-error-registration": "The passkey could not be registered.<br/> {0}",
      "webauthn-error-api-get": "Passkey authentication failed.<br/> {0}",
      "webauthn-error-different-user": "This passkey belongs to another user.",
      "webauthn-error-auth-verification": "The passkey authentication response is invalid.<br/> {0}",
      "webauthn-error-register-verification": "The passkey registration response is invalid.<br/> {0}",
      "webauthn-error-user-not-found": "The user authenticated by the passkey was not found.",
      "webauthn-unsupported-browser-text": "This browser does not support passkeys.",
      "webauthn-doAuthenticate": "Continue with a passkey",
      "webauthn-registration-init-label": "Passkey",
      "webauthn-registration-init-label-prompt": "Enter a name for the passkey",
      "passkey-login-title": "Sign in with a passkey",
      "passkey-available-authenticators": "Available passkeys",
      "passkey-unsupported-browser-text": "This browser does not support conditional passkeys.",
      "passkey-doAuthenticate": "Sign in with a passkey",
      "passkey-createdAt-label": "Created: ",
      "passkey-autofill-select": "Select your passkey"
    }
  })
  .build();

export type I18n = typeof ofTypeI18n;
export { useI18n };
