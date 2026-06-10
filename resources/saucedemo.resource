*** Settings ***
Documentation       Suite-facing facade for SauceDemo tests.
...                 Test suites import only this resource. It re-exports the
...                 environment/runtime keywords, Page Object keywords and shared
...                 test constants while keeping those concerns physically separate.

Resource            environment.resource
Resource            pages/cart_page.resource
Resource            pages/checkout_page.resource
Resource            pages/inventory_page.resource
Resource            pages/login_page.resource
Resource            test_constants.resource
