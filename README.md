# 🤖 Selenium GUI Test Suite

> Automated cross-browser GUI testing for the [ACME Demo App](https://demo.applitools.com) and [Applitools demo pages](https://applitools.github.io/demo), containerised with Docker and driven by Selenium WebDriver, Mocha, and Chai.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Scripts](#scripts)
- [Running Tests](#running-tests)
- [Test Suites](#test-suites)
- [Configuration](#configuration)
- [Docker Architecture](#docker-architecture)
- [CI / GitHub Actions](#ci--github-actions)
- [Troubleshooting](#troubleshooting)
- [Lessons Learned](#lessons-learned)

---

## Overview

This project provides a fully containerised Selenium test environment targeting the Applitools demo applications. Tests run headlessly inside Docker using both **Google Chrome** and **Microsoft Edge**, with no external testing accounts or API keys required.

<img width="849" height="1079" alt="image" src="https://github.com/user-attachments/assets/9ed2d437-9a86-452f-95db-a299dd532722" />







The suite covers:

- **Login page** — form rendering, input acceptance, field clearing, and successful navigation
- **App page** — post-login dashboard smoke test
- **Static demo pages** — home, mobile emulation page load checks
- **Cross-browser** — all of the above verified on Chrome and Edge in a single run

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| [Selenium WebDriver 4](https://www.selenium.dev/) | Browser automation |
| [Mocha](https://mochajs.org/) | Test runner |
| [Chai](https://www.chaijs.com/) | Assertions |
| [Node.js 20](https://nodejs.org/) | Runtime |
| [Docker](https://www.docker.com/) | Containerised environment |
| Google Chrome 145+ | Primary test browser |
| Microsoft Edge 145+ | Secondary test browser |

> **No Applitools account needed.** Applitools Eyes was deliberately removed in favour of plain Selenium assertions. If you want visual AI diffing, it can be added back easily.

---

## Project Structure

```
.
├── config/
│   ├── urls.js            # Page URLs and CSS selectors
│   ├── .env               # Local config (git-ignored)
│   └── .env.example       # Config template
├── tests/
│   ├── login.test.js      # Login page functional tests
│   ├── visual.test.js     # Page smoke tests
│   └── cross-browser.test.js  # Chrome + Edge combined suite
├── utils/
│   └── driver.js          # Chrome / Edge WebDriver factory
├── Dockerfile             # Node 20 + Chrome + Edge image
├── docker-compose.yml     # Container config with volume mount
├── setup.sh               # One-shot installer and builder
├── build.sh               # Rebuild the Docker image
├── run-tests.sh           # Run tests via docker compose
└── package.json
```

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Docker | 20+ |
| Docker Compose | v2 (`docker compose`) |
| Bash | Any modern version |

> No local Node.js or browser installation required — everything runs inside the container.

---

## Quick Start

```bash
# 1. Clone the repo
git clone <your-repo-url>
cd <repo-directory>

# 2. Run the installer — creates all files and builds the Docker image
bash setup.sh

# 3. Run the tests
./run-tests.sh
```

That's it. The installer handles everything including the Docker build.

---

## Scripts

### `setup.sh`

One-shot installer. Creates all project files, sets up `config/.env`, and builds the Docker image.

```bash
# Install into current directory
bash setup.sh

# Install into a new named directory
bash setup.sh my-test-project
```

### `build.sh`

Rebuilds the Docker image. Use this after making changes to `Dockerfile`, `package.json`, or test files.

```bash
./build.sh            # Standard rebuild (uses layer cache)
./build.sh --no-cache # Force completely fresh build
```

### `run-tests.sh`

Runs the test suite via `docker compose`.

```bash
./run-tests.sh                         # Chrome, all suites
./run-tests.sh -b edge                 # Edge only
./run-tests.sh -b both                 # Chrome + Edge (cross-browser suite)
./run-tests.sh -s test:login           # Login suite only
./run-tests.sh -s test:smoke           # Smoke tests only
./run-tests.sh -b edge -s test:login   # Combine flags
```

**Available `-s` values:**

| Flag | What runs |
|------|-----------|
| `test` | All suites (default) |
| `test:login` | Login page tests |
| `test:smoke` | Page smoke tests |
| `test:cross-browser` | Chrome + Edge combined |

---

## Running Tests

### Standard run

```bash
./run-tests.sh
```

### Target a specific browser

```bash
./run-tests.sh -b chrome
./run-tests.sh -b edge
```

### Run both browsers simultaneously

```bash
./run-tests.sh -b both
# equivalent to: ./run-tests.sh -s test:cross-browser
```

### Run with a visible browser window

The container runs headlessly by default. To disable headless mode (requires a display on the host):

```bash
# Edit config/.env
HEADLESS=false
./run-tests.sh
```

---

## Test Suites

### `tests/login.test.js`

Functional tests for the [ACME Demo App](https://demo.applitools.com) login page.

| Test | Description |
|------|-------------|
| renders the username field | Checks `#username` is visible |
| renders the password field | Checks `#password` is visible |
| renders the login button | Checks `#log-in` is visible |
| accepts input in username and password fields | Types and reads back values |
| clears fields after clearing input | Verifies `field.clear()` empties the field |
| login button navigates to the app page | Clicks login, asserts URL contains `app` |

> **Note:** The ACME demo login has no server-side validation — any credentials navigate to `app.html`. Tests are written to match this actual behaviour.

### `tests/visual.test.js`

Smoke tests confirming key pages load without errors.

| Test | URL |
|------|-----|
| login page loads with a title | `demo.applitools.com` |
| app page loads after login | `demo.applitools.com/app.html` |
| home page loads with a title | `applitools.github.io/demo/` |
| mobile emulation page loads | `applitools.github.io/demo/MobileEmulation/` |

### `tests/cross-browser.test.js`

Runs login and smoke tests on **both Chrome and Edge** in a single Mocha run. Each test is prefixed with `[CHROME]` or `[EDGE]` in the output.

---

## Configuration

Config is stored in `config/.env` which is mounted into the container at runtime. It is **never baked into the Docker image**.

```bash
# config/.env
BROWSER=chrome    # chrome | edge
HEADLESS=true     # true | false
```

Copy the template to get started:

```bash
cp config/.env.example config/.env
```

Environment variables can also be passed inline:

```bash
BROWSER=edge ./run-tests.sh
```

---

## Docker Architecture

### Why Docker?

- **Reproducible** — same Chrome and Edge versions every time, on any host
- **No local setup** — no need to install Node, Chrome, or Edge locally
- **Isolated** — won't interfere with other containers or services on the host
- **CI-ready** — the same `docker compose` command works locally and in pipelines

### How secrets are handled

`docker-compose.yml` mounts **only** `config/.env` directly to `/app/.env` inside the container:

```yaml
volumes:
  - ./config/.env:/app/.env
```

This avoids mounting the entire `config/` directory, which would overwrite `config/urls.js` inside the image. The `.env` file is git-ignored and never committed.

### Key Docker settings

```yaml
cap_add:
  - SYS_ADMIN    # Required for Chrome/Edge sandbox inside Docker
shm_size: "2gb"  # Prevents browser crashes from shared memory exhaustion
```

### Image size

The built image is approximately **1.7 GB** due to Chrome and Edge being installed from their official repos inside the container.

---

## CI / GitHub Actions

Add this workflow to `.github/workflows/test.yml`:

```yaml
name: Selenium Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Create config/.env
        run: cp config/.env.example config/.env

      - name: Build Docker image
        run: ./build.sh

      - name: Run tests — Chrome
        run: ./run-tests.sh -b chrome

      - name: Run tests — Edge
        run: ./run-tests.sh -b edge
```

> The runner needs Docker available. `ubuntu-latest` on GitHub Actions includes Docker by default.

---

## Troubleshooting

### `SessionNotCreatedError: This version of ChromeDriver only supports Chrome version X`

**Cause:** A pinned `chromedriver` npm package is mismatched with the Chrome version in the image.

**Fix:** Remove `chromedriver` from `package.json`. Selenium Manager (built into `selenium-webdriver` 4.6+) automatically downloads the correct driver.

---

### `Cannot find module '../config/urls'`

**Cause:** The `config/` directory was mounted as a Docker volume, overwriting `urls.js` inside the container.

**Fix:** Mount only the `.env` file, not the whole directory:

```yaml
# docker-compose.yml
volumes:
  - ./config/.env:/app/.env   # correct
  # - ./config:/config        # wrong — overwrites urls.js
```

---

### `TimeoutError: Waiting for element to be located`

**Cause 1:** Wrong URL — the element doesn't exist on that page.

**Fix:** Verify URLs in `config/urls.js`. The login form lives at `https://demo.applitools.com`, not the `applitools.github.io` static pages.

**Cause 2:** Page not fully loaded before the test runs.

**Fix:** Use `driver.wait(until.elementLocated(...), 15000)` in `before()` hooks before interacting with any elements.

---

### `Timed out receiving message from renderer`

**Cause:** Too many browser sessions created back-to-back inside the container, exhausting shared memory.

**Fix:** Use `before`/`after` (once per suite) instead of `beforeEach`/`afterEach` (once per test) to share a single driver instance across tests in the same describe block.

```js
// Good — one browser per suite
before(async function () { driver = await buildDriver(); });
after(async function () { await driver.quit(); });

// Risky inside Docker — one browser per test
beforeEach(async function () { driver = await buildDriver(); });
afterEach(async function () { await driver.quit(); });
```

---

### `NoSuchElementError` for `.alert-warning`

**Cause:** The ACME demo login page has no real server-side validation. The login button is an `<a>` tag that always navigates to `app.html` regardless of credentials — there is no error message element.

**Fix:** Remove error state tests, or point tests at a different demo app that has real validation.

---

## Lessons Learned

A few things discovered during setup that aren't obvious from the docs:

1. **Don't pin `chromedriver`** — Selenium Manager handles driver versioning automatically and will always match the installed browser.

2. **Mount files, not directories** — Mounting `./config:/config` as a volume overwrites everything inside `/app/config` in the container, including `urls.js`. Always mount the specific file you need.

3. **`demo.applitools.com` ≠ `applitools.github.io/demo`** — These are two different things. The GitHub Pages site is a set of simple static HTML test pages. The real demo app with a login form lives at `demo.applitools.com`.

4. **The ACME login has no validation** — The login button is a plain link. Any username and password will navigate to `app.html`. Write tests that match what the app actually does, not what you expect it to do.

5. **Share the driver inside Docker** — Creating a new browser session per test (`beforeEach`) works fine locally but causes renderer timeouts inside Docker under load. Share one driver per `describe` block using `before`/`after`.

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-new-tests`
3. Add your tests in `tests/`
4. Run the suite: `./run-tests.sh`
5. Open a pull request

---

## License

MIT
