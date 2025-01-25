#!/usr/bin/env bats

load ../system_helper

@test "system proxy is running" {
    run check_haproxy
    [ "$status" -eq 0 ]
}

@test "system proxy welcome page" {
    run curl -s "http://localhost:${OPENAI_PROXY_PORT}/"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Welcome to OpenAI-Proxy" ]]
}

@test "system proxy handles OpenAI requests" {
    [ -n "${OPENAI_API_KEY:-}" ] || skip "OPENAI_API_KEY not set"
    
    run curl -s \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/models"
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "data" ]]
}
