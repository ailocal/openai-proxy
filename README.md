---
alias: openai-proxy
---
# openai-proxy

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![HAProxy](https://img.shields.io/badge/HAProxy-2.4%2B-blue)](https://www.haproxy.org/)

A simple HAProxy configuration for routing OpenAI API requests to alternative endpoints.

![Architecture](docs/images/architecture.mmd.svg)

Use unmodified tools (like [Aider](https://aider.chat])) with self-hosted services such as:

- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp): Voice transcription
- [Ollama](https://ollama.com): Large Language Models
- [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI): Text to Speech

This project provides a simple way to route different services to different places.

Feel free to try it out with Whisper running on my M4 Mac Mini: https://api.ailocal.org

Uses [HAProxy](https://haproxy.org), the Reliable, High Performance TCP/HTTP Load Balancer.

## Usage

```shell
Usage: openai-proxy <command> [options]

Commands:
  check-config        Check HAProxy configuration syntax
  check-endpoints     Test the OpenAI API endpoints

  start              Start HAProxy directly on the host
  stop               Stop HAProxy on the host 
  status             Show HAProxy status on the host

  start-container    Start the proxy container
  stop-container     Stop the proxy container
  status-container   Show proxy container status
  enable-container   Enable container auto-start with system
  disable-container  Disable container auto-start with system

Global Options:
  -h, --help     Show this help message
  -v, --verbose  Show detailed output
```

## How It Works

### 1. Start the Proxy

Choose one of these methods:

**Option A: Direct with HAProxy**
```bash
# Debian/Ubuntu
sudo apt install haproxy

# Fedora/RHEL
sudo dnf install haproxy

# macOS
brew install haproxy

# Run the proxy
haproxy -f config/haproxy/conf.d/openai-proxy.cfg
```

**Option B: Using Containers**
```bash
# Using podman-compose
podman-compose up -d

# Or using plain podman
podman run -d \
  --name openai-proxy \
  --network host \
  -v ./config/haproxy/conf.d/openai-proxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  -p 127.0.0.1:2020:2020 \
  haproxytech/haproxy-alpine:latest
```

### 2. Configure Your Environment

The `OPENAI_BASE_URL` environment variable must be set for any tool using an OpenAI SDK to use your proxy:

```bash
OPENAI_BASE_URL=http://localhost:2020/v1
```

You can set this in several ways:
- In your shell startup file (~/.bashrc, ~/.zshrc, etc)
- For the current session: `export OPENAI_BASE_URL=http://localhost:2020/v1`
- When running a command: `OPENAI_BASE_URL=http://localhost:2020/v1 aider`
- In a project's .env file
- In your tool's configuration file (e.g. .aiderrc)

### 3. Verify It Works

Use the built-in endpoint checker to verify your setup:

```bash
$ openai-proxy check-endpoints
Testing OpenAI Proxy endpoints...

1. Testing /v1/audio/transcriptions...
✓ Audio transcription endpoint working

2. Testing /v1/chat/completions...
✓ Chat completions endpoint working

3. Testing /v1/audio/speech...
✓ Audio speech endpoint working

Verification complete!
```

Note: This requires your `OPENAI_API_KEY` to be set in the environment.

## Configuration

Configuration is provided through HAProxy's configuration file. A sample configuration is provided in `config/haproxy/conf.d/openai-proxy.cfg-example`. When you first run the proxy, it will offer to copy this example configuration for you.

See the [detailed configuration guide](docs/configuration.md) for complete information about configuring endpoints and routing.


## Usage

```shell
Usage: openai-proxy <command> [options]

Commands:
  check-config        Check HAProxy configuration syntax
  check-endpoints     Test the OpenAI API endpoints

  start              Start HAProxy directly on the host
  stop               Stop HAProxy on the host 
  status             Show HAProxy status on the host

  start-container    Start the proxy container
  stop-container     Stop the proxy container
  status-container   Show proxy container status
  enable-container   Enable container auto-start with system
  disable-container  Disable container auto-start with system

Global Options:
  -h, --help     Show this help message
  -v, --verbose  Show detailed output
```

## Testing

To verify that the proxy is working correctly:

1. Start the proxy.
2. Send a request to one of the routed endpoints:

    ```shell
    curl http://localhost:2020/v1/chat/completions
    ```

3. Ensure the request is routed to the correct backend.

## Troubleshooting

- **HAProxy not found**: Make sure HAProxy is installed and in your system's PATH.
- **Port already in use**: Change the `PORT` to a different port if the default is in use.
- **Configuration errors**: Check the environment variables and ensure they are correctly set.
- **Missing Backend Mapping**: If a specific API path is not routed as expected, ensure the corresponding environment variable is defined correctly.

## Verifying the Setup

You can verify your setup using two check commands:

### 1. Check Configuration

Verify the HAProxy configuration syntax:

```bash
$ openai-proxy check-config
Checking HAProxy configuration: /etc/haproxy/conf.d/openai-proxy.cfg
Configuration is valid
```

For more detailed output, use the verbose flag:

```bash
$ openai-proxy check-config -v
Checking HAProxy configuration: /etc/haproxy/conf.d/openai-proxy.cfg
Configuration file /etc/haproxy/conf.d/openai-proxy.cfg has valid syntax
Configuration is valid
```

### 2. Check Endpoints

Test that all OpenAI API endpoints are reachable through the proxy:

```bash
$ openai-proxy check-endpoints
Testing OpenAI Proxy endpoints...

1. Testing /v1/audio/transcriptions...
✓ Audio transcription endpoint working
Response: {"text": "huge manatees"}

2. Testing /v1/chat/completions...
✓ Chat completions endpoint working

3. Testing /v1/audio/speech...
✓ Audio speech endpoint working

Verification complete!
```

For detailed API responses, use the verbose flag:

```bash
$ openai-proxy check-endpoints -v
```

Note: The endpoints check requires your `OPENAI_API_KEY` to be set in the environment.

## License

This project is licensed under the MIT License.


## See Also

- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [HAProxy Documentation](https://www.haproxy.org/#docs)
- [justsayit (addons.mozilla.org)](https://addons.mozilla.org/en-US/firefox/addon/justsayit/): Enables voice typing on many websites using any Whisper API service.
