import { createElement } from "@lwc/engine-dom";
import PsOperationsConsole from "c/psOperationsConsole";
import getOperationsHealth from "@salesforce/apex/PartnerSyncOperationsConsoleController.getOperationsHealth";
import retryDeadLetter from "@salesforce/apex/PartnerSyncOperationsConsoleController.retryDeadLetter";
import acknowledgeDeadLetter from "@salesforce/apex/PartnerSyncOperationsConsoleController.acknowledgeDeadLetter";

function mockWireAdapter() {
  const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  return { default: createApexTestWireAdapter(jest.fn()) };
}

jest.mock(
  "@salesforce/apex/PartnerSyncOperationsConsoleController.getOperationsHealth",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/PartnerSyncOperationsConsoleController.retryDeadLetter",
  () => ({ default: jest.fn(() => Promise.resolve()) }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/PartnerSyncOperationsConsoleController.acknowledgeDeadLetter",
  () => ({ default: jest.fn(() => Promise.resolve()) }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex",
  () => ({ refreshApex: jest.fn(() => Promise.resolve()) }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const HEALTH = {
  newDeadLetterCount: 2,
  failedDeadLetterCount: 1,
  retriedDeadLetterCount: 3,
  deadLetters: [
    {
      dlqId: "a0Yxx000000001",
      eventType: "DealSubmitted",
      status: "New",
      retryCount: 0,
      errorMessage: "Timeout calling downstream service."
    }
  ],
  aiFailedInteractionCount: 1,
  aiBlockedInteractionCount: 0,
  aiProposedRecommendationCount: 4,
  aiFailedRecommendationCount: 1
};

describe("c-ps-operations-console", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders health metric tiles and dead-letter rows", async () => {
    const element = createElement("c-ps-operations-console", {
      is: PsOperationsConsole
    });
    document.body.appendChild(element);

    getOperationsHealth.emit(HEALTH);
    await flushPromises();

    const tiles = element.shadowRoot.querySelectorAll(
      "c-ps-dashboard-metric-card"
    );
    expect(tiles).toHaveLength(7);
    expect(tiles[0].value).toBe(2);

    const cards = element.shadowRoot.querySelectorAll(".queue-card");
    expect(cards).toHaveLength(1);
  });

  it("retries a dead letter when the retry button is clicked", async () => {
    const element = createElement("c-ps-operations-console", {
      is: PsOperationsConsole
    });
    document.body.appendChild(element);

    getOperationsHealth.emit(HEALTH);
    await flushPromises();

    element.shadowRoot.querySelector(".action-button-retry").click();
    await flushPromises();

    expect(retryDeadLetter).toHaveBeenCalledWith({ dlqId: "a0Yxx000000001" });
  });

  it("acknowledges a dead letter when the acknowledge button is clicked", async () => {
    const element = createElement("c-ps-operations-console", {
      is: PsOperationsConsole
    });
    document.body.appendChild(element);

    getOperationsHealth.emit(HEALTH);
    await flushPromises();

    element.shadowRoot.querySelector(".action-button-acknowledge").click();
    await flushPromises();

    expect(acknowledgeDeadLetter).toHaveBeenCalledWith({
      dlqId: "a0Yxx000000001"
    });
  });

  it("shows an empty state when the dead-letter queue is clear", async () => {
    const element = createElement("c-ps-operations-console", {
      is: PsOperationsConsole
    });
    document.body.appendChild(element);

    getOperationsHealth.emit({ ...HEALTH, deadLetters: [] });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state").title).toBe(
      "Queue clear"
    );
  });

  it("shows an error panel when the health wire fails", async () => {
    const element = createElement("c-ps-operations-console", {
      is: PsOperationsConsole
    });
    document.body.appendChild(element);

    getOperationsHealth.error({
      body: { message: "Internal access required." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load the operations health summary."
    );
  });
});
