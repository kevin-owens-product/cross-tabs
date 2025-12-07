module.exports = {
  preset: "ts-jest",
  testEnvironment: "jsdom",
  roots: ["<rootDir>/src"],
  testMatch: ["**/__tests__/**/*.test.ts", "**/__tests__/**/*.test.tsx"],
  moduleFileExtensions: ["ts", "tsx", "js", "jsx"],
  transform: {
    "^.+\\.(ts|tsx)$": "ts-jest",
  },
  setupFilesAfterEnv: ["<rootDir>/src/crosstab-builder/XB2/src/__tests__/setup.ts"],
  moduleNameMapper: {
    "\\.(css|scss|sass)$": "identity-obj-proxy",
  },
  collectCoverageFrom: [
    "src/crosstab-builder/XB2/src/**/*.{ts,tsx}",
    "!src/crosstab-builder/XB2/src/**/*.d.ts",
    "!src/crosstab-builder/XB2/src/**/__tests__/**",
  ],
};

