# SauceDemo Login Automation — Robot Framework + SeleniumLibrary

Automated UI tests for the login flow of <https://www.saucedemo.com>, built with **Robot Framework** and **SeleniumLibrary** using the **Page Object** pattern and
**relative XPath** locators (anchored to stable `data-test` attributes). The page is very well covered by both `id`s and `data-test` attributes, so I additionaly contrived a scenario that needed a more complicated locator.

Dependencies and tooling are managed with **[uv](https://docs.astral.sh/uv/)**,the code is kept formated by the **[Robocop](https://robocop.dev)** linter and formatter under a **strict, all-rules** configuration, and the suite runs on
**Chrome and Firefox in parallel** via **[pabot](https://github.com/mkorpela/pabot)**.

The two expected scenarios are covered, with the negative case expanded into a
**data-driven** suite:

| Test case(s)                | What it verifies                                                            |
| --------------------------- | --------------------------------------------------------------------------- |
| **Valid Login Succeeds**    | A correct user logs in and lands on the inventory (Products) page.          |
| **Invalid login** (5 cases) | Unknown user, locked-out account, missing username, missing password and empty form are each rejected with the exact expected error, staying on the login page. |

The suite runs with **Chrome** and **Firefox** on both **Windows** and **Linux**.

---

## Project layout

```
Project/
├── .github/workflows/
|   └──└── robot-tests.yml           # Example Github Action worflow defition that runs the tests
├── tests/
│   ├── valid_login.robot            # Happy path login scenario
│   └── invalid_login.robot          # Data-driven invalid login scenarios
├── resources/
│   ├── saucedemo.resource           # Suite-facing facade imported by tests
│   ├── environment.resource         # Env/runtime only: browser lifecycle + options
│   ├── test_constants.resource      # Test data constants (credentials/messages/sample product)
│   └── pages/                       # Page Objects (locators + page-specific keywords)
│       ├── login_page.resource      # Login page (relative XPath locators)
│       └── inventory_page.resource  # Inventory page shown after a successful login
├── args/
│   ├── chrome.args                  # pabot argument file for chrome
│   └── firefox.args                 # pabot argument file for firefox
├── pyproject.toml                   # uv project and dependencies + strict Robocop config
├── uv.lock                          #
├── requirements.txt                 # Pip fallback (runtime deps only)
├── run_tests.sh / run_tests.bat     # Parallel Chrome+Firefox runners (Linux/macOS & Windows)
├── lint.sh                          # Robocop linter runner
├── docs/
│   ├── DESIGN.md                    # Design decisions & how the locators were obtained
│   └── ASSUMPTIONS.md               # Assumptions and environment notes
└── README.md
```

* `tests/` describes *what* is tested in the highest level keywords (closest to business language)
* `resources/saucedemo.resource` is the suite-facing facade that tests import
* `resources/pages/` contain *how* to interact with each page (locators and action keywords)
* `resources/test_constants.resource` holds shared test data constants
* `resources/environment.resource` owns environment/runtime behavior (browser lifecycle, options, platform workarounds), so test data and environment plumbing stay cleanly separated

---

## Prerequisites

* **[uv](https://docs.astral.sh/uv/)** installed —
  uv provisions a matching Python interpreter and all dependencies for you.
* **Google Chrome** and/or **Mozilla Firefox** installed.
* Internet access (the target site and Selenium Manager's driver downloads).

> Driver binaries (`chromedriver` / `geckodriver`) are resolved automatically
> by Selenium Manager (bundled with Selenium 4), so no manual setup is needed.

Install uv (if you don't have it):

```bash
# Linux / macOS
curl -LsSf https://astral.sh/uv/install.sh | sh
# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

---

## Setup

```bash
# From the project root — creates .venv and installs runtime + dev deps from uv.lock
uv sync
```

No manual virtual-environment activation is needed; commands are run through `uv run`.

> **Pip fallback** (no uv): `python -m venv venv && . venv/bin/activate &&
> pip install -r requirements.txt` (runtime deps only; add Robocop with
> `pip install robotframework-robocop` for linting).

---

## Running the tests

### Easiest — use the runner script

```bash
./run_tests.sh                    # Chrome + Firefox in PARALLEL (headless, default)
BROWSER=chrome ./run_tests.sh     # a single browser only (chrome or firefox)
HEADLESS=False ./run_tests.sh     # show the browser window(s)
```

On Windows:

```bat
run_tests.bat                       :: Chrome + Firefox in parallel
set BROWSER=firefox & run_tests.bat :: single browser
```

The default run uses **pabot** to execute the suite on both browsers concurrently
and merges everything into one report under `results/`.

### Or call `robot` / `pabot` through uv directly

```bash
# Single browser
uv run robot --variable BROWSER:chrome --outputdir results tests/
uv run robot --variable BROWSER:firefox --outputdir results tests/

# Both browsers in parallel (merged report)
uv run pabot --argumentfile1 args/chrome.args --argumentfile2 args/firefox.args \
    --outputdir results tests/

# Visible Chrome
uv run robot --variable BROWSER:chrome --variable HEADLESS:False --outputdir results tests/

# A single test
uv run robot --test "Valid Login Succeeds" --outputdir results tests/
```

Reports are written to `results/` (`report.html`, `log.html`, `output.xml`)


### Configuration variables

All are overridable from the command line with `--variable NAME:value`:

| Variable               | Default      | Purpose                                                                                                                                  |
| ------------------------| --------------| ------------------------------------------------------------------------------------------------------------------------------------------|
| `BROWSER`              | `chrome`     | `chrome` or `firefox`                                                                                                                    |
| `HEADLESS`             | `True`       | Run without a visible window                                                                                                             |
| `SELENIUM_TIMEOUT`     | `10 seconds` | Default wait timeout                                                                                                                     |
| `REMOTE_DEBUG_ADDRESS` | *(empty)*    | Attach to an already-running Chrome at `host:port` instead of launching one (see notes)                                                  |
| `FIREFOX_BINARY`       | *(empty)*    | Explicit Firefox binary path for hosts where geckodriver can't auto-detect it (e.g. Snap). The Linux runner auto-detects the Snap binary |

---

## Linting (Robocop)

The project is configured for the strictest Robocop analysis: the *entire*
built-in rule set is enabled (`select = ALL`) and **any** finding fails the run (`threshold = I`).
The configuration lives in `pyproject.toml` under `[tool.robocop.lint]` / `[tool.robocop.format]`

```bash
./lint.sh             # strict lint — fails on any finding
./lint.sh --format    # lint + verify formatting
./lint.sh --fix       # apply the formatter, then lint

# Install the Git pre-commit hook (run once after cloning / git init)
uv run pre-commit install

# Run the pre-commit hook manually against all tracked files
uv run pre-commit run --all-files

# or call Robocop directly
uv run robocop check          # lint
uv run robocop format --check # formatting check (no changes)
uv run robocop format         # apply formatting
```

---

### GitHub Actions

The repository includes sample GitHub Action `.github/workflows/robot-tests.yml` for CI execution.

The workflow installs dependencies with `uv`, runs Robocop linting, verifies
Robot Framework formatting, performs a dry run, executes the UI tests on Chrome
and Firefox, and uploads Robot reports as artifacts. A daily early-morning UTC
`schedule` trigger is included in the YAML but commented out/disabled.

---

See [`docs/ASSUMPTIONS.md`](docs/ASSUMPTIONS.md) for environment-specific notes (`localhost`/IPv6 Chrome quirk and the `REMOTE_DEBUG_ADDRESS` workaround it motivated, plus the Snap-Firefox `FIREFOX_BINARY` handling)
