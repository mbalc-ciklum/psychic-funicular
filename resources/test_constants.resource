*** Settings ***
Documentation       Test constants shared across suites.
...                 Contains test data (credentials + expected messages)


*** Variables ***
# Credentials
# credentials are the ones publicly published on the SauceDemo login page.
${VALID_USERNAME: str}                  standard_user
${VALID_PASSWORD: str}                  secret_sauce
${LOCKED_USERNAME: str}                 locked_out_user
${INVALID_USERNAME: str}                invalid_user
${INVALID_PASSWORD: str}                wrong_password

# Expected error messages (for data-driven negative scenarios)
${INVALID_LOGIN_MESSAGE: str}           Epic sadface: Username and password do not match any user in this service
${LOCKED_OUT_MESSAGE: str}              Epic sadface: Sorry, this user has been locked out.
${USERNAME_REQUIRED_MESSAGE: str}       Epic sadface: Username is required
${PASSWORD_REQUIRED_MESSAGE: str}       Epic sadface: Password is required

# For parameterized locator example
${INVENTORY_SAMPLE_PRODUCT: str}        Sauce Labs Backpack
