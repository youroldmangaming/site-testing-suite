require('dotenv').config();
const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const edge   = require('selenium-webdriver/edge');

const BROWSER = (process.env.BROWSER || 'chrome').toLowerCase();

async function buildDriver(browserOverride) {
  const browser  = browserOverride || BROWSER;
  const headless = process.env.HEADLESS !== 'false';
  const commonArgs = [
    '--no-sandbox', '--disable-dev-shm-usage',
    '--disable-gpu', '--window-size=1280,800',
  ];

  if (browser === 'edge') {
    const options = new edge.Options();
    if (headless) options.addArguments('--headless=new');
    options.addArguments(...commonArgs);
    const driver = await new Builder()
      .forBrowser('MicrosoftEdge').setEdgeOptions(options).build();
    await driver.manage().setTimeouts({ implicit: 10000, pageLoad: 30000 });
    return driver;
  }

  const options = new chrome.Options();
  if (headless) options.addArguments('--headless=new');
  options.addArguments(...commonArgs);
  const driver = await new Builder()
    .forBrowser('chrome').setChromeOptions(options).build();
  await driver.manage().setTimeouts({ implicit: 10000, pageLoad: 30000 });
  return driver;
}

module.exports = { buildDriver };
