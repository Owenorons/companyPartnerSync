import { createElement } from "@lwc/engine-dom";
import PsLogo from "c/psLogo";

const mockNavigate = jest.fn();

jest.mock("lightning/navigation", () => {
  const Navigate = Symbol("Navigate");

  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate](...args) {
        mockNavigate(...args);
      }
    };
  NavigationMixin.Navigate = Navigate;

  return { NavigationMixin };
});

describe("c-ps-logo", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the text wordmark when no logo image is configured", () => {
    const element = createElement("c-ps-logo", { is: PsLogo });
    element.wordmark = "PartnerSync";

    document.body.appendChild(element);

    const wordmark = element.shadowRoot.querySelector(".logo-wordmark");
    expect(wordmark.textContent).toBe("PartnerSync");
    expect(element.shadowRoot.querySelector(".logo-image")).toBeNull();
  });

  it("renders the logo image when a logo URL is configured", () => {
    const element = createElement("c-ps-logo", { is: PsLogo });
    element.logoUrl = "/resource/PartnerSync_Logo";
    element.wordmark = "PartnerSync";

    document.body.appendChild(element);

    const image = element.shadowRoot.querySelector(".logo-image");
    expect(image.src).toContain("/resource/PartnerSync_Logo");
    expect(element.shadowRoot.querySelector(".logo-wordmark")).toBeNull();
  });

  it("navigates to the configured home page on click", () => {
    const element = createElement("c-ps-logo", { is: PsLogo });
    element.homePageName = "Home";

    document.body.appendChild(element);

    element.shadowRoot.querySelector(".logo-link").click();

    expect(mockNavigate).toHaveBeenCalledWith({
      type: "comm__namedPage",
      attributes: { name: "Home" }
    });
  });

  it("does not navigate when no home page name is configured", () => {
    const element = createElement("c-ps-logo", { is: PsLogo });
    element.homePageName = "";

    document.body.appendChild(element);

    const link = element.shadowRoot.querySelector(".logo-link");
    expect(link.classList).toContain("is-static");

    link.click();

    expect(mockNavigate).not.toHaveBeenCalled();
  });
});
