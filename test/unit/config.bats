#!/usr/bin/env bats

load ../test_helper

setup() {
    echo "Using proxy at: $PROXY" >&2
    
    # Source the proxy script directly to get access to its functions
    source "$PROXY"
    
    # Load test environment
    load_test_env
}

@test "should properly parse backend URLs" {
    skip "TODO: Fix backend URL parsing test"
    # Test HTTPS URL with port
    OPENAI_PROXY_BACKEND_TEST="https://api.example.com:8443"
    parse_backend_url "OPENAI_PROXY_BACKEND_TEST"
    [ "$OPENAI_PROXY_BACKEND_TEST_HOST" = "api.example.com" ]
    [ "$OPENAI_PROXY_BACKEND_TEST_PORT" = "8443" ]
    [ "$OPENAI_PROXY_BACKEND_TEST_SSL" = "1" ]

    # Test HTTP URL without port
    OPENAI_PROXY_BACKEND_TEST="http://localhost"
    parse_backend_url "OPENAI_PROXY_BACKEND_TEST"
    [ "$OPENAI_PROXY_BACKEND_TEST_HOST" = "localhost" ]
    [ "$OPENAI_PROXY_BACKEND_TEST_PORT" = "80" ]
    [ "$OPENAI_PROXY_BACKEND_TEST_SSL" = "0" ]

    # Test HTTPS URL without port
    OPENAI_PROXY_BACKEND_TEST="https://api.openai.com"
    parse_backend_url "OPENAI_PROXY_BACKEND_TEST"
    [ "$OPENAI_PROXY_BACKEND_TEST_HOST" = "api.openai.com" ]
    [ "$OPENAI_PROXY_BACKEND_TEST_PORT" = "443" ]
    [ "$OPENAI_PROXY_BACKEND_TEST_SSL" = "1" ]
}

@test "config generation should properly load environment variables from env file" {
    skip "TODO: Fix environment variable loading test"
    # Load the test environment file
    load_test_env
    local TEST_CONFIG="/tmp/haproxy-env-test-$$.cfg"
    export OPENAI_PROXY_CONFIG="$TEST_CONFIG"
    
    # Generate config first
    generate_haproxy_config
    
    # Run the proxy with these settings
    run "$PROXY" start
    
    # Check if start was successful
    [ "$status" -eq 0 ]
    
    # Verify the generated config contains our test values
    run cat "$TEST_CONFIG"
    echo "Generated config:"
    echo "$output"
    
    # Check for specific values from our test env file
    [[ "$output" =~ "bind *:2099" ]] || {
        echo "Config doesn't contain correct port"
        return 1
    }
    
    # Clean up
    "$PROXY" stop
    rm -f "$TEST_CONFIG"
}
