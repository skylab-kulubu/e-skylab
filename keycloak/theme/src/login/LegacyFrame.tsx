import type { ReactNode } from "react";
import skyLabLogoUrl from "../assets/skylab-logo.png";
import skyLabWatermarkUrl from "../assets/skylab-watermark.svg";

type LegacyFrameProps = {
  children: ReactNode;
  description: ReactNode;
  kvkkLinkText: ReactNode;
  kvkkPrefix: ReactNode;
  kvkkSuffix: ReactNode;
  mainId: string;
  skipToContent: string;
  title: ReactNode;
  titleId: string;
};

export default function LegacyFrame(props: LegacyFrameProps) {
  const {
    children,
    description,
    kvkkLinkText,
    kvkkPrefix,
    kvkkSuffix,
    mainId,
    skipToContent,
    title,
    titleId
  } = props;

  return (
    <div className="sl-legacy-shell">
      <a
        className="sl-legacy-skip-link"
        href={`#${mainId}`}
        onClick={event => {
          event.preventDefault();
          document.getElementById(mainId)?.focus();
        }}
      >
        {skipToContent}
      </a>

      <div className="sl-legacy-background" aria-hidden="true">
        <span className="sl-legacy-background__layers" />
        <span className="sl-legacy-background__iris" />
        <span className="sl-legacy-background__stars" />
        <img className="sl-legacy-background__mark" src={skyLabWatermarkUrl} alt="" />
        <span className="sl-legacy-background__grain" />
      </div>

      <main id={mainId} className="sl-legacy-main" tabIndex={-1}>
        <div className="sl-legacy-stack">
          <header className="sl-legacy-logo">
            <img src={skyLabLogoUrl} alt="SKY LAB" />
          </header>

          <section className="sl-legacy-card" aria-labelledby={titleId}>
            <div className="sl-legacy-intro">
              <h1 id={titleId}>{title}</h1>
              <p>{description}</p>
            </div>

            {children}
          </section>

          <footer className="sl-legacy-footer" role="contentinfo">
            <p>
              {kvkkPrefix}
              <a href="https://skyl.app/kvkk-metni" target="_blank" rel="noreferrer">
                {kvkkLinkText}
              </a>
              {kvkkSuffix}
            </p>
            <strong>e-skylab by WEBLAB</strong>
            <span className="sl-legacy-credit">Developed by Yusuf Açmacı</span>
          </footer>
        </div>
      </main>
    </div>
  );
}
