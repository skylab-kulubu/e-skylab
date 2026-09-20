import { useEffect } from "react";
import { useSetClassName } from "keycloakify/tools/useSetClassName";
import type { KcContext } from "./KcContext";
import type { I18n } from "./i18n";
import LegacyFrame from "./LegacyFrame";

type PasskeyOfferProps = {
  kcContext: Extract<KcContext, { pageId: "passkey-offer.ftl" }>;
  i18n: I18n;
};

export default function PasskeyOffer(props: PasskeyOfferProps) {
  const { kcContext, i18n } = props;
  const { currentLanguage, msgStr } = i18n;
  const isTurkish = currentLanguage.languageTag.toLowerCase().startsWith("tr");
  const copy = isTurkish
    ? {
        title: "Passkey ekle",
        description:
          "Touch ID, Face ID veya Windows Hello ile daha hızlı ve parolasız giriş yapabilirsin.",
        privacy: "Passkey yalnızca bu cihazda güvenli şekilde saklanır; SKY LAB biyometrik verine erişmez.",
        now: "Şimdi ekle",
        later: "30 gün boyunca tekrar sorma"
      }
    : {
        title: "Add a passkey",
        description:
          "Sign in faster without a password by using Touch ID, Face ID or Windows Hello.",
        privacy: "Your passkey stays protected on this device; SKY LAB never receives your biometric data.",
        now: "Add now",
        later: "Do not ask again for 30 days"
      };

  useSetClassName({ qualifiedName: "html", className: "sl-html" });
  useSetClassName({ qualifiedName: "body", className: "sl-body" });

  useEffect(() => {
    document.documentElement.lang = currentLanguage.languageTag;
    document.title = `${copy.title} · SKY LAB`;
  }, [copy.title, currentLanguage.languageTag]);

  return (
    <LegacyFrame
      mainId="sl-passkey-offer-main"
      titleId="sl-passkey-offer-title"
      title={copy.title}
      description={copy.description}
      skipToContent={msgStr("skipToContent")}
      kvkkPrefix={msgStr("kvkkPrefix")}
      kvkkLinkText={msgStr("kvkkLinkText")}
      kvkkSuffix={msgStr("kvkkSuffix")}
    >
      <form
        id="kc-passkey-offer-form"
        className="sl-passkey-offer"
        action={kcContext.url.loginAction}
        method="post"
      >
        <p className="sl-passkey-offer__privacy">{copy.privacy}</p>
        <div className="sl-passkey-offer__actions">
          <button
            className="sl-legacy-submit"
            type="submit"
            name="passkey-choice"
            value="yes"
          >
            {copy.now}
          </button>
          <button
            className="sl-legacy-choice sl-passkey-offer__later"
            type="submit"
            name="passkey-choice"
            value="no"
          >
            {copy.later}
          </button>
        </div>
      </form>
    </LegacyFrame>
  );
}
