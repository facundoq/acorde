module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/core/tests/**/*.test.ts'],
  maxWorkers: 1, // Sequential execution
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
    '/fetcher$': '<rootDir>/core/fetcher.web',
    'react-native': '<rootDir>/tests/mocks/react-native.js',
  },
};
