*** Settings ***
Documentation       Data-driven invalid login scenarios for https://www.saucedemo.com
...
...                 Each test case is one row of data (credentials + expected error)
...                 executed through the shared Login Should Be Rejected With
...                 template, which submits the credentials and asserts the login is
...                 rejected on the login page with the exact expected message

Resource            ../resources/saucedemo.resource

Test Setup          Open SauceDemo Login Page
Test Teardown       Close SauceDemo
Test Template       Login Should Be Rejected With

Test Tags           login    negative


*** Test Cases ***    USERNAME    PASSWORD    EXPECTED ERROR MESSAGE
Reject Unknown User
    [Documentation]    Credentials that match no user are rejected
    ${INVALID_USERNAME}    ${INVALID_PASSWORD}    ${INVALID_LOGIN_MESSAGE}
Reject Locked Out User
    [Documentation]    A valid but locked-out account is blocked
    ${LOCKED_USERNAME}    ${VALID_PASSWORD}    ${LOCKED_OUT_MESSAGE}
Reject Missing Username
    [Documentation]    A missing username is reported before authentication
    ${EMPTY}    ${VALID_PASSWORD}    ${USERNAME_REQUIRED_MESSAGE}
Reject Missing Password
    [Documentation]    A missing password is reported before authentication
    ${VALID_USERNAME}    ${EMPTY}    ${PASSWORD_REQUIRED_MESSAGE}
Reject Empty Credentials
    [Documentation]    Submitting an empty form reports the username error
    ${EMPTY}    ${EMPTY}    ${USERNAME_REQUIRED_MESSAGE}
