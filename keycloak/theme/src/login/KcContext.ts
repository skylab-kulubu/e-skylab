/* eslint-disable @typescript-eslint/no-empty-object-type */
import type { ExtendKcContext } from "keycloakify/login";
import type { KcEnvName, ThemeName } from "../kc.gen";

export type KcContextExtension = {
  themeName: ThemeName;
  properties: Record<KcEnvName, string> & {};
};

export type KcContextExtensionPerPage = {
  "passkey-offer.ftl": {};
};

export type KcContext = ExtendKcContext<KcContextExtension, KcContextExtensionPerPage>;
