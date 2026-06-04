# Design notes & reasoning

This document records why the framework looks the way it does.

## 1. Layered Page Object design

```
tests/valid_login.robot   tests/invalid_login.robot   (data-driven)
            │  import                  │  import
            └──────────────┬───────────┘
                           ▼
              resources/saucedemo.resource
              (single suite-facing facade)
                 │ imports runtime APIs
                 ├── resources/environment.resource   ← browser lifecycle and options
                 │ imports page APIs
                 ├── resources/pages/*.resource       ← one Page Object per page
                 │ imports shared test data
                 └── resources/test_constants.resource ← credentials, messages, sample product
```

* **Tests** are written in business language and contain no locators and no direct Selenium calls.
* **Page Objects** (`resources/pages/`) are the only place that knows about element locators and page-specific interactions.
  Each page exposes specific keywords (`Input Username`, `Submit Login`, `Inventory Page Should Be Open` ...)
* **`saucedemo.resource`** is the single resource imported by test suites. It re-exports environment/runtime keywords,
  Page Object keywords and test data.
* **`environment.resource`** centralises environment/runtime behavior (browser options, lifecycle, platform workarounds)
  so tests and page objects are isolated from execution specific concerns.
* **`test_constants.resource`** centralizes test data (credentials, expected messages, sample product name)

## 2. XPath locators

I use **XPath** locators to locate the page elements.
Every locator is XPath, written as a **relative** expression anchored to a stable attribute (`id` / `data-test`)
for example:

```
${LOGIN_USERNAME_INPUT}   xpath=//input[@id='user-name']
${LOGIN_ERROR_MESSAGE}    xpath=//h3[@data-test='error']
${INVENTORY_PAGE_TITLE}   xpath=//*[@data-test='title']
```
My reasoning behind this choice:
Relative, attribute-anchored XPaths are far more robust than absolute paths(`/html/body/div[1]/div[1]/...`),
which break on any structural markup anywhere along the tree. Where an element has no stable attribute of its own, it is
located by anchoring on a nearby element that does (see the anchor-based demonstration below).

## 3. Cross-browser & cross-platform strategy

* **Browser choice** is a variable (`${BROWSER}`), defaulting to `chrome` and
  switchable to `firefox` from the command line.
* **`Resolve Browser Options`** builds the Selenium `options` string per browser:
  * Chrome: `--headless=new`, `--no-sandbox`, `--disable-dev-shm-usage`,
    `--window-size=1920,1080`
  * Firefox: `-headless`, `--width/--height`
* **Parallel cross-browser execution** is provided by **pabot**: `run_tests.sh` /
  `run_tests.bat` run the suite on Chrome and Firefox **concurrently** (two
  argument files in `args/`, labelled `Chrome` / `Firefox`, more can be added to add additional parallel configurations)
  and merge the results into a single report. Setting `BROWSER` evn variable runs just one browser.
* **Driver management** is delegated to **Selenium Manager**, which downloads the matching `chromedriver`/`geckodriver` for the
  host OS automatically. This removes any platform-specific driver setup.
* **Firefox binary override** (`${FIREFOX_BINARY}`) handles environments where
  geckodriver cannot auto-detect Firefox — notably **Snap** installs, which expose
  a wrapper script instead of the real binary. The Linux runner auto-detects the
  Snap binary. The variable is empty (and unused) everywhere else.
* **Headless** is the default so the same command works on developer machines and on headless CI agents; set `HEADLESS:False` to watch the run.

## 4. Test independence

`Test Setup`/`Test Teardown` open a fresh browser before each test and close it afterwards, so the cases cannot influence one another.
If we would be mutating some backend state (e.g. adding items to cart, changing user settings), we would want to reset that state in the teardown as well, to ensure a clean slate for the next test.

## 5. Assertions

* **Valid login** asserts the URL contains `inventory.html` *and* that the inventory page's landmark elements (title "Products", menu button, cart link,
  and a sample product's *Add to cart* button located via the product-name anchor) are present — i.e. login truly succeeded, not just a URL change.
  The sample product validation is more of a example to show parameterized locators than a actual assertion that I would normally use for basic login flow,
  but it does add confidence that the page is fully loaded and rendered.
* **Invalid login** is **data-driven**: the `Login Should Be Rejected With` template is exercised with several credential sets — unknown user, locked-out
  account, missing username, missing password and an empty form — each asserting the exact expected error banner *and* that the browser stayed on the login URL
  (see `tests/invalid_login.robot`).

### Anchor-based locator demonstration

`inventory_page.resource` includes a realistic example of locating an element by **anchoring on a nearby element that carries a stable attribute**, rather than on
the target's own (brittle) attribute. It also shows my preferred way of anchoring inside a filter and keeping the main locator flow only one way down the tree,
for better readability and maintainability. (no `..` or `ancestor::` axes)

The keyword `Add To Cart Button Locator` builds the locator for a product's *Add to cart* button from the product's **visible name**

```
xpath=//*[@data-test='inventory-item-description' and .//*[@data-test='inventory-item-name' and normalize-space()='Sauce Labs Backpack']]//button
```

## 6. Tooling & code quality

### Dependency management — uv

Dependencies and the Python toolchain are managed with **[uv](https://docs.astral.sh/uv/)**:

* `pyproject.toml` declares the runtime dependencies (`[project.dependencies]`) and the dev tooling (`[dependency-groups].dev` Robocop).
* `uv.lock` pins exact, hash-verified versions for **reproducible** installs across machines and CI.
* `uv sync` creates `.venv` and installs everything; tests/lint run via `uv run`, so there is no manual environment activation.

A `requirements.txt` is kept only as a pip fallback for environments without uv.

### Parallel execution — pabot

`robotframework-pabot` runs the suite on **Chrome and Firefox in parallel**. Each browser is described by a small argument file (`args/chrome.args`,
`args/firefox.args`) passed to pabot as `--argumentfile1` / `--argumentfile2` pabot executes them concurrently and merges everything into one report.
More targets (e.g. different platforms, or a headless vs headed pair) can be added by creating more argument files and passing them to pabot.

### Linting & formatting — Robocop (strict)

The code is analysed by **[Robocop](https://robocop.dev)** (linter + formatter),
configured in `pyproject.toml` for the strictest practical setting:

```toml
[tool.robocop.lint]
select = ["ALL"]            # every built-in rule, incl. non-default ones
threshold = "I"            # any finding (down to Info severity) fails the run
```
