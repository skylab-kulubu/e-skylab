import { useEffect, useState } from "react";
import { kcSanitize } from "keycloakify/lib/kcSanitize";
import type { PageProps } from "keycloakify/login/pages/PageProps";
import { useScript } from "keycloakify/login/pages/Login.useScript";
import { useSetClassName } from "keycloakify/tools/useSetClassName";
import ytuLogoUrl from "../assets/ytu-logo.png";
import type { KcContext } from "./KcContext";
import type { I18n } from "./i18n";
import LegacyFrame from "./LegacyFrame";
import "./legacy-login.css";

type LoginProps = PageProps<Extract<KcContext, { pageId: "login.ftl" }>, I18n>;

export default function Login(props: LoginProps) {
  const { kcContext, i18n } = props;
  const {
    auth,
    authenticators,
    enableWebAuthnConditionalUI,
    login,
    messagesPerField,
    realm,
    social,
    url,
    usernameHidden
  } = kcContext;
  const { currentLanguage, msg, msgStr } = i18n;
  const webAuthnButtonId = "authenticateWebAuthnButton";
  const hasPasskey =
    enableWebAuthnConditionalUI === true ||
    (authenticators !== undefined && authenticators.authenticators.length > 0);
  const microsoftProvider = social?.providers?.find(provider => provider.providerId === "microsoft");
  const [view, setView] = useState<"choice" | "password">(
    messagesPerField.existsError("username", "password") ? "password" : "choice"
  );
  const [isLoginButtonDisabled, setIsLoginButtonDisabled] = useState(false);
  const [isPasswordVisible, setIsPasswordVisible] = useState(false);

  useScript({ webAuthnButtonId, kcContext, i18n });
  useSetClassName({ qualifiedName: "html", className: "sl-html" });
  useSetClassName({ qualifiedName: "body", className: "sl-body" });

  useEffect(() => {
    document.documentElement.lang = currentLanguage.languageTag;
    document.title = msgStr("loginTitle", realm.displayName || realm.name);
  }, [currentLanguage.languageTag, msgStr, realm.displayName, realm.name]);

  return (
    <LegacyFrame
      mainId="sl-legacy-main"
      titleId="sl-legacy-title"
      title={msgStr("skylabTitle")}
      description={msgStr("skylabDesc")}
      skipToContent={msgStr("skipToContent")}
      kvkkPrefix={msgStr("kvkkPrefix")}
      kvkkLinkText={msgStr("kvkkLinkText")}
      kvkkSuffix={msgStr("kvkkSuffix")}
    >
            {view === "choice" && (
              <>
                <div className="sl-legacy-choices">
                  {microsoftProvider !== undefined && (
                    <a className="sl-legacy-choice" href={microsoftProvider.loginUrl}>
                      <img src={ytuLogoUrl} alt="" />
                      <span>{msgStr("microsoft")}</span>
                    </a>
                  )}

                  <button
                    className="sl-legacy-choice"
                    type="button"
                    onClick={() => setView("password")}
                  >
                    <svg aria-hidden="true" viewBox="0 0 24 24" fill="none">
                      <path
                        d="M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0ZM12 14a7 7 0 0 0-7 7h14a7 7 0 0 0-7-7Z"
                        stroke="currentColor"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="2"
                      />
                    </svg>
                    <span>{msgStr("notYtuStudent")}</span>
                  </button>
                </div>

                {hasPasskey && (
                  <div className="sl-legacy-passkey-wrap">
                    <button
                      id={webAuthnButtonId}
                      className="sl-legacy-passkey"
                      type="button"
                    >
                      {msgStr("passkeyChoice")}
                    </button>
                  </div>
                )}
              </>
            )}

            {view === "password" && (
              <div className="sl-legacy-password-view">
                <button
                  className="sl-legacy-back"
                  type="button"
                  onClick={() => setView("choice")}
                >
                  <svg aria-hidden="true" viewBox="0 0 24 24" fill="none">
                    <path
                      d="m15 19-7-7 7-7"
                      stroke="currentColor"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                    />
                  </svg>
                  {msgStr("goBack")}
                </button>

                {kcContext.message !== undefined && kcContext.message.type !== "warning" && (
                  <div
                    className={`sl-legacy-alert sl-legacy-alert--${kcContext.message.type}`}
                    role={kcContext.message.type === "error" ? "alert" : "status"}
                    dangerouslySetInnerHTML={{ __html: kcSanitize(kcContext.message.summary) }}
                  />
                )}

                <form
                  id="kc-form-login"
                  action={url.loginAction}
                  method="post"
                  onSubmit={() => setIsLoginButtonDisabled(true)}
                >
                  {!usernameHidden && (
                    <div className="sl-legacy-field">
                      <label htmlFor="username">
                        {!realm.loginWithEmailAllowed
                          ? msg("username")
                          : realm.registrationEmailAsUsername
                            ? msg("email")
                            : msg("usernameOrEmail")}
                      </label>
                      <input
                        id="username"
                        name="username"
                        type="text"
                        autoFocus
                        autoComplete={enableWebAuthnConditionalUI ? "username webauthn" : "username"}
                        defaultValue={login.username ?? ""}
                        aria-invalid={messagesPerField.existsError("username", "password")}
                      />
                    </div>
                  )}

                  {realm.password && (
                    <div className="sl-legacy-field">
                      <div className="sl-legacy-field__heading">
                        <label htmlFor="password">{msg("password")}</label>
                        {realm.resetPasswordAllowed && (
                          <a href={url.loginResetCredentialsUrl}>{msg("doForgotPassword")}</a>
                        )}
                      </div>
                      <div className="sl-legacy-password-input">
                        <input
                          id="password"
                          name="password"
                          type={isPasswordVisible ? "text" : "password"}
                          autoComplete="current-password"
                          aria-invalid={messagesPerField.existsError("username", "password")}
                        />
                        <button
                          type="button"
                          aria-label={msgStr(isPasswordVisible ? "hidePassword" : "showPassword")}
                          aria-controls="password"
                          onClick={() => setIsPasswordVisible(current => !current)}
                        >
                          <span aria-hidden="true">{isPasswordVisible ? "⊘" : "◉"}</span>
                        </button>
                      </div>
                    </div>
                  )}

                  {messagesPerField.existsError("username", "password") && (
                    <p
                      id="input-error"
                      className="sl-legacy-field-error"
                      aria-live="polite"
                      dangerouslySetInnerHTML={{
                        __html: kcSanitize(messagesPerField.getFirstError("username", "password"))
                      }}
                    />
                  )}

                  {realm.rememberMe && !usernameHidden && (
                    <label className="sl-legacy-remember" htmlFor="rememberMe">
                      <input
                        id="rememberMe"
                        name="rememberMe"
                        type="checkbox"
                        defaultChecked={Boolean(login.rememberMe)}
                      />
                      <span>{msg("rememberMe")}</span>
                    </label>
                  )}

                  <input
                    id="id-hidden-input"
                    name="credentialId"
                    type="hidden"
                    value={auth.selectedCredential}
                  />
                  <button
                    id="kc-login"
                    className="sl-legacy-submit"
                    type="submit"
                    disabled={isLoginButtonDisabled}
                  >
                    {msg("doLogIn")}
                  </button>
                </form>
              </div>
            )}

            {hasPasskey && (
              <>
                <form id="webauth" action={url.loginAction} method="post" hidden>
                  <input type="hidden" id="clientDataJSON" name="clientDataJSON" />
                  <input type="hidden" id="authenticatorData" name="authenticatorData" />
                  <input type="hidden" id="signature" name="signature" />
                  <input type="hidden" id="credentialId" name="credentialId" />
                  <input type="hidden" id="userHandle" name="userHandle" />
                  <input type="hidden" id="error" name="error" />
                </form>
                {authenticators !== undefined && authenticators.authenticators.length > 0 && (
                  <form id="authn_select" hidden>
                    {authenticators.authenticators.map(authenticator => (
                      <input
                        key={authenticator.credentialId}
                        type="hidden"
                        name="authn_use_chk"
                        readOnly
                        value={authenticator.credentialId}
                      />
                    ))}
                  </form>
                )}
              </>
            )}
    </LegacyFrame>
  );
}
