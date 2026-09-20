import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { KcPage } from "./kc.gen";

const root = document.getElementById("root");

if (root === null) {
  throw new Error("Missing theme root");
}

if (window.kcContext === undefined && import.meta.env.DEV) {
  const { getDevKcContext } = await import("./devKcContext");
  window.kcContext = getDevKcContext();
}

createRoot(root).render(
  <StrictMode>
    {window.kcContext === undefined ? (
      <main className="sl-fallback" aria-labelledby="sl-fallback-title">
        <h1 id="sl-fallback-title">SKY LAB Hesap</h1>
        <p>Kimlik doğrulama ekranı yalnızca SKY LAB giriş hizmeti üzerinden açılır.</p>
      </main>
    ) : (
      <KcPage kcContext={window.kcContext} />
    )}
  </StrictMode>
);
