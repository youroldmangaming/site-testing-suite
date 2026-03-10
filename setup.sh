#!/usr/bin/env bash
# =============================================================================
# setup.sh - Create, configure and build the Selenium test suite
# Usage: bash setup.sh [target-directory]  (default: current directory)
# =============================================================================

set -e

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*"; exit 1; }
header()  { echo -e "\n${GREEN}--- $* ---${RESET}"; }

# Target directory
TARGET="${1:-.}"

if [ "$TARGET" != "." ] && [ -d "$TARGET" ]; then
  warn "Directory '$TARGET' already exists."
  read -rp "Overwrite? (y/N) " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

mkdir -p "$TARGET"/{tests,utils,config}
cd "$TARGET"

# Pre-flight
header "Pre-flight checks"
docker info > /dev/null 2>&1 || error "Docker is not running. Please start Docker and try again."
success "Docker is running"

# Helper: write file and log it
write() { local f="$1"; shift; cat > "$f"; info "$f"; }

# =============================================================================
header "Creating project files"
# =============================================================================

write "package.json" << 'EOF'
{
  "name": "selenium-demo",
  "version": "1.0.0",
  "description": "Selenium GUI tests for the applitools/demo site",
  "scripts": {
    "test": "mocha 'tests/**/*.test.js' --timeout 60000 --reporter spec",
    "test:login": "mocha tests/login.test.js --timeout 60000",
    "test:smoke": "mocha tests/visual.test.js --timeout 60000",
    "test:chrome": "BROWSER=chrome mocha tests/login.test.js tests/visual.test.js --timeout 60000",
    "test:edge": "BROWSER=edge mocha tests/login.test.js tests/visual.test.js --timeout 60000",
    "test:cross-browser": "mocha tests/cross-browser.test.js --timeout 120000"
  },
  "dependencies": {
    "selenium-webdriver": "^4.18.1",
    "dotenv": "^16.4.5"
  },
  "devDependencies": {
    "mocha": "^10.4.0",
    "chai": "^5.1.1"
  }
}
EOF

write ".gitignore" << 'EOF'
node_modules/
.env
*.log
EOF

write ".dockerignore" << 'EOF'
node_modules/
*.log
.git/
EOF

write "Dockerfile" << 'EOF'
FROM node:20-slim

RUN apt-get update && apt-get install -y \
    wget curl gnupg ca-certificates \
    fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 \
    libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
    libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 \
    libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 \
    libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 \
    libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
    libxss1 libxtst6 lsb-release xdg-utils \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /tmp/chrome.deb \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y /tmp/chrome.deb \
    && rm /tmp/chrome.deb && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
       https://packages.microsoft.com/repos/edge stable main" \
       > /etc/apt/sources.list.d/microsoft-edge.list \
    && apt-get update \
    && apt-get install -y microsoft-edge-stable \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "test"]
EOF

write "docker-compose.yml" << 'EOF'
services:
  selenium-tests:
    build: .
    image: auto-test
    volumes:
      - ./config/.env:/app/.env
    environment:
      - HEADLESS=true
      - BROWSER=${BROWSER:-chrome}
    cap_add:
      - SYS_ADMIN
    shm_size: "2gb"
EOF

write "config/urls.js" << 'EOF'
const BASE_URL = 'https://applitools.github.io/demo';

const URLS = {
  home:   `${BASE_URL}/index.html`,
  login:  `${BASE_URL}/TestPages/LoginPage/index.html`,
  form:   `${BASE_URL}/TestPages/FormPage/index.html`,
  canvas: `${BASE_URL}/TestPages/CanvasPage/index.html`,
  dom:    `${BASE_URL}/DomSnapshot/index.html`,
  mobile: `${BASE_URL}/MobileEmulation/index.html`,
};

const LOGIN = {
  username:   '#username',
  password:   '#password',
  loginBtn:   '#log-in',
  rememberMe: '#remember-me',
  errorMsg:   '.alert-warning',
};

module.exports = { URLS, LOGIN };
EOF

write "config/.env.example" << 'EOF'
BROWSER=chrome
HEADLESS=true
EOF

write "config/.gitignore" << 'EOF'
.env
EOF

write "utils/driver.js" << 'EOF'
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
EOF

write "tests/login.test.js" << 'EOF'
require('dotenv').config();
const { expect } = require('chai');
const { By, until } = require('selenium-webdriver');
const { buildDriver } = require('../utils/driver');
const { URLS, LOGIN } = require('../config/urls');

describe('Login Page', function () {
  let driver;

  beforeEach(async function () {
    driver = await buildDriver();
    await driver.get(URLS.login);
    await driver.wait(until.elementLocated(By.css(LOGIN.loginBtn)), 10000);
  });

  afterEach(async function () {
    if (driver) await driver.quit();
  });

  it('renders the username and password fields', async function () {
    const username = await driver.findElement(By.css(LOGIN.username));
    const password = await driver.findElement(By.css(LOGIN.password));
    expect(await username.isDisplayed()).to.be.true;
    expect(await password.isDisplayed()).to.be.true;
  });

  it('renders the login button', async function () {
    const btn = await driver.findElement(By.css(LOGIN.loginBtn));
    expect(await btn.isDisplayed()).to.be.true;
    expect(await btn.isEnabled()).to.be.true;
  });

  it('shows an error when submitting empty credentials', async function () {
    await driver.findElement(By.css(LOGIN.loginBtn)).click();
    const error = await driver.wait(
      until.elementIsVisible(driver.findElement(By.css(LOGIN.errorMsg))), 5000
    );
    expect(await error.isDisplayed()).to.be.true;
  });

  it('accepts input in username and password fields', async function () {
    await driver.findElement(By.css(LOGIN.username)).sendKeys('admin');
    await driver.findElement(By.css(LOGIN.password)).sendKeys('password123');
    expect(await driver.findElement(By.css(LOGIN.username)).getAttribute('value')).to.equal('admin');
    expect(await driver.findElement(By.css(LOGIN.password)).getAttribute('value')).to.equal('password123');
  });

  it('clears fields after clearing input', async function () {
    const field = await driver.findElement(By.css(LOGIN.username));
    await field.sendKeys('admin');
    await field.clear();
    expect(await field.getAttribute('value')).to.equal('');
  });

  it('navigates away from the login page on valid login', async function () {
    await driver.findElement(By.css(LOGIN.username)).sendKeys('admin');
    await driver.findElement(By.css(LOGIN.password)).sendKeys('admin');
    await driver.findElement(By.css(LOGIN.loginBtn)).click();
    await driver.sleep(1500);
    const currentUrl = await driver.getCurrentUrl();
    const pageSource = await driver.getPageSource();
    const loggedIn =
      !currentUrl.includes('LoginPage') ||
      pageSource.includes('logged') ||
      pageSource.includes('welcome');
    expect(loggedIn).to.be.true;
  });
});
EOF

write "tests/visual.test.js" << 'EOF'
require('dotenv').config();
const { expect } = require('chai');
const { By, until } = require('selenium-webdriver');
const { buildDriver } = require('../utils/driver');
const { URLS } = require('../config/urls');

describe('Demo Site - Page Smoke Tests', function () {
  let driver;

  beforeEach(async function () {
    driver = await buildDriver();
  });

  afterEach(async function () {
    if (driver) await driver.quit();
  });

  it('home page loads and has a title', async function () {
    await driver.get(URLS.home);
    expect(await driver.getTitle()).to.not.be.empty;
  });

  it('form page renders at least one input', async function () {
    await driver.get(URLS.form);
    await driver.wait(until.elementLocated(By.css('input, select, textarea')), 10000);
    const inputs = await driver.findElements(By.css('input, select, textarea'));
    expect(inputs.length).to.be.greaterThan(0);
  });

  it('canvas page contains a canvas element', async function () {
    await driver.get(URLS.canvas);
    await driver.wait(until.elementLocated(By.css('canvas')), 10000);
    const canvases = await driver.findElements(By.css('canvas'));
    expect(canvases.length).to.be.greaterThan(0);
  });

  it('mobile emulation page loads', async function () {
    await driver.get(URLS.mobile);
    expect(await driver.getTitle()).to.not.be.empty;
  });

  it('dom snapshot page loads', async function () {
    await driver.get(URLS.dom);
    expect(await driver.getTitle()).to.not.be.empty;
  });
});
EOF

write "tests/cross-browser.test.js" << 'EOF'
require('dotenv').config();
const { expect } = require('chai');
const { By, until } = require('selenium-webdriver');
const { buildDriver } = require('../utils/driver');
const { URLS, LOGIN } = require('../config/urls');

const BROWSERS = ['chrome', 'edge'];

BROWSERS.forEach((browser) => {
  describe(`[${browser.toUpperCase()}] Login Page`, function () {
    let driver;

    beforeEach(async function () {
      driver = await buildDriver(browser);
      await driver.get(URLS.login);
      await driver.wait(until.elementLocated(By.css(LOGIN.loginBtn)), 10000);
    });

    afterEach(async function () {
      if (driver) await driver.quit();
    });

    it('renders login form elements', async function () {
      const username = await driver.findElement(By.css(LOGIN.username));
      const password = await driver.findElement(By.css(LOGIN.password));
      const btn      = await driver.findElement(By.css(LOGIN.loginBtn));
      expect(await username.isDisplayed()).to.be.true;
      expect(await password.isDisplayed()).to.be.true;
      expect(await btn.isDisplayed()).to.be.true;
    });

    it('shows an error for empty credentials', async function () {
      await driver.findElement(By.css(LOGIN.loginBtn)).click();
      const error = await driver.wait(
        until.elementIsVisible(driver.findElement(By.css(LOGIN.errorMsg))), 5000
      );
      expect(await error.isDisplayed()).to.be.true;
    });

    it('accepts typed credentials', async function () {
      await driver.findElement(By.css(LOGIN.username)).sendKeys('admin');
      await driver.findElement(By.css(LOGIN.password)).sendKeys('secret');
      expect(
        await driver.findElement(By.css(LOGIN.username)).getAttribute('value')
      ).to.equal('admin');
    });
  });

  describe(`[${browser.toUpperCase()}] Page Smoke Tests`, function () {
    let driver;

    beforeEach(async function () {
      driver = await buildDriver(browser);
    });

    afterEach(async function () {
      if (driver) await driver.quit();
    });

    it('home page has a title', async function () {
      await driver.get(URLS.home);
      expect(await driver.getTitle()).to.not.be.empty;
    });

    it('form page has inputs', async function () {
      await driver.get(URLS.form);
      await driver.wait(until.elementLocated(By.css('input, select, textarea')), 10000);
      const inputs = await driver.findElements(By.css('input, select, textarea'));
      expect(inputs.length).to.be.greaterThan(0);
    });

    it('canvas page has a canvas element', async function () {
      await driver.get(URLS.canvas);
      await driver.wait(until.elementLocated(By.css('canvas')), 10000);
      const canvases = await driver.findElements(By.css('canvas'));
      expect(canvases.length).to.be.greaterThan(0);
    });
  });
});
EOF

write "build.sh" << 'EOF'
#!/usr/bin/env bash
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[done]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*"; exit 1; }

NO_CACHE=false
[ "$1" = "-n" ] || [ "$1" = "--no-cache" ] && NO_CACHE=true

[ -f "Dockerfile" ]         || error "Dockerfile not found. Run from the project root."
[ -f "docker-compose.yml" ] || error "docker-compose.yml not found."
docker info > /dev/null 2>&1 || error "Docker is not running."

info "Building image: auto-test"
BUILD_ARGS="--tag auto-test ."
$NO_CACHE && BUILD_ARGS="--no-cache $BUILD_ARGS"
docker build $BUILD_ARGS

success "Image built. Run ./run-tests.sh to execute the tests."
EOF

write "run-tests.sh" << 'EOF'
#!/usr/bin/env bash
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[done]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*"; exit 1; }

BROWSER="chrome"
SUITE="test"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--browser) BROWSER="$2"; shift 2 ;;
    -s|--suite)   SUITE="$2";   shift 2 ;;
    *) error "Unknown option: $1" ;;
  esac
done

[ -f "docker-compose.yml" ] || error "docker-compose.yml not found. Run from the project root."
docker info > /dev/null 2>&1 || error "Docker is not running."
[ "$BROWSER" = "both" ] && SUITE="test:cross-browser"

info "Browser: $BROWSER"
info "Suite:   npm run $SUITE"
echo ""

BROWSER="$BROWSER" docker compose run --rm selenium-tests npm run "$SUITE"
EXIT_CODE=$?
echo ""
[ $EXIT_CODE -eq 0 ] && success "All tests passed." || error "Tests failed (exit $EXIT_CODE)."
EOF

chmod +x build.sh run-tests.sh

# Create config/.env if missing
if [ ! -f "config/.env" ]; then
  cp config/.env.example config/.env
  info "config/.env created from example"
fi

# =============================================================================
header "Building Docker image"
# =============================================================================
docker build --tag auto-test .

# =============================================================================
header "Setup complete"
# =============================================================================
echo ""
success "All files created and image built."
echo ""
echo "  Run all tests:         ./run-tests.sh"
echo "  Run Edge only:         ./run-tests.sh -b edge"
echo "  Run both browsers:     ./run-tests.sh -b both"
echo "  Run login tests only:  ./run-tests.sh -s test:login"
echo "  Rebuild image:         ./build.sh"
echo ""



