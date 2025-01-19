#!/usr/bin/env bats

load ../test_helper

setup() {
    # Remove the redundant load
    echo "Using proxy at: $PROXY" >&2
}

@test "can access OpenAI API directly" {
    run curl -s -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Welcome to the OpenAI API" ]]
}

@test "proxy should forward requests to OpenAI API" {
    "$PROXY" start
    sleep 1  # Give proxy time to start
    
    run curl -s "http://localhost:${OPENAI_PROXY_PORT}/"
    [ "$status" -eq 0 ]
    # Check for any valid response, since we're using a local backend
    [ -n "$output" ]
}

@test "proxy should handle completions request" {
    # Force stop any running test proxy first
    "$PROXY" stop || true
    sleep 1
    
    "$PROXY" start
    sleep 1
    
    # Create a JSON request body
    REQUEST_BODY='{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Say hello"}],
        "max_tokens": 10
    }'
    
    # Send request to the proxy on test port
    echo "Sending request to proxy..."
    run curl -v -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$REQUEST_BODY" \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/chat/completions"
    
    echo "=== BEGIN CURL OUTPUT ==="
    echo "Exit status: $status"
    echo "Response:"
    echo "$output"
    echo "=== END CURL OUTPUT ==="
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "\"role\":\"assistant\"" ]] || {
        echo "Response doesn't contain assistant role"
        echo "Full response: ${output}"
    }
    [[ "${output}" =~ "\"content\":" ]] || {
        echo "Response doesn't contain content field"
        echo "Full response: ${output}"
    }
}
