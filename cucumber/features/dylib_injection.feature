
@dylib_inject
Feature: Dylib Injection

Tests the universe of dylib injection for iOS.

We can control which LPServer is started:  the LPServer embedded in the
application binary or the LPServer dylib embedded in the application
.app bundle.

There is also a test that entitlement injector is loaded on Test Cloud.

@not_xtc
@simulator
Scenario: Server embedded in the binary is launched
Given the app has launched
Then the server identifier is from the embedded binary

@not_xtc
@skip_embedded_server
@simulator
Scenario: Server in the .app bundle is launched
Given the app has launched
Then the server identifier is from the embedded dylib

Scenario: Entitlement Injector has been loaded
Given the app has launched
And I go to the second tab
When running in App Center the entitlement injector is loaded
When running locally the entitlement injector is not loaded
