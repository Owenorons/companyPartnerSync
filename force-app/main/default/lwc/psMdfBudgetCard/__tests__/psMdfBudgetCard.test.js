import { createElement } from "@lwc/engine-dom";
import PsMdfBudgetCard from "c/psMdfBudgetCard";

describe("c-ps-mdf-budget-card", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders budget labels and used progress", () => {
    const element = createElement("c-ps-mdf-budget-card", {
      is: PsMdfBudgetCard
    });
    element.budget = {
      annualBudget: 10000,
      usedBudget: 2500,
      remainingBudget: 7500
    };

    document.body.appendChild(element);

    const fill = element.shadowRoot.querySelector(".ledger-progress .fill");
    const stats = Array.from(element.shadowRoot.querySelectorAll("strong"));

    expect(element.shadowRoot.querySelector("h2").textContent).toBe("$10,000");
    expect(fill.style.width).toBe("25%");
    expect(stats.map((stat) => stat.textContent)).toEqual(["$2,500", "$7,500"]);
  });
});
