module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/core/tests/**/*.test.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
    '\.\./fetcher': '<rootDir>/core/fetcher.web',
    '\./fetcher': '<rootDir>/core/fetcher.web',
    '\.\./logger': '<rootDir>/core/logger',
    '\./logger': '<rootDir>/core/logger',
    'react-native': '<rootDir>/tests/mocks/react-native.js',
  },
};
