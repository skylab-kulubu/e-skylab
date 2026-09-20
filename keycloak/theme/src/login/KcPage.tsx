import { lazy, Suspense } from "react";
import DefaultPage from "keycloakify/login/DefaultPage";
import type { ClassKey } from "keycloakify/login";
import type { KcContext } from "./KcContext";
import Template from "./Template";
import { useI18n } from "./i18n";
import { usePasskeyRememberMeBridge } from "./rememberMeBridge";
import "./theme.css";

const UserProfileFormFields = lazy(() => import("keycloakify/login/UserProfileFormFields"));

export default function KcPage(props: { kcContext: KcContext }) {
  const { kcContext } = props;
  const { i18n } = useI18n({ kcContext });

  usePasskeyRememberMeBridge(kcContext);

  return (
    <Suspense fallback={<main className="sl-loading" aria-live="polite">Yükleniyor…</main>}>
      <DefaultPage
        kcContext={kcContext}
        i18n={i18n}
        classes={classes}
        Template={Template}
        doUseDefaultCss={false}
        UserProfileFormFields={UserProfileFormFields}
        doMakeUserConfirmPassword
      />
    </Suspense>
  );
}

export const classes = {
  kcFormClass: "sl-form",
  kcFormGroupClass: "sl-field",
  kcFormGroupErrorClass: "sl-field--error",
  kcLabelClass: "sl-label",
  kcLabelWrapperClass: "sl-label-wrap",
  kcInputWrapperClass: "sl-input-wrap",
  kcInputClass: "sl-input",
  kcInputLargeClass: "sl-input--large",
  kcTextareaClass: "sl-input sl-textarea",
  kcInputGroup: "sl-input-group",
  kcInputErrorMessageClass: "sl-field-error",
  kcInputHelperTextBeforeClass: "sl-helper-text",
  kcInputHelperTextAfterClass: "sl-helper-text",
  kcFormOptionsClass: "sl-options",
  kcFormOptionsWrapperClass: "sl-options__item",
  kcFormSettingClass: "sl-settings",
  kcFormButtonsClass: "sl-actions",
  kcFormButtonsWrapperClass: "sl-actions",
  kcButtonClass: "sl-button",
  kcButtonPrimaryClass: "sl-button--primary",
  kcButtonSecondaryClass: "sl-button--secondary",
  kcButtonDefaultClass: "sl-button--secondary",
  kcButtonLargeClass: "sl-button--large",
  kcButtonBlockClass: "sl-button--block",
  kcFormPasswordVisibilityButtonClass: "sl-password-toggle",
  kcFormPasswordVisibilityIconShow: "sl-eye sl-eye--show",
  kcFormPasswordVisibilityIconHide: "sl-eye sl-eye--hide",
  kcAlertClass: "sl-alert",
  kcAlertTitleClass: "sl-alert__title",
  kcFeedbackSuccessIcon: "sl-feedback-icon sl-feedback-icon--success",
  kcFeedbackWarningIcon: "sl-feedback-icon sl-feedback-icon--warning",
  kcFeedbackErrorIcon: "sl-feedback-icon sl-feedback-icon--error",
  kcFeedbackInfoIcon: "sl-feedback-icon sl-feedback-icon--info",
  kcSignUpClass: "sl-sign-up",
  kcInfoAreaWrapperClass: "sl-info__inner",
  kcFormSocialAccountSectionClass: "sl-social",
  kcFormSocialAccountListClass: "sl-social__list",
  kcFormSocialAccountListGridClass: "sl-social__list--grid",
  kcFormSocialAccountListButtonClass: "sl-button sl-button--secondary sl-button--block",
  kcFormSocialAccountNameClass: "sl-social__name",
  kcFormSocialAccountGridItem: "sl-social__item",
  kcFormSocialAccountLinkClass: "sl-social__link",
  kcSelectAuthListClass: "sl-auth-list",
  kcSelectAuthListItemClass: "sl-auth-item",
  kcSelectAuthListItemIconClass: "sl-auth-item__icon",
  kcSelectAuthListItemIconPropertyClass: "sl-auth-item__icon-mark",
  kcSelectAuthListItemBodyClass: "sl-auth-item__body",
  kcSelectAuthListItemHeadingClass: "sl-auth-item__title",
  kcSelectAuthListItemDescriptionClass: "sl-auth-item__description",
  kcSelectAuthListItemFillClass: "sl-auth-item__fill",
  kcSelectAuthListItemArrowClass: "sl-auth-item__arrow",
  kcSelectAuthListItemArrowIconClass: "sl-auth-item__arrow-mark",
  kcSelectAuthListItemTitle: "sl-auth-list__title",
  kcWebAuthnKeyIcon: "sl-key-icon",
  kcWebAuthnDefaultIcon: "sl-key-icon",
  kcWebAuthnUnknownIcon: "sl-key-icon",
  kcWebAuthnUSB: "sl-key-icon",
  kcWebAuthnNFC: "sl-key-icon",
  kcWebAuthnBLE: "sl-key-icon",
  kcWebAuthnInternal: "sl-key-icon",
  kcAuthenticatorDefaultClass: "sl-authenticator-icon",
  kcAuthenticatorPasswordClass: "sl-authenticator-icon",
  kcAuthenticatorOTPClass: "sl-authenticator-icon",
  kcAuthenticatorWebAuthnClass: "sl-authenticator-icon",
  kcAuthenticatorWebAuthnPasswordlessClass: "sl-authenticator-icon",
  kcLoginOTPListClass: "sl-otp-list",
  kcLoginOTPListInputClass: "sl-otp-list__input",
  kcLoginOTPListItemHeaderClass: "sl-otp-list__header",
  kcLoginOTPListItemIconBodyClass: "sl-otp-list__icon",
  kcLoginOTPListItemIconClass: "sl-authenticator-icon",
  kcLoginOTPListItemTitleClass: "sl-otp-list__title",
  kcInputClassRadio: "sl-choice",
  kcInputClassRadioInput: "sl-choice__input",
  kcInputClassRadioLabel: "sl-choice__label",
  kcInputClassCheckbox: "sl-choice",
  kcInputClassCheckboxInput: "sl-choice__input",
  kcInputClassCheckboxLabel: "sl-choice__label",
  kcInputClassRadioCheckboxLabelDisabled: "sl-choice__label--disabled",
  kcCheckboxInputClass: "sl-choice__input",
  kcCheckClass: "sl-choice",
  kcCheckInputClass: "sl-choice__input",
  kcCheckLabelClass: "sl-choice__label",
  kcRecoveryCodesWarning: "sl-recovery-warning",
  kcRecoveryCodesList: "sl-recovery-list",
  kcRecoveryCodesActions: "sl-actions",
  kcRecoveryCodesConfirmation: "sl-choice",
  kcSrOnlyClass: "sl-sr-only",
  kcResetFlowIcon: "sl-reset-icon",
  kcFormGroupHeader: "sl-section-title",
  kcContentWrapperClass: "sl-content-grid"
} satisfies { [key in ClassKey]?: string };
