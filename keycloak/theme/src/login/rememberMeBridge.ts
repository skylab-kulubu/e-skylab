import { useEffect } from "react";
import type { KcContext } from "./KcContext";

export const PASSKEY_REMEMBER_ME_INPUT_ID = "sl-passkey-remember-me";

export function installPasskeyRememberMeBridge(root: ParentNode = document): () => void {
  const passkeyForm = root.querySelector<HTMLFormElement>("form#webauth");
  if (passkeyForm === null) {
    return () => undefined;
  }

  const hiddenInput = document.createElement("input");
  hiddenInput.type = "hidden";
  hiddenInput.id = PASSKEY_REMEMBER_ME_INPUT_ID;
  hiddenInput.name = "rememberMe";
  hiddenInput.value = "on";
  passkeyForm.append(hiddenInput);

  let rememberMeCheckbox: HTMLInputElement | null = null;

  const sync = () => {
    const nextCheckbox = root.querySelector<HTMLInputElement>("input#rememberMe");
    if (nextCheckbox !== rememberMeCheckbox) {
      rememberMeCheckbox?.removeEventListener("change", sync);
      rememberMeCheckbox = nextCheckbox;
      rememberMeCheckbox?.addEventListener("change", sync);
    }
    hiddenInput.disabled = rememberMeCheckbox?.checked !== true;
  };

  sync();
  const observer = new MutationObserver(sync);
  observer.observe(root instanceof Document ? root.body : root, { childList: true, subtree: true });

  return () => {
    observer.disconnect();
    rememberMeCheckbox?.removeEventListener("change", sync);
    hiddenInput.remove();
  };
}

export function watchPasskeyRememberMeBridge(root: Document = document): () => void {
  let removeBridge: (() => void) | undefined;

  const installWhenReady = () => {
    if (removeBridge !== undefined || root.querySelector("form#webauth") === null) {
      return;
    }
    removeBridge = installPasskeyRememberMeBridge(root);
  };

  installWhenReady();
  const observer = new MutationObserver(installWhenReady);
  observer.observe(root.body, { childList: true, subtree: true });

  return () => {
    observer.disconnect();
    removeBridge?.();
  };
}

export function usePasskeyRememberMeBridge(kcContext: KcContext): void {
  useEffect(() => {
    if (kcContext.pageId !== "login.ftl" && kcContext.pageId !== "login-username.ftl") {
      return;
    }

    return watchPasskeyRememberMeBridge();
  }, [kcContext]);
}
