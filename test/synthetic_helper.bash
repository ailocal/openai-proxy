# Helper functions for synthetic tests
# These tests run against a fresh HAProxy instance

# Get absolute path to project root
TEST_HELPER_DIR="$(dirname -- "$(realpath "${BASH_SOURCE[0]}")")"
PROJECT_ROOT="$(realpath "${TEST_HELPER_DIR}/..")"

# Set up isolated test configuration paths
export TEST_CONFIG_DIR="/tmp/haproxy-test-$$"
export TEST_CONFIG_FILE="${TEST_CONFIG_DIR}/haproxy.cfg"
export TEST_SOCKET_FILE="${TEST_CONFIG_DIR}/haproxy.sock"
export TEST_PID_FILE="${TEST_CONFIG_DIR}/haproxy.pid"

# Set up synthetic environment file path
export SYNTHETIC_ENV_FILE="${PROJECT_ROOT}/test/fixtures/synthetic.env"

# HAProxy control functions
function start_haproxy() {
    mkdir -p "$TEST_CONFIG_DIR"
    cp "${PROJECT_ROOT}/config/haproxy/conf.d/openai-proxy.cfg" "$TEST_CONFIG_FILE"
    
    # Update the port in the test config
    sed -i "s/bind 127.0.0.1:2020/bind 127.0.0.1:${OPENAI_PROXY_PORT}/" "$TEST_CONFIG_FILE"
    
    # Start HAProxy with test configuration
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

teardown() {
    stop_haproxy
}

# Load synthetic test environment
if [ -f "$SYNTHETIC_ENV_FILE" ]; then
    source "$SYNTHETIC_ENV_FILE"
else
    echo "Warning: Synthetic env file not found at $SYNTHETIC_ENV_FILE" >&2
fi
