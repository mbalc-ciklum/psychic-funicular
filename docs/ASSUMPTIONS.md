# Assumptions & environment notes

## Assumptions

1. **Credentials.** SauceDemo publishes its accepted usernames and the shared password (`secret_sauce`) directly on the login page.
   The "valid" test uses `standard_user` / `secret_sauce`.
   These are public demo credentials, so committing them is acceptable; in a real project they would come from a secret
   store / environment variables.

2. **Definition of "invalid login" (data-driven).** The negative case is implemented as a **data-driven** suite (`tests/invalid_login.robot`)
   covering several distinct rejection scenarios, each asserting the exact error banner and that the user stays on the login page:

   | Scenario         | Credentials                        | Expected message                                                            |
   |------------------|------------------------------------|-----------------------------------------------------------------------------|
   | Unknown user     | `invalid_user` / `wrong_password`  | `Epic sadface: Username and password do not match any user in this service` |
   | Locked-out user  | `locked_out_user` / `secret_sauce` | `Epic sadface: Sorry, this user has been locked out.`                       |
   | Missing username | `${EMPTY}` / `secret_sauce`        | `Epic sadface: Username is required`                                        |
   | Missing password | `standard_user` / `${EMPTY}`       | `Epic sadface: Password is required`                                        |
   | Empty form       | `${EMPTY}` / `${EMPTY}`            | `Epic sadface: Username is required`                                        |

3. **Definition of "successful login"** Success is asserted by landing on `inventory.html` **and** the presence of that page's landmark elements, not by
   a URL change alone.

4. **Driver management** Selenium Manager (bundled with Selenium 4) is expected to download the correct `chromedriver`/`geckodriver` on first run. This needs
   outbound internet access.

5. **Browsers installed** The host is expected to have Chrome and/or Firefox installed. The default run exercises both in parallel (via pabot), set
   `BROWSER` to run only one.

6. **XPath** locators are used, for better maintainability I use relative XPaths anchored to stable elements rather than absolute paths from the root.

7. **uv available** Tooling is managed with uv. The host is expected to have uv installed (it provisions Python and all dependencies). A pip fallback exists
   via `requirements.txt` for the runtime dependencies.

8. **Strict linting** Robocop linter is configured with `select = ALL` and `threshold = I`, i.e. *every* rule at every severity must pass.

9. **Test data placement** Credentials, expected messages and the sample inventory product name are centralized in `resources/test_constants.resource`.
   `resources/environment.resource` has browser/session/platform configuration and reusable environment keywords

10. **Facade and page URLs** Test suites import `resources/saucedemo.resource`, which re-exports environment keywords, Page Objects and constants.
   Page URLs live in their corresponding Page Object resources (`LOGIN_URL` in`login_page.resource`, `INVENTORY_URL` in `inventory_page.resource`).

## Environment notes

* **Validated on:** Linux, Python 3.14 (via uv), Google Chrome 149,
  Firefox 151 (Snap), uv 0.10.0, Robot Framework 7.4.2, SeleniumLibrary 6.9.0, Selenium 4.44.0, robotframework-robocop 8.2.9, robotframework-pabot 5.2.2

* **Result:** The full suite (1 happy path + 5 data-driven negative scenarios) passes on both Chrome and Firefox in parallel

* **Firefox on Snap (host-specific)** When Firefox is installed as a Snap (Ubuntu and derivatives), geckodriver is handed the `/usr/bin/firefox` wrapper script and rejects it
  ("binary is not a Firefox executable"). As a workaround I point to real binary via `${FIREFOX_BINARY}` (`/snap/firefox/current/usr/lib/firefox/firefox`), which
  `run_tests.sh` auto-detects this on Linux. A `Error terminating service process` may be logged at teardown — it is the Snap sandbox refusing the SIGTERM
  and does not affect results. Non-Snap Firefox installs need none of this.

* **Chrome `localhost` DevTools quirk — ESET Web Access Protection** I added a workaround for ESET localhost filter as a Python library
  to demonstrate implementing platform specific workarounds and functionality as Python libraries and using them from Robot.
  It also serves as a case study in diagnosing and working around a real-world environment issue that caused ChromeDriver sessions to fail on my laptop.
  ```text
  Bakcground:
  On my laptop direct localhost communication is being blocked by corporate antivirus setting. The ChromeDriver could not reach a freshly launched Chrome
  ("session not created: from chrome not reachable" and would hang).
  ESET Endpoint Antivirus' Web Access Protection** (kernel module `eset_wap`, daemon `wapd`) performs HTTP-aware filtering of *loopback* traffic and drops
  DevTools requests whose `Host:` header is `localhost`, while the IP literal `127.0.0.1` passes:
  curl http://127.0.0.1:<port>/json/version   ->  200 OK (JSON)
  curl http://localhost:<port>/json/version   ->  dropped (empty)
  ```
