import { fireEvent } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import {
  installPasskeyRememberMeBridge,
  PASSKEY_REMEMBER_ME_INPUT_ID
} from "./rememberMeBridge";

describe("conditional passkey remember-me bridge", () => {
  afterEach(() => {
    document.body.replaceChildren();
  });

  it("submits rememberMe only while the visible choice is selected", () => {
    document.body.innerHTML = `
      <form id="kc-form-login">
        <input id="rememberMe" name="rememberMe" type="checkbox" />
      </form>
      <form id="webauth"></form>
    `;

    const cleanup = installPasskeyRememberMeBridge();
    const checkbox = document.querySelector<HTMLInputElement>("#rememberMe")!;
    const hidden = document.querySelector<HTMLInputElement>(`#${PASSKEY_REMEMBER_ME_INPUT_ID}`)!;

    expect(hidden.name).toBe("rememberMe");
    expect(hidden.value).toBe("on");
    expect(hidden.disabled).toBe(true);

    fireEvent.click(checkbox);
    expect(hidden.disabled).toBe(false);

    fireEvent.click(checkbox);
    expect(hidden.disabled).toBe(true);

    cleanup();
    expect(document.querySelector(`#${PASSKEY_REMEMBER_ME_INPUT_ID}`)).toBeNull();
  });

  it("does nothing when conditional passkey markup is absent", () => {
    const cleanup = installPasskeyRememberMeBridge();
    expect(cleanup).toBeTypeOf("function");
    expect(document.querySelector(`#${PASSKEY_REMEMBER_ME_INPUT_ID}`)).toBeNull();
  });
});
