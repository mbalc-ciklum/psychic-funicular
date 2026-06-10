*** Settings ***
Documentation       Dynamic E2E Shopping & Price Validation
...                 1.    Successfully log in with a user, e.g. 'standard_user' (using your existing Page Objects).
...                 2.    Sort the products by 'Price (low to high)'. Select the second and third cheapest
...                 items dynamically (do not hardcode the item names) and add them to the basket.
...                 3.    Go to the basket, please verify that these two items are present,
...                 and then proceed to the checkout.
...                 4.    Fill out the checkout information. On the 'Overview' page, calculate the total
...                 price of the items and verify that it matches the 'Item total' displayed by the
...                 website (before tax).
...                 5.    Complete the purchase and please check that the success message appears.

Resource            ../resources/saucedemo.resource

Test Setup          Open SauceDemo Login Page
Test Teardown       Close SauceDemo


*** Test Cases ***
Dynamic Shopping with Price Validation
    [Documentation]    Dynamic E2E Shopping & Price Validation
    [Tags]    e2e    shopping
    Login With Credentials    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Sort Products By Price    ascending
    ${basket_items: list}=    Add Products To Basket By Index Range    2    3
    Go To Basket
    Verify Selected Items In Basket    ${basket_items}
    Proceed To Checkout
    Fill Checkout Information    Hans    Saucyson    1024
    Verify Item Total    ${basket_items}
    Complete Purchase
    Verify Purchase Success Message
