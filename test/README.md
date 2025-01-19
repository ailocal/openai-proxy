# OpenAI Proxy Tests

This directory contains the test suite for the OpenAI Proxy. The tests are written using [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

## Directory Structure

```txt
test/
├── fixtures/           # Test data and configuration files
│   ├── test.env       # Environment variables for testing
│   └── audio-sample.mp3 # Sample audio file for testing
├── e2e/               # End-to-end tests with real services
│   └── services.bats  # Tests for local service integration
├── integration/        # Integration tests
│   └── proxy.bats     # Tests for proxy functionality
├── unit/              # Unit tests
│   ├── commands.bats  # Tests for CLI commands
│   └── config.bats    # Tests for configuration handling
└── test_helper.bash   # Common test helper functions
```

## Running Tests

Run all tests:
```bash
make test
# or
bats -r test/
```

Run specific test files:
```bash
bats test/unit/commands.bats
bats test/integration/proxy.bats
```

## Writing Tests

Tests are written using Bats syntax. Each test file should:

1. Load the test helper:
```bash
load ../test_helper
```

2. Include a setup function:
```bash
setup() {
    load ../test_helper
    echo "Using proxy at: $PROXY" >&2
}
```

3. Write tests using `@test` blocks:
```bash
@test "example test" {
    run "$PROXY" start
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" =~ "expected output" ]]
}
```

## Test Helper

The `test_helper.bash` provides common functions and setup for all tests:

- Sets up test environment variables
- Provides path resolution for the proxy executable
- Handles cleanup in teardown
- Provides utility functions for loading test configurations

## Environment Variables

Tests use these environment variables:

- `OPENAI_PROXY_PORT`: Test port (default: 2021)
- `OPENAI_PROXY_SOCKET`: Test socket path
- `OPENAI_PROXY_CONFIG`: Test config path
- `OPENAI_PROXY_ENV_FILE`: Path to test environment file

## Adding New Tests

1. Create a new `.bats` file in the appropriate directory
2. Load the test helper
3. Add setup/teardown if needed
4. Write your tests using `@test` blocks
5. Run the test suite to verify

## Debugging Tests

Use the `--verbose` flag for detailed output:
```bash
bats --verbose test/
```

For more verbose HAProxy output, set:
```bash
export DEBUG=1
```

## Requirements

- Bats v1.0.0 or higher
- HAProxy
- socat (for socket communication)
- envsubst (from gettext)
