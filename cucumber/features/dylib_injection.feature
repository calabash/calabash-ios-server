
@dylib_inject
@simulator
@not_xtc
Feature: Start LPServer from embedded dylib

Skips starting the LPServer embedded in the application binary
in favor of starting the LPServer (dylib) embedded in the
application .app bundle.

Scenario: Server embedded in the binary is launched
Given the app has launched
Then the server identifier is from the embedded binary

@skip_embedded_server
Scenario: Server in the .app bundle is launched
Given the app has launched
Then the server identifier is from the embedded dylib
