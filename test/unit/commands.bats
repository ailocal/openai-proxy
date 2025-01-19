#!/usr/bin/env bats

load ../test_helper

setup() {
    # Remove the redundant load
    echo "Using proxy at: $PROXY" >&2
}

@test "start command should start proxy" {
    run "$PROXY" start
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" =~ "OpenAI Proxy started successfully" ]]
}

@test "status command should show running when started" {
    "$PROXY" start
    run "$PROXY" status
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" =~ "openai-proxy is running" ]]
}

@test "status command should show not running when stopped" {
    "$PROXY" stop || true
    run "$PROXY" status
    [ "$status" -eq 1 ]
    [[ "${lines[*]}" =~ "openai-proxy is not running" ]]
}

@test "stop command should stop running proxy" {
    "$PROXY" start
    run "$PROXY" stop
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" =~ "Stopped" ]]
    
    # Verify it's actually stopped
    run "$PROXY" status
    [ "$status" -eq 1 ]
    [[ "${lines[*]}" =~ "not running" ]]
}

@test "restart command should restart proxy" {
    "$PROXY" start
    run "$PROXY" restart
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" =~ "OpenAI Proxy started successfully" ]]
    
    # Verify it's running
    run "$PROXY" status
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" =~ "openai-proxy is running" ]]
}

@test "reload command should reload configuration" {
    "$PROXY" start
    run "$PROXY" reload
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" =~ "Configuration reloaded" ]]
    
    # Verify it's still running
    run "$PROXY" status
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" =~ "openai-proxy is running" ]]
}
