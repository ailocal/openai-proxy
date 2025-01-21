# Common test helper functions for openai-proxy tests

# Ensure realpath is available
command -v realpath &> /dev/null || {
    echo "Error: 'realpath' is required but not found. Please install 'coreutils' (e.g. 'brew install coreutils' on macOS)." >&2
    return 1
}

# Get absolute path to project root using realpath to handle symlinks
TEST_HELPER_DIR="$(dirname -- "$(realpath "${BASH_SOURCE[0]}")")"
PROJECT_ROOT="$(realpath "${TEST_HELPER_DIR}/..")"

# Fix the PROXY path to point directly to the bin/openai-proxy script
PROXY="${PROJECT_ROOT}/bin/openai-proxy"

# Set up E2E environment file path
export E2E_ENV_FILE="${PROJECT_ROOT}/test/fixtures/e2e.env"

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
        echo "Proxy path: $PROXY" >&2
        echo "E2E env file: $E2E_ENV_FILE" >&2
        export BATS_TEST_HELPER_DEBUG_SHOWN=1
    fi
    
    # Verify proxy script exists and is executable
    if [[ ! -x "$PROXY" ]]; then
        echo "ERROR: Proxy script not found or not executable at: $PROXY" >&2
        return 1
    fi
    
    # Export PROXY so it's available to all tests
    export PROXY
    
    # Set test-specific environment variables
    export OPENAI_PROXY_PORT=2021
    export OPENAI_PROXY_SOCKET="/tmp/haproxy-test-$$.sock"
    export OPENAI_PROXY_CONFIG="/tmp/haproxy-test-$$.cfg"

    # Set test backend URLs
    export OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS="http://localhost:8001"
    export OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS="http://localhost:8002"
    export OPENAI_PROXY_BACKEND_AUDIO_SPEECH="http://localhost:8003"
    export OPENAI_PROXY_BACKEND_OPENAI="http://localhost:8000"
    export WELCOME_PAGE="${PROJECT_ROOT}/config/haproxy/pages/welcome.http"

    # Source the proxy script to make its functions available for testing
    if [[ -z "$OPENAI_PROXY_FUNCTIONS_LOADED" ]]; then
        # Create a temporary file to hold just the functions
        TEMP_FUNCTIONS=$(mktemp)
        
        # Extract functions and supporting code, excluding the main() call
        sed '/^main "\$@"$/d' "$PROXY" > "$TEMP_FUNCTIONS"
        
        # Source the functions
        source "$TEMP_FUNCTIONS"
        rm -f "$TEMP_FUNCTIONS"
        export OPENAI_PROXY_FUNCTIONS_LOADED=1
    fi

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
    if [[ -n "$PROXY" ]]; then
        "$PROXY" stop || true
    fi
    rm -f "$OPENAI_PROXY_CONFIG" "$OPENAI_PROXY_SOCKET" || true
    # Clean up any test-specific environment variables
    unset OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS
    unset OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS
    unset OPENAI_PROXY_BACKEND_AUDIO_SPEECH
    unset OPENAI_PROXY_BACKEND_OPENAI
}

load_test_env() {
    export OPENAI_PROXY_ENV_FILE="${PROJECT_ROOT}/test/fixtures/test.env"
}
