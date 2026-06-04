*** Settings ***
Documentation       Valid login scenario for https://www.saucedemo.com
...                 A correct user reaches the inventory (Products) page.

Resource            ../resources/saucedemo.resource

Test Setup          Open SauceDemo Login Page
Test Teardown       Close SauceDemo

Test Tags           login


*** Test Cases ***
Valid Login Succeeds
    [Documentation]    Logging in with valid credentials lands on the inventory page.
    [Tags]    positive    smoke
    Login With Credentials    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Inventory Page Should Be Open
