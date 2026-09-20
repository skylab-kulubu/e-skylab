import { describe, expect, it } from "vitest";
import css from "./theme.css?raw";

function relativeLuminance(hex: string): number {
  const normalized = hex.length === 4
    ? `#${[...hex.slice(1)].map(channel => channel.repeat(2)).join("")}`
    : hex;
  const channels = normalized
    .slice(1)
    .match(/.{2}/g)!
    .map(value => Number.parseInt(value, 16) / 255)
    .map(value => (value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4));

  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}

function cssRule(selector: string): string {
  const escapedSelector = selector.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = css.match(new RegExp(`${escapedSelector}\\s*\\{([^}]*)\\}`));
  expect(match, `missing CSS rule ${selector}`).not.toBeNull();
  return match![1];
}

function declaration(rule: string, property: string): string {
  const match = rule.match(new RegExp(`(?:^|;)\\s*${property}\\s*:\\s*([^;]+)`));
  expect(match, `missing CSS declaration ${property}`).not.toBeNull();
  return match![1].trim();
}

function resolveColor(value: string): string {
  const variable = value.match(/^var\((--[a-z0-9-]+)\)$/i)?.[1];
  const resolved = variable === undefined ? value : declaration(cssRule(":root"), variable);
  expect(resolved, `unsupported CSS color ${resolved}`).toMatch(/^#[0-9a-f]{3}(?:[0-9a-f]{3})?$/i);
  return resolved;
}

function contrastRatio(first: string, second: string): number {
  const lighter = Math.max(relativeLuminance(first), relativeLuminance(second));
  const darker = Math.min(relativeLuminance(first), relativeLuminance(second));
  return (lighter + 0.05) / (darker + 0.05);
}

describe("SKY LAB theme accessibility contract", () => {
  it("keeps primary and secondary button text at WCAG AA contrast", () => {
    for (const selector of [
      ".sl-button--primary",
      ".sl-button--primary:hover",
      ".sl-button--secondary",
      ".sl-button--secondary:hover"
    ]) {
      const rule = cssRule(selector);
      const foreground = resolveColor(declaration(rule, "color"));
      const background = resolveColor(declaration(rule, "background"));
      expect(contrastRatio(foreground, background), selector).toBeGreaterThanOrEqual(4.5);
    }
  });

  it("has explicit keyboard focus and reduced-motion behavior", () => {
    expect(css).toContain(":focus-visible");
    expect(css).toContain("@media (prefers-reduced-motion: reduce)");
    expect(css).toContain("animation: none");
  });

  it("does not regress the white secondary-button defect", () => {
    expect(css).toContain(".sl-button--secondary");
    expect(css).toContain("background: #292c39");
    expect(css).not.toMatch(/\.sl-button--secondary\s*\{[^}]*background:\s*(?:white|#fff(?:fff)?)/s);
  });
});
