*** Settings ***
Documentation       Page Object for the SauceDemo checkout page

Library             SeleniumLibrary


*** Variables ***
${CHECKOUT_FIRST_NAME_INPUT: str}       xpath=//input[@data-test='firstName']
${CHECKOUT_LAST_NAME_INPUT: str}        xpath=//input[@data-test='lastName']
${CHECKOUT_ZIP_INPUT: str}              xpath=//input[@data-test='postalCode']
${CHECKOUT_CONTINUE_BUTTON: str}        xpath=//input[@data-test='continue']
${CHECKOUT_ITEM_TOTAL_LABEL: str}       xpath=//*[@data-test='subtotal-label']
${CHECKOUT_FINISH_BUTTON: str}          xpath=//button[@data-test='finish']
${CHECKOUT_COMPLETE_HEADER: str}        xpath=//*[@data-test='complete-header']


*** Keywords ***
Item Price Locator
    [Documentation]    locator builder for the price element of an order line identified by
    ...                product name, anchored on item name (can be partial match)
    [Arguments]    ${product_name: str}
    ${locator: str}=    Catenate    SEPARATOR=${EMPTY}
    ...    xpath=//*[@data-test='inventory-item'
    ...    and contains(normalize-space(),"${product_name}")]
    ...    //*[@data-test='inventory-item-price']
    RETURN    ${locator}

Get Item Price
    [Documentation]    Returns the numeric price of the given product on the overview page
    [Arguments]    ${product_name: str}
    ${locator: str}=    Item Price Locator    ${product_name}
    Wait Until Element Is Visible    ${locator}
    ${text: str}=    Get Text    ${locator}
    ${text: str}=    Evaluate    "${text}".replace("$", "").strip()
    ${price: float}=    Convert To Number    ${text}
    RETURN    ${price}

Get Displayed Item Total
    [Documentation]    Returns the numeric Item total before tax from the overview page
    Wait Until Element Is Visible    ${CHECKOUT_ITEM_TOTAL_LABEL}
    ${text: str}=    Get Text    ${CHECKOUT_ITEM_TOTAL_LABEL}
    ${text: str}=    Evaluate    "${text}".split("$")[-1].strip()
    ${total: float}=    Convert To Number    ${text}
    RETURN    ${total}

Fill Checkout Information
    [Documentation]    Fills the checkout information form and checks out
    [Arguments]    ${first_name: str}    ${last_name: str}    ${postal_code: str}
    Wait Until Element Is Visible    ${CHECKOUT_FIRST_NAME_INPUT}
    Input Text    ${CHECKOUT_FIRST_NAME_INPUT}    ${first_name}
    Input Text    ${CHECKOUT_LAST_NAME_INPUT}    ${last_name}
    Input Text    ${CHECKOUT_ZIP_INPUT}    ${postal_code}
    Click Element    ${CHECKOUT_CONTINUE_BUTTON}
    Wait Until Element Is Visible    ${CHECKOUT_ITEM_TOTAL_LABEL}

Verify Item Total
    [Documentation]    calculates the total price of the given items from their
    ...                displayed prices and asserts it
    [Arguments]    ${expected_items: list}
    VAR    ${calculated_total: float}=    ${0}
    FOR    ${product_name: str}    IN    @{expected_items}
        ${price: float}=    Get Item Price    ${product_name}
        ${calculated_total: float}=    Evaluate    ${calculated_total} + ${price}
    END
    ${displayed_total: float}=    Get Displayed Item Total
    Should Be Equal As Numbers    ${calculated_total}    ${displayed_total}    precision=2
    ...    msg=Calculated item total ${calculated_total} does not match displayed ${displayed_total}

Complete Purchase
    [Documentation]    Finishes the order from the overview page and waits for the completion page
    Wait Until Element Is Visible    ${CHECKOUT_FINISH_BUTTON}
    Click Element    ${CHECKOUT_FINISH_BUTTON}
    Wait Until Element Is Visible    ${CHECKOUT_COMPLETE_HEADER}

Verify Purchase Success Message
    [Documentation]    Asserts the order completion confirmation message
    [Arguments]    ${expected_message: str}=${PURCHASE_SUCCESS_MESSAGE}
    Wait Until Element Is Visible    ${CHECKOUT_COMPLETE_HEADER}
    ${actual: str}=    Get Text    ${CHECKOUT_COMPLETE_HEADER}
    Should Be Equal    ${actual}    ${expected_message}
