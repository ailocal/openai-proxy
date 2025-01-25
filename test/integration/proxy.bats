#!/usr/bin/env bats

load ../test_helper

@test "can access OpenAI API directly" {
    run curl -s -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Welcome to the OpenAI API" ]]
}

@test "proxy should forward requests to OpenAI API" {
    run curl -s "http://localhost:2020/"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "proxy should handle completions request" {
    # Create a JSON request body
    REQUEST_BODY='{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Say hello"}],
        "max_tokens": 10
    }'
    
    # Send request to the proxy
    run curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$REQUEST_BODY" \
        "http://localhost:2020/v1/chat/completions"
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "\"role\":\"assistant\"" ]]
    [[ "${output}" =~ "\"content\":" ]]
}
