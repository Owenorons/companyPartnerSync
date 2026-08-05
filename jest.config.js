const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver", "<rootDir>/tools"],
  testPathIgnorePatterns: [
    ...jestConfig.testPathIgnorePatterns,
    "<rootDir>/tools"
  ],
  collectCoverageFrom: [
    "force-app/main/default/lwc/*/*.js",
    "!force-app/main/default/lwc/**/__tests__/**"
  ],
  coverageThreshold: {
    global: {
      branches: 60,
      functions: 75,
      lines: 80,
      statements: 80
    }
  },
  watchman: false,
  // Recent @lwc runtime packages are published as ESM. Salesforce's default
  // preset ignores most node_modules, so explicitly pass LWC packages through
  // the supplied transformer instead of asking Jest to execute raw `export`
  // syntax as CommonJS.
  transformIgnorePatterns: [
    "/node_modules/(?!(?:@lwc|@salesforce/sfdx-lwc-jest/src/lightning-stubs)/)"
  ]
};
