#!/usr/bin/env bats

load ../synthetic_helper

@test "proxy welcome page is accessible" {
    run curl -s "http://localhost:${OPENAI_PROXY_PORT}/"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Welcome to OpenAI-Proxy" ]]
}

@test "proxy forwards requests to OpenAI API" {
    # Skip if no API key provided
    [ -n "${OPENAI_API_KEY:-}" ] || skip "OPENAI_API_KEY not set"
    
    run curl -s \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/models"
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "data" ]]
}

@test "chat completions with local service" {
    [ -n "${OPENAI_API_KEY:-}" ] || skip "OPENAI_API_KEY not set"
    [ -n "${OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS not configured"
    
    run curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role":"user","content":"Say hello"}],
            "max_tokens": 10
        }' \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/chat/completions"
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "\"role\":\"assistant\"" ]]
    [[ "${output}" =~ "\"content\":" ]]
}

@test "audio transcription with local service" {
    [ -n "${OPENAI_API_KEY:-}" ] || skip "OPENAI_API_KEY not set"
    [ -n "${OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS not configured"
    
    local audio_file="test/fixtures/for-the-benefit-of-all-huge-manatees.mp3"
    [ -f "$audio_file" ] || skip "Test audio file not found: $audio_file"
    
    run curl -s -X POST \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -F "file=@$audio_file" \
        -F "model=whisper-1" \
        -F "response_format=json" \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/audio/transcriptions"
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "text" ]]
}

@test "text to speech with local service" {
    [ -n "${OPENAI_API_KEY:-}" ] || skip "OPENAI_API_KEY not set"
    [ -n "${OPENAI_PROXY_BACKEND_AUDIO_SPEECH:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_AUDIO_SPEECH not configured"
    
    run curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d '{
            "model": "tts-1",
            "input": "Hello world",
            "voice": "alloy"
        }' \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/audio/speech"
    
    [ "$status" -eq 0 ]
    [ "${#output}" -gt 100 ]
}
