import { fireEvent } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import {
  installPasskeyRememberMeBridge,
  PASSKEY_REMEMBER_ME_INPUT_ID
} from "./rememberMeBridge";

describe("passkey remember-me bridge", () => {
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

  it("binds a remember-me checkbox rendered after the passkey form", async () => {
    document.body.innerHTML = '<form id="webauth"></form><div id="password-view"></div>';

    const cleanup = installPasskeyRememberMeBridge();
    const hidden = document.querySelector<HTMLInputElement>(`#${PASSKEY_REMEMBER_ME_INPUT_ID}`)!;
    expect(hidden.disabled).toBe(true);

    document.querySelector("#password-view")!.innerHTML = `
      <label><input id="rememberMe" name="rememberMe" type="checkbox" checked /> Beni hatırla</label>
    `;
    await new Promise(resolve => setTimeout(resolve));

    expect(hidden.disabled).toBe(false);
    fireEvent.click(document.querySelector<HTMLInputElement>("#rememberMe")!);
    expect(hidden.disabled).toBe(true);

    cleanup();
  });
});
