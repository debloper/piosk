const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const sea = require('node:sea');

const app = express();
const PORT = 80;

// --- Universal Asset Handling ---
// Check if we are running inside a Single Executable Application
const IS_SEA = sea.isSea();

// When running as a binary, the config should be next to it.
// When running as a script, it's in the project root.
const basePath = IS_SEA ? path.dirname(process.execPath) : __dirname;
const configPath = path.join(basePath, 'config.json');

app.use(express.json());

// --- Serve Frontend Assets ---

// Serve the main HTML page
app.get('/', (req, res) => {
  try {
    if (IS_SEA) {
      // Production mode: Serve from embedded asset
      const htmlContent = sea.getAsset('web/index.html', 'utf8');
      res.setHeader('Content-Type', 'text/html');
      res.send(htmlContent);
    } else {
      // Development mode: Serve from file system
      res.sendFile(path.join(__dirname, 'web', 'index.html'));
    }
  } catch (error) {
    console.error("Failed to serve index.html", error);
    res.status(500).send('Could not load page.');
  }
});

// Serve the main JavaScript file
app.get('/script.js', (req, res) => {
  try {
    if (IS_SEA) {
      // Production mode: Serve from embedded asset
      const jsContent = sea.getAsset('web/script.js', 'utf8');
      res.setHeader('Content-Type', 'application/javascript');
      res.send(jsContent);
    } else {
      // Development mode: Serve from file system
      res.sendFile(path.join(__dirname, 'web', 'script.js'));
    }
  } catch (error) {
    console.error("Failed to serve script.js", error);
    res.status(500).send('Could not load script.');
  }
});

// --- API Endpoints for Configuration ---

app.get('/config', (req, res) => {
  fs.readFile(configPath, 'utf8', (err, data) => {
    if (err) {
      if (err.code === 'ENOENT') {
        // If config doesn't exist, send empty array to allow setup
        return res.json({ urls: [] });
      }
      console.error('Error reading config file:', err);
      return res.status(500).send('Could not read configuration.');
    }
    res.setHeader('Content-Type', 'application/json');
    res.send(data);
  });
});

app.post('/config', (req, res) => {
  if (typeof req.body !== 'object' || req.body === null) {
    return res.status(400).send('Invalid configuration format.');
  }

  const newConfig = JSON.stringify(req.body, null, "  ");
  fs.writeFile(configPath, newConfig, 'utf8', err => {
    if (err) {
      console.error('Error writing config file:', err);
      return res.status(500).send('Could not save config.');
    }

    // --- Reboot Logic ---
    // First, send a success response to the client.
    res.status(200).send("Configuration saved successfully. System will now restart.");

    // Then, execute the reboot command only if running as the final binary.
    if (IS_SEA) {
      console.log("Configuration saved. Rebooting system to apply changes.");
      exec('sudo reboot', (error, stdout, stderr) => {
        if (error) {
          console.error(`Reboot exec error: ${error}`);
          return;
        }
      });
    } else {
      console.log("Configuration saved. In development mode, reboot is skipped.");
    }
  });
});

app.listen(PORT, (err) => {
  if (err) {
    console.error("Failed to start server:", err);
    return;
  }
  console.log(`PiOSK dashboard server listening at http://localhost:${PORT}`);
});

