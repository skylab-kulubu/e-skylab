import { useEffect } from "react";
import { kcSanitize } from "keycloakify/lib/kcSanitize";
import type { TemplateProps } from "keycloakify/login/TemplateProps";
import { useInitialize } from "keycloakify/login/Template.useInitialize";
import { useSetClassName } from "keycloakify/tools/useSetClassName";
import skyLabLogoUrl from "../assets/skylab-logo.png";
import ytuLogoUrl from "../assets/ytu-logo.png";
import type { KcContext } from "./KcContext";
import type { I18n } from "./i18n";

export default function Template(props: TemplateProps<KcContext, I18n>) {
  const {
    displayInfo = false,
    displayMessage = true,
    displayRequiredFields = false,
    headerNode,
    socialProvidersNode = null,
    infoNode = null,
    documentTitle,
    bodyClassName,
    kcContext,
    i18n,
    doUseDefaultCss,
    children
  } = props;

  const { realm, auth, url, message, isAppInitiatedAction } = kcContext;
  const { msg, msgStr, currentLanguage, enabledLanguages } = i18n;
  const copy = currentLanguage.languageTag.toLowerCase().startsWith("tr")
    ? {
        skipToContent: "İçeriğe geç",
        identityService: "SKY LAB kimlik hizmeti",
        loginPage: "SKY LAB giriş sayfası",
        account: "Hesap",
        secureAccountAction: "Güvenli hesap işlemi",
        additionalInformation: "Ek bilgi",
        clubName: "Yıldız Teknik Üniversitesi SKY LAB Kulübü"
      }
    : {
        skipToContent: "Skip to content",
        identityService: "SKY LAB identity service",
        loginPage: "SKY LAB sign-in page",
        account: "Account",
        secureAccountAction: "Secure account action",
        additionalInformation: "Additional information",
        clubName: "Yıldız Technical University SKY LAB Club"
      };

  useEffect(() => {
    document.title = documentTitle ?? msgStr("loginTitle", realm.displayName || realm.name);
    document.documentElement.lang = currentLanguage.languageTag;
  }, [currentLanguage.languageTag, documentTitle, msgStr, realm.displayName, realm.name]);

  useSetClassName({ qualifiedName: "html", className: "sl-html" });
  useSetClassName({ qualifiedName: "body", className: bodyClassName ?? "sl-body" });

  const { isReadyToRender } = useInitialize({ kcContext, doUseDefaultCss });

  if (!isReadyToRender) {
    return null;
  }

  const showAttemptedUsername = auth?.showUsername && !auth.showResetCredentials;
  const messageIsVisible =
    displayMessage &&
    message !== undefined &&
    (message.type !== "warning" || !isAppInitiatedAction);

  return (
    <div className="sl-shell">
      <a
        className="sl-skip-link"
        href="#sl-main-content"
        onClick={event => {
          event.preventDefault();
          document.getElementById("sl-main-content")?.focus();
        }}
      >
        {copy.skipToContent}
      </a>

      <div className="sl-atmosphere" aria-hidden="true">
        <span className="sl-orbit sl-orbit--one" />
        <span className="sl-orbit sl-orbit--two" />
        <span className="sl-glow sl-glow--pink" />
        <span className="sl-glow sl-glow--blue" />
      </div>

      <header className="sl-site-header" aria-label={copy.identityService}>
        <a className="sl-brand" href={url.loginUrl} aria-label={copy.loginPage}>
          <img className="sl-brand__mark" src={skyLabLogoUrl} alt="" />
          <span className="sl-brand__copy">
            <strong>SKY LAB</strong>
            <span>{copy.account}</span>
          </span>
        </a>

        {enabledLanguages.length > 1 && (
          <details className="sl-language">
            <summary aria-label={msgStr("languages")}>{currentLanguage.label}</summary>
            <nav aria-label={msgStr("languages")}>
              <ul>
                {enabledLanguages.map(({ languageTag, label, href }) => (
                  <li key={languageTag}>
                    <a href={href} lang={languageTag} aria-current={languageTag === currentLanguage.languageTag ? "page" : undefined}>
                      {label}
                    </a>
                  </li>
                ))}
              </ul>
            </nav>
          </details>
        )}
      </header>

      <main id="sl-main-content" className="sl-main" tabIndex={-1}>
        <section className="sl-card" aria-labelledby="kc-page-title">
          <div className="sl-card__eyebrow">
            <span aria-hidden="true">✦</span>
            {copy.secureAccountAction}
          </div>

          <header className="sl-card__header">
            {displayRequiredFields && (
              <p className="sl-required-note">
                <span aria-hidden="true">*</span> {msg("requiredFields")}
              </p>
            )}
            <h1 id="kc-page-title">{headerNode}</h1>
            {showAttemptedUsername && (
              <div className="sl-attempted-user">
                <span id="kc-attempted-username">{auth.attemptedUsername}</span>
                <a id="reset-login" href={url.loginRestartFlowUrl}>
                  {msg("restartLoginTooltip")}
                </a>
              </div>
            )}
          </header>

          {messageIsVisible && (
            <div
              className={`sl-alert sl-alert--${message.type}`}
              role={message.type === "error" ? "alert" : "status"}
              aria-live={message.type === "error" ? "assertive" : "polite"}
            >
              <span className="sl-alert__icon" aria-hidden="true" />
              <span dangerouslySetInnerHTML={{ __html: kcSanitize(message.summary) }} />
            </div>
          )}

          <div className="sl-card__content">
            {children}

            {auth?.showTryAnotherWayLink && (
              <form id="kc-select-try-another-way-form" action={url.loginAction} method="post">
                <input type="hidden" name="tryAnotherWay" value="on" />
                <button
                  className="sl-text-button"
                  type="submit"
                  id="try-another-way"
                >
                  {msg("doTryAnotherWay")}
                </button>
              </form>
            )}

            {socialProvidersNode}

            {displayInfo && infoNode !== null && (
              <aside id="kc-info" className="sl-info" aria-label={copy.additionalInformation}>
                {infoNode}
              </aside>
            )}
          </div>
        </section>
      </main>

      <footer className="sl-site-footer">
        <img src={ytuLogoUrl} alt="" aria-hidden="true" />
        <span>{copy.clubName}</span>
      </footer>
    </div>
  );
}
