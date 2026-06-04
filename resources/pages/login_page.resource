*** Settings ***
Documentation       Page Object for the SauceDemo **Login** page
...
...                 All element locators are expressed as relative XPath (id or data-test attributes based)

Library             SeleniumLibrary


*** Variables ***
${LOGIN_URL: str}               https://www.saucedemo.com/
${LOGIN_USERNAME_INPUT: str}    xpath=//*[@data-test='username']
${LOGIN_PASSWORD_INPUT: str}    xpath=//*[@data-test='password']
${LOGIN_SUBMIT_BUTTON: str}     xpath=//*[@data-test='login-button']
${LOGIN_ERROR_MESSAGE: str}     xpath=//h3[@data-test='error']


*** Keywords ***
Login Page Should Be Open
    [Documentation]    Verifies that the login form is rendered and ready for input.
    Wait Until Element Is Visible    ${LOGIN_USERNAME_INPUT}
    Wait Until Element Is Visible    ${LOGIN_PASSWORD_INPUT}
    Wait Until Element Is Visible    ${LOGIN_SUBMIT_BUTTON}

Input Username
    [Documentation]    Types the given username into the username field.
    [Arguments]    ${username: str}
    Wait Until Element Is Visible    ${LOGIN_USERNAME_INPUT}
    Input Text    ${LOGIN_USERNAME_INPUT}    ${username}

Input Password
    [Documentation]    Types the given password into the password field.
    [Arguments]    ${password: str}
    Wait Until Element Is Visible    ${LOGIN_PASSWORD_INPUT}
    Input Text    ${LOGIN_PASSWORD_INPUT}    ${password}

Submit Login
    [Documentation]    Clicks the login (submit) button.
    Wait Until Element Is Visible    ${LOGIN_SUBMIT_BUTTON}
    Click Element    ${LOGIN_SUBMIT_BUTTON}

Login With Credentials
    [Documentation]    Convenience keyword that fills both fields and submits.
    [Arguments]    ${username: str}    ${password: str}
    Input Username    ${username}
    Input Password    ${password}
    Submit Login

Login Error Should Be Displayed
    [Documentation]    Asserts inline login error banner is visible, non-empty and
    ...                exactly matches the expected message.
    [Arguments]    ${expected_message: str}
    Wait Until Element Is Visible    ${LOGIN_ERROR_MESSAGE}
    ${actual: str}=    Get Text    ${LOGIN_ERROR_MESSAGE}
    Should Not Be Empty    ${actual}    The login error banner is empty.
    Should Be Equal    ${actual}    ${expected_message}

Login Should Be Rejected With
    [Documentation]    Data-driven negative-login check: submits the given
    ...                credentials and asserts the attempt is rejected on the login
    ...                page with the exact expected error message.
    [Arguments]    ${username: str}    ${password: str}    ${expected_message: str}
    Login With Credentials    ${username}    ${password}
    Login Error Should Be Displayed    ${expected_message}
    Location Should Be    ${LOGIN_URL}
