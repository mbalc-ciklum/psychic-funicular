*** Settings ***
Documentation       Page Object for the SauceDemo Inventory (Products) page shown after a successful login
...                 (https://www.saucedemo.com/inventory.html)
...
...                 All element locators are expressed as relative XPath (id or data-test attributes based)
...                 example element with parameterized locator and another element used as anchor.

Library             Collections
Library             SeleniumLibrary


*** Variables ***
${INVENTORY_URL: str}               https://www.saucedemo.com/inventory.html
${INVENTORY_PAGE_TITLE: str}        xpath=//*[@data-test='title']
${INVENTORY_MENU_BUTTON: str}       xpath=//*[@data-test='open-menu']
${INVENTORY_CART_LINK: str}         xpath=//a[@data-test='shopping-cart-link']
${INVENTORY_SORT_DROPDOWN: str}     xpath=//select[@data-test='product-sort-container']
${INVENTORY_ITEM_NAME: str}         xpath=//*[@data-test='inventory-item-name']
${SORT_PRICE_LOW_TO_HIGH: str}      lohi
${SORT_PRICE_HIGH_TO_LOW: str}      hilo
${SORT_A_TO_Z: str}                 az
${SORT_Z_TO_A: str}                 za


*** Keywords ***
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

Add To Cart Button Locator By Index
    [Documentation]    parameterized locator for the Add to cart button of the product at the given
    ...                position in the product table
    [Arguments]    ${index: int}
    ${locator: str}=    Catenate    SEPARATOR=${EMPTY}    xpath=(//*[@data-test='inventory-item'])[${index}]//button
    RETURN    ${locator}

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

Select Product Sort Option
    [Documentation]    Select sort option from dropdown vy value, default is "lohi" - price low to high
    [Arguments]    ${option_value: str}=lohi
    Wait Until Element Is Visible    ${INVENTORY_SORT_DROPDOWN}
    Select From List By Value    ${INVENTORY_SORT_DROPDOWN}    ${option_value}

Sort Products By Price
    [Documentation]    Sorts the product grid by price
    [Arguments]    ${order: str}=ascending
    IF    "${order}" == "ascending"
        Select Product Sort Option    ${SORT_PRICE_LOW_TO_HIGH}
    ELSE IF    "${order}" == "descending"
        Select Product Sort Option    ${SORT_PRICE_HIGH_TO_LOW}
    ELSE
        Fail    sort order '${order}' unsupported. Use 'ascending' or 'descending'
    END
    Wait Until Element Is Enabled    ${INVENTORY_SORT_DROPDOWN}

Get Product Names In Display Order
    [Documentation]    returns the visible product names as a list
    @{name_elements: Any}=    Get WebElements    ${INVENTORY_ITEM_NAME}
    @{names: str}=    Evaluate    [element.text for element in $name_elements]
    RETURN    ${names}

Add Product To Basket By Index
    [Documentation]    Add product to cart by its 1-based position
    [Arguments]    ${index: int}
    ${button: str}=    Add To Cart Button Locator By Index    ${index}
    Wait Until Element Is Visible    ${button}
    VAR    ${added: bool}=    ${False}
    WHILE    not ${added}    limit=3
        Click Element    ${button}
        ${added: bool}=    Run Keyword And Return Status
        ...    Wait Until Element Contains    ${button}    Remove    timeout=1 seconds
    END

Add Products To Basket By Index Range
    [Documentation]    Adds the products from range by its 1-based positions,
    ...                returns the list of their names in display order
    [Arguments]    ${start_index: int}    ${end_index: int}
    ${end_exclusive: int}=    Evaluate    ${end_index} + 1
    FOR    ${index: int}    IN RANGE    ${start_index}    ${end_exclusive}
        Add Product To Basket By Index    ${index}
    END
    ${slice_start: int}=    Evaluate    ${start_index} - 1
    @{names: str}=    Get Product Names In Display Order
    @{selected: str}=    Get Slice From List    ${names}    ${slice_start}    ${end_index}
    RETURN    ${selected}

Go To Basket
    [Documentation]    Opens the basket by clicking the cart link in the page header
    Wait Until Element Is Visible    ${INVENTORY_CART_LINK}
    Click Element    ${INVENTORY_CART_LINK}
    Wait Until Location Contains    cart.html    timeout=${SELENIUM_TIMEOUT}
