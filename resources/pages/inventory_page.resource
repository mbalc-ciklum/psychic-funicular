*** Settings ***
Documentation       Page Object for the SauceDemo Inventory (Products) page shown after a successful login
...                 (https://www.saucedemo.com/inventory.html)
...
...                 All element locators are expressed as relative XPath (id or data-test attributes based)
...                 example element with parameterized locator and another element used as anchor.

Library             SeleniumLibrary


*** Variables ***
${INVENTORY_URL: str}               https://www.saucedemo.com/inventory.html
${INVENTORY_PAGE_TITLE: str}        xpath=//*[@data-test='title']
${INVENTORY_MENU_BUTTON: str}       xpath=//*[@data-test='open-menu']
${INVENTORY_CART_LINK: str}         xpath=//a[@data-test='shopping-cart-link']


*** Keywords ***
Inventory Page Should Be Open
    [Documentation]    Verifies that login succeeded by asserting we landed on the
    ...                inventory page and its key landmarks are present.
    Wait Until Location Contains    inventory.html    timeout=${SELENIUM_TIMEOUT}
    Wait Until Element Is Visible    ${INVENTORY_PAGE_TITLE}
    Element Text Should Be    ${INVENTORY_PAGE_TITLE}    Products
    Page Should Contain Element    ${INVENTORY_MENU_BUTTON}
    Page Should Contain Element    ${INVENTORY_CART_LINK}
    ${add_to_cart_button: str}=    Add To Cart Button Locator    ${INVENTORY_SAMPLE_PRODUCT}
    Page Should Contain Element    ${add_to_cart_button}

Add To Cart Button Locator
    [Documentation]    Builds a locator for the "Add to cart" button of the product identified by its visible name.
    ...                Used as a example of parameterized locator that cannot be expressed with a single static XPath
    ...                and is for a element based on non-id type locator. It uses my prefered locator syntax
    ...                with nested filters on an anchor parent element,
    ...                for better clarity (and stability in case new buttons are added in the future)
    ...                I could also add data-test filter on the button, in this case I opted for
    ...                a shorted locator instead.
    [Arguments]    ${product_name: str}
    ${locator: str}=    Catenate    SEPARATOR=${EMPTY}
    ...    xpath=//*[@data-test='inventory-item-description'
    ...    and .//*[@data-test='inventory-item-name' and normalize-space()="${product_name}"]]//button
    RETURN    ${locator}
