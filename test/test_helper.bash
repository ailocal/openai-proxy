# Common test helper functions for openai-proxy tests
#
# This file sets up an isolated HAProxy instance for testing, separate from
# the system HAProxy service. This approach:
# - Allows tests to run without sudo
# - Prevents interference with production traffic
# - Enables testing on different ports/sockets
# - Works safely in CI/CD environments
# - Keeps test environment isolated and reproducible

# Ensure realpath is available
command -v realpath &> /dev/null || {
    echo "Error: 'realpath' is required but not found. Please install 'coreutils' (e.g. 'brew install coreutils' on macOS)." >&2
    return 1
}

# Get absolute path to project root using realpath to handle symlinks
TEST_HELPER_DIR="$(dirname -- "$(realpath "${BASH_SOURCE[0]}")")"
PROJECT_ROOT="$(realpath "${TEST_HELPER_DIR}/..")"

# Set up isolated test configuration paths
# Using process ID ($$) to ensure unique test instance
export TEST_CONFIG_DIR="/tmp/haproxy-test-$$"
export TEST_CONFIG_FILE="${TEST_CONFIG_DIR}/haproxy.cfg"
export TEST_SOCKET_FILE="${TEST_CONFIG_DIR}/haproxy.sock"
export TEST_PID_FILE="${TEST_CONFIG_DIR}/haproxy.pid"

# Set up E2E environment file path
export E2E_ENV_FILE="${PROJECT_ROOT}/test/fixtures/e2e.env"

# HAProxy control functions
function start_haproxy() {
    mkdir -p "$TEST_CONFIG_DIR"
    cp "${PROJECT_ROOT}/config/haproxy/conf.d/openai-proxy.cfg" "$TEST_CONFIG_FILE"
    
    # Start HAProxy with test configuration
    # Added -W for master-worker mode to support socket
    haproxy -W -f "$TEST_CONFIG_FILE" -p "$TEST_PID_FILE" -S "$TEST_SOCKET_FILE" -D
    sleep 1  # Give HAProxy time to start
    
    # Verify HAProxy is running
    if ! pgrep -F "$TEST_PID_FILE" > /dev/null; then
        echo "Failed to start HAProxy" >&2
        return 1
    fi
}

function stop_haproxy() {
    if [ -f "$TEST_PID_FILE" ]; then
        kill $(cat "$TEST_PID_FILE") || true
        rm -f "$TEST_PID_FILE"
    fi
    rm -rf "$TEST_CONFIG_DIR"
}

# Service control functions
function start_ollama_service() {
    echo "Starting Ollama service..." >&2
    ollama serve &
    OLLAMA_PID=$!
    export OLLAMA_PID
}

function stop_ollama_service() {
    if [ -n "$OLLAMA_PID" ]; then
        echo "Stopping Ollama service..." >&2
        kill $OLLAMA_PID || true
    fi
}

function start_whisper_service() {
    echo "Starting Whisper service..." >&2
    whisper-api --port 9000 &
    WHISPER_PID=$!
    export WHISPER_PID
}

function stop_whisper_service() {
    if [ -n "$WHISPER_PID" ]; then
        echo "Stopping Whisper service..." >&2
        kill $WHISPER_PID || true
    fi
}

function start_tts_service() {
    echo "Starting TTS service..." >&2
    tts-server --port 8080 &
    TTS_PID=$!
    export TTS_PID
}

function stop_tts_service() {
    if [ -n "$TTS_PID" ]; then
        echo "Stopping TTS service..." >&2
        kill $TTS_PID || true
    fi
}

# Only run setup once
if [[ -z "$BATS_TEST_HELPER_SETUP_DONE" ]]; then
    # Debug output - only show once
    if [[ -z "$BATS_TEST_HELPER_DEBUG_SHOWN" ]]; then
        echo "Test helper dir: $TEST_HELPER_DIR" >&2
        echo "Project root: $PROJECT_ROOT" >&2
        echo "Test config: $TEST_CONFIG_FILE" >&2
        echo "E2E env file: $E2E_ENV_FILE" >&2
        export BATS_TEST_HELPER_DEBUG_SHOWN=1
    fi
    
    # Set test-specific environment variables
    export OPENAI_PROXY_PORT=2021
    
    # Set test backend URLs
    export OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS="http://localhost:8001"
    export OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS="http://localhost:8002"
    export OPENAI_PROXY_BACKEND_AUDIO_SPEECH="http://localhost:8003"
    export OPENAI_PROXY_BACKEND_OPENAI="http://localhost:8000"

    # Mark setup as done
    export BATS_TEST_HELPER_SETUP_DONE=1
fi

# Parse a backend URL into component parts
parse_backend_url() {
    local var_prefix="$1"      # e.g. BACKEND_DEFAULT
    local env_var="${var_prefix}"  # Construct the full env var name
    
    # Use eval to get the URL value since we're dealing with dynamic variable names
    local url
    eval "url=\${$env_var}"
    
    # Extract protocol, host, port
    if [[ "$url" =~ ^(https?)://([^:/]+)(:([0-9]+))? ]]; then
        local proto="${BASH_REMATCH[1]}"
        local host="${BASH_REMATCH[2]}"
        local port="${BASH_REMATCH[4]}"
        
        # Set default ports if not specified
        [[ -z "$port" ]] && port=$([ "$proto" = "https" ] && echo "443" || echo "80")
        
        # Export parsed components
        export "${var_prefix}_HOST"="$host"
        export "${var_prefix}_PORT"="$port"
        export "${var_prefix}_SSL"="$([ "$proto" = "https" ] && echo "1" || echo "0")"
    fi
}

# Helper function for checking backend status
check_backend_status() {
    local backend=$1
    local socket=$2
    if [ -S "$socket" ]; then
        echo "show stat" | socat "$socket" stdio | grep "$backend" | grep 'BACKEND' | cut -d',' -f18
    else
        echo "NONE"
    fi
}

teardown() {
    stop_haproxy
    stop_ollama_service
    stop_whisper_service
    stop_tts_service
}

load_test_env() {
    export OPENAI_PROXY_ENV_FILE="${PROJECT_ROOT}/test/fixtures/test.env"
}
