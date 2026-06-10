*** Settings ***
Documentation       Shared environment configuration and browser lifecycle keywords.
...
...                 This resource contains only environment/runtime behavior.
...                 Test suites import resources/saucedemo.resource, which re-exports
...                 these keywords together with Page Objects and test constants.

Library             String
Library             ${CURDIR}/libraries/ChromeDevToolsLauncher.py
Library             SeleniumLibrary


*** Variables ***
# --- Runtime configuration (override from the CLI with --variable) -----------
# Browser: chrome | firefox    robot --variable BROWSER:firefox
${BROWSER: str}                 chrome
${HEADLESS: bool}               ${TRUE}
${SELENIUM_TIMEOUT: str}        10 seconds
${REMOTE_DEBUG_ADDRESS: str}    ${EMPTY}
${FIREFOX_BINARY: str}          ${EMPTY}

${CHROME_LOOPBACK_FIX: bool}    ${FALSE}

${WINDOW_WIDTH: int}            ${1920}
${WINDOW_HEIGHT: int}           ${1080}


*** Keywords ***
Open SauceDemo Login Page
    [Documentation]    Launches the configured browser, navigates to the login
    ...                page and waits until it is ready.
    IF    ${CHROME_LOOPBACK_FIX} and "chrome" in "${BROWSER}".lower()
        ${address: str}=    Start Chrome On Loopback    headless=${HEADLESS}
        VAR    ${options: str}=    add_experimental_option("debuggerAddress", "${address}")
    ELSE
        ${options: str}=    Resolve Browser Options
    END
    Open Browser    ${LOGIN_URL}    browser=${BROWSER}    options=${options}
    IF    ${CHROME_LOOPBACK_FIX} and "chrome" in "${BROWSER}".lower()
        Keep Attached Chrome Focused
    END
    Set Window Size    ${WINDOW_WIDTH}    ${WINDOW_HEIGHT}
    Set Selenium Timeout    ${SELENIUM_TIMEOUT}
    Login Page Should Be Open

Close SauceDemo
    [Documentation]    Closes every browser opened during the test (and any
    ...                loopback Chrome instance that was launched for it).
    Close All Browsers
    Stop All Loopback Chrome

Resolve Browser Options
    [Documentation]    Builds a SeleniumLibrary options string tailored to the
    ...                selected browser.
    ...
    ...                When ``REMOTE_DEBUG_ADDRESS`` is set, the driver
    ...                attaches to that already-running browser instead.
    ${browser: str}=    Convert To Lower Case    ${BROWSER}
    IF    "${REMOTE_DEBUG_ADDRESS}" != "" and "chrome" in "${browser}"
        RETURN    add_experimental_option("debuggerAddress", "${REMOTE_DEBUG_ADDRESS}")
    END
    IF    "firefox" in "${browser}"
        ${options: str}=    Catenate    SEPARATOR=;${SPACE}
        ...    add_argument("--width=1920")
        ...    add_argument("--height=1080")
        IF    ${HEADLESS}
            ${options: str}=    Catenate    SEPARATOR=;${SPACE}    ${options}    add_argument("-headless")
        END
        IF    "${FIREFOX_BINARY}" != ""
            ${options: str}=    Catenate    SEPARATOR=;${SPACE}    ${options}    binary_location="${FIREFOX_BINARY}"
        END
    ELSE
        ${options: str}=    Catenate    SEPARATOR=;${SPACE}
        ...    add_argument("--window-size=1920,1080")
        ...    add_argument("--incognito")
        ...    add_argument("--test-type")
        ...    add_argument("--no-sandbox")
        ...    add_argument("--disable-dev-shm-usage")
        ...    add_argument("--disable-gpu")
        ...    add_experimental_option("excludeSwitches", ["enable-automation"])
        IF    ${HEADLESS}
            ${options: str}=    Catenate    SEPARATOR=;${SPACE}    ${options}    add_argument("--headless=new")
        END
    END
    RETURN    ${options}
