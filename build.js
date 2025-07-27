const esbuild = require('esbuild');
const path = require('path');
const fs = require('fs');

async function build() {
  console.log('Bundling application with esbuild...');

  try {
    // This tells esbuild to start at index.js, bundle everything,
    // target Node.js, and output a single file.
    await esbuild.build({
      entryPoints: ['index.js'],
      bundle: true,
      platform: 'node',
      target: 'node22', // Target your Node.js version
      outfile: 'dist/main.js',
      format: 'cjs', // CommonJS format is required for SEA
    });

    console.log('Application bundled successfully to dist/main.js');

    // --- SEA Creation Steps ---
    
    // 1. Create SEA config pointing to the bundled file
    const seaConfig = {
      main: 'dist/main.js', // Use the bundled file
      output: 'dist/piosk.blob',
      disableExperimentalSEAWarning: true,
      assets: {
        "web/index.html": "./web/index.html",
        "web/script.js": "./web/script.js"
      }
    };
    fs.writeFileSync('sea-config.json', JSON.stringify(seaConfig, null, 2));
    console.log('Created sea-config.json');

  } catch (error) {
    console.error('Build failed:', error);
    process.exit(1);
  }
}

build();
