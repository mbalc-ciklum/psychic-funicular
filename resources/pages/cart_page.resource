*** Settings ***
Documentation       Cart page keywords

Library             Collections
Library             SeleniumLibrary


*** Variables ***
${CART_URL: str}                https://www.saucedemo.com/cart.html
${CART_ITEM_NAME: str}          xpath=//*[@data-test='inventory-item-name']
${CART_CHECKOUT_BUTTON: str}    xpath=//button[@data-test='checkout']


*** Keywords ***
Cart Page Should Be Open
    [Documentation]    Cart page check
    Wait Until Location Contains    cart.html    timeout=${SELENIUM_TIMEOUT}
    Wait Until Element Is Visible    ${CART_CHECKOUT_BUTTON}

Get Items In Basket
    [Documentation]    Returns the visible product names in basket
    @{name_elements: Any}=    Get WebElements    ${CART_ITEM_NAME}
    @{names: str}=    Evaluate    [element.text for element in $name_elements]
    RETURN    ${names}

Verify Selected Items In Basket
    [Documentation]    Basket items check against expected list of items (unordered)
    [Arguments]    ${expected_items: list}
    Cart Page Should Be Open
    @{basket_items: str}=    Get Items In Basket
    ${expected_count: int}=    Get Length    ${expected_items}
    Length Should Be    ${basket_items}    ${expected_count}
    ...    msg=Basket should contain ${expected_count} items but has ${basket_items}
    FOR    ${item: str}    IN    @{expected_items}
        List Should Contain Value    ${basket_items}    ${item}
        ...    msg=Expected item '${item}' is missing from the basket ${basket_items}
    END

Proceed To Checkout
    [Documentation]    Starts the checkout flow from basket page
    Wait Until Element Is Visible    ${CART_CHECKOUT_BUTTON}
    Click Element    ${CART_CHECKOUT_BUTTON}
