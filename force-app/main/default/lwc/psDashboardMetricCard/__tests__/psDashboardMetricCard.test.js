import { createElement } from "@lwc/engine-dom";
import PsDashboardMetricCard from "c/psDashboardMetricCard";

describe("c-ps-dashboard-metric-card", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the configured metric and icon label", () => {
    const element = createElement("c-ps-dashboard-metric-card", {
      is: PsDashboardMetricCard
    });
    element.label = "Open Deals";
    element.value = 12;
    element.iconName = "utility:opportunity";
    element.iconAlternativeText = "Open Deals";

    document.body.appendChild(element);

    const icon = element.shadowRoot.querySelector("lightning-icon");

    expect(element.shadowRoot.querySelector(".label").textContent).toBe(
      "Open Deals"
    );
    expect(element.shadowRoot.querySelector(".value").textContent).toBe("12");
    expect(icon.iconName).toBe("utility:opportunity");
    expect(icon.alternativeText).toBe("Open Deals");
  });
});
