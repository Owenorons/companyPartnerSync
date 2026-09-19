const { defineConfig } = require("eslint/config");
const eslintJs = require("@eslint/js");
const jestPlugin = require("eslint-plugin-jest");
const auraConfig = require("@salesforce/eslint-plugin-aura");
const lwcConfig = require("@salesforce/eslint-config-lwc");
const globals = require("globals");

module.exports = defineConfig([
  // Reference sample code (not our maintained source — see
  // tools/metadata-builder/codeSamples/*/README.md for origin)
  {
    ignores: ["tools/metadata-builder/codeSamples/**"]
  },

  // Aura configuration
  {
    files: ["**/aura/**/*.js"],
    extends: [...auraConfig.configs.recommended, ...auraConfig.configs.locker]
  },

  // LWC configuration. The Salesforce package exports flat-config arrays,
  // so apply them directly instead of nesting them inside `extends`.
  ...lwcConfig.configs.recommended.map((config) => ({
    ...config,
    files: ["**/lwc/**/*.js"]
  })),

  // LWC configuration with override for LWC test files
  {
    files: ["**/lwc/**/*.test.js"],
    rules: {
      "@lwc/lwc/no-unexpected-wire-adapter-usages": "off"
    },
    languageOptions: {
      globals: {
        ...globals.node
      }
    }
  },

  // Jest mocks configuration
  {
    files: ["**/jest-mocks/**/*.js"],
    languageOptions: {
      sourceType: "module",
      ecmaVersion: "latest",
      globals: {
        ...globals.node,
        ...globals.es2021,
        ...jestPlugin.environments.globals.globals
      }
    },
    plugins: {
      eslintJs
    },
    extends: ["eslintJs/recommended"]
  }
]);
