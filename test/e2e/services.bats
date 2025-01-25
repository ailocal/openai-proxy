#!/usr/bin/env bats

load ../test_helper

setup() {
    # Load E2E specific configuration if present
    if [ -f "$E2E_ENV_FILE" ]; then
        source "$E2E_ENV_FILE"
    else
        echo "Warning: E2E configuration file not found at $E2E_ENV_FILE" >&2
        echo "Copy test/fixtures/e2e-env-example to test/fixtures/e2e.env and configure for your environment" >&2
        return 1
    fi
    
    # Set test timeout if specified in E2E config
    if [ -n "${E2E_TEST_TIMEOUT:-}" ]; then
        export BATS_TEST_TIMEOUT="$E2E_TEST_TIMEOUT"
    fi
    
    # Start HAProxy with test configuration
    start_haproxy
}

@test "verify all required services are configured" {
    # Check that all required backend URLs are set
    [ -n "${OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS not configured"
    [ -n "${OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS not configured"
    [ -n "${OPENAI_PROXY_BACKEND_AUDIO_SPEECH:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_AUDIO_SPEECH not configured"
}

@test "chat completions with local Ollama" {
    [ -n "$OPENAI_API_KEY" ] || skip "OPENAI_API_KEY not set"
    [ -n "${OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS not configured"
    
    run curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "OpenAI-Organization: ${OPENAI_ORG_ID:-}" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role":"user","content":"Say hello"}],
            "temperature": 0.7,
            "max_tokens": 50
        }' \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/chat/completions"
    
    echo "Status: $status" >&2
    echo "Output: $output" >&2
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "content" ]]
}

@test "audio transcription with local Whisper" {
    [ -n "$OPENAI_API_KEY" ] || skip "OPENAI_API_KEY not set"
    [ -n "${OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS not configured"
    
    local audio_file="test/fixtures/for-the-benefit-of-all-huge-manatees.mp3"
    [ -f "$audio_file" ] || skip "Test audio file not found: $audio_file"
    
    run curl -s -X POST \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "OpenAI-Organization: ${OPENAI_ORG_ID:-}" \
        -F "file=@$audio_file" \
        -F "model=whisper-1" \
        -F "response_format=json" \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/audio/transcriptions"
    
    echo "Status: $status" >&2
    echo "Output: $output" >&2
    
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "text" ]]
}

@test "text to speech with local service" {
    [ -n "$OPENAI_API_KEY" ] || skip "OPENAI_API_KEY not set"
    [ -n "${OPENAI_PROXY_BACKEND_AUDIO_SPEECH:-}" ] || \
        skip "OPENAI_PROXY_BACKEND_AUDIO_SPEECH not configured"
    
    run curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "OpenAI-Organization: ${OPENAI_ORG_ID:-}" \
        -d '{
            "model": "tts-1",
            "input": "Hello world",
            "voice": "alloy"
        }' \
        "http://localhost:${OPENAI_PROXY_PORT}/v1/audio/speech"
    
    echo "Status: $status" >&2
    echo "Output length: ${#output}" >&2
    
    [ "$status" -eq 0 ]
    [ "${#output}" -gt 100 ]
}
