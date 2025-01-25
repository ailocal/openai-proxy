# Helper functions for system tests
# These tests run against the installed system HAProxy

# Get absolute path to project root
TEST_HELPER_DIR="$(dirname -- "$(realpath "${BASH_SOURCE[0]}")")"
PROJECT_ROOT="$(realpath "${TEST_HELPER_DIR}/..")"

# Set default system HAProxy port
export OPENAI_PROXY_PORT=${OPENAI_PROXY_PORT:-2020}

# Verify system HAProxy is running
function check_haproxy() {
    if ! curl -s "http://localhost:${OPENAI_PROXY_PORT}/" > /dev/null; then
        echo "System HAProxy not running on port ${OPENAI_PROXY_PORT}" >&2
        return 1
    fi
}

setup() {
    check_haproxy
}
