import react from "@vitejs/plugin-react";
import { keycloakify } from "keycloakify/vite-plugin";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [
    react(),
    keycloakify({
      accountThemeImplementation: "none",
      themeName: "e-skylab-theme",
      keycloakVersionTargets: {
        "22-to-25": false,
        "all-other-versions": "e-skylab-theme-2.0.0.jar"
      }
    })
  ]
});
