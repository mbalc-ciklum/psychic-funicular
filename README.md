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

The suite runs with **Chrome** and **Firefox** on both **Windows** and **Linux**