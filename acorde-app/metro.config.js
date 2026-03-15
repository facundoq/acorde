const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
// This points to /home/facundoq/dev/acorde/acorde-core
const coreRoot = path.resolve(projectRoot, '../acorde-core');

const config = getDefaultConfig(projectRoot);

// 1. Add wasm to source and asset extensions
config.resolver.sourceExts.push('wasm');
config.resolver.assetExts.push('wasm');

// 2. Watch all files in the core library as well
config.watchFolders = [projectRoot, coreRoot];

// 2. Add search paths for node_modules and enable symlinks
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(coreRoot, 'node_modules'),
];

config.resolver.unstable_enableSymlinks = true;

module.exports = config;