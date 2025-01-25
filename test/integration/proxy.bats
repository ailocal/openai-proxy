#!/usr/bin/env bats

load ../test_helper

@test "proxy welcome page is accessible" {
    run curl -s "http://localhost:2020/"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Welcome to OpenAI-Proxy" ]]
}

@test "proxy forwards requests to OpenAI API" {
    # Skip if no API key provided
    [ -n "$OPENAI_API_KEY" ] || skip "OPENAI_API_KEY not set"
    
    # Test a simple models list request
    run curl -s -H "Authorization: Bearer $OPENAI_API_KEY" "http://localhost:2020/v1/models"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "data" ]]
}

@test "proxy handles chat completions" {
    # Skip if no API key provided
    [ -n "$OPENAI_API_KEY" ] || skip "OPENAI_API_KEY not set"
    
    # Create a minimal chat request
    REQUEST_BODY='{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Say hello"}],
        "max_tokens": 10
    }'
    
    # Send request through proxy
    run curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$REQUEST_BODY" \
        "http://localhost:2020/v1/chat/completions"
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "\"role\":\"assistant\"" ]]
    [[ "${output}" =~ "\"content\":" ]]
}
