# openai-proxy

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![HAProxy](https://img.shields.io/badge/HAProxy-2.4%2B-blue)](https://www.haproxy.org/)
[![Tests](https://github.com/ailocal/openai-proxy/actions/workflows/test.yml/badge.svg)](https://github.com/ailocal/openai-proxy/actions/workflows/test.yml)

Portable HTTP proxy for routing select OpenAI API paths to alternative endpoints.

Use unmodified tools (like [Aider](https://aider.chat])) with self-hosted services such as:

- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp): Voice transcription
- [Ollama](https://ollama.com): Large Language Models
- [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI): Text to Speech

The OpenAI SDK's allow you to direct traffic to an alternate provider:

    ```shell
    export OPENAI_BASE_URL=http://localhost:2020/v1
    ```
This project provides a simple way to route different services to different places.

Feel free to try it out with Whisper running on my M4 Mac Mini: https://api.ailocal.org

Uses [HAProxy](https://haproxy.org), the Reliable, High Performance TCP/HTTP Load Balancer.

## Quickstart

1. **Clone the git repository**

    ```shell
    git clone https://github.com/ailocal/openai-proxy
    ```

2. **Configure environment variables**

    Copy `config/env-example` to `config/env` and modify as needed:

    ```shell
    cp config/env-example config/env
    ```

    Edit `config/env` to set your desired configuration.

3. **Start the proxy**

    ```shell
    bin/openai-proxy start
    ```

    You'll see output like this:

    ```shell
    OpenAI API Routing Table

    ● UP    /v1/audio/transcriptions      http://localhost:9000
    ● UP    /v1/chat/completions          http://localhost:11434
    ● UP    /v1/audio/speech              http://localhost:8080

    OpenAI API Backend: https://api.openai.com:443

    Listening on: http://127.0.0.1:2020
    ```

    The status indicators show:
    - 🟢 GREEN = Backend is UP and responding
    - 🔴 RED = Backend is DOWN or unreachable
    - 🟡 YELLOW = Status unknown

    In this example, all backends are UP and the audio transcriptions endpoint is routed to a custom Whisper API endpoint.

4. **Configure your application**

    Set the `OPENAI_BASE_URL` environment variable in your application to point to the proxy:

    ```shell
    export OPENAI_BASE_URL="http://localhost:2020"
    ```

## Configuration

Configuration is provided via environment variables (defined in `config/env` or exported in the shell).

### Environment Variables

All environment variables have a common prefix `OPENAI_PROXY_`:

- `OPENAI_PROXY_PORT`: Port to listen on (default: 2020)
- `OPENAI_PROXY_BIND_IP`: IP address to bind to (default: 127.0.0.1)
- `OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS`: Backend for audio transcription
- `OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS`: Backend for chat completions
- `OPENAI_PROXY_BACKEND_AUDIO_SPEECH`: Backend for text-to-speech
- `OPENAI_PROXY_BACKEND_OPENAI`: Default backend for other OpenAI API paths

### Welcome Page

The proxy serves a welcome page at the root URL (/) showing available endpoints and their routing.
This can be customized by modifying `config/haproxy/pages/welcome.http`.

**Example**:

```shell
export OPENAI_PROXY_PORT=2020
export OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS=http://localhost:11434 # ollama
export OPENAI_PROXY_BACKEND_AUDIO_SPEECH=http://localhost:8880 # kokoro-fastapi
export OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS=http://localhost:2022 # whisper
export OPENAI_PROXY_BACKEND_DEFAULT=https://api.openai.com:443
```

### Commands

- `start`: Start the proxy (default if no command specified)
- `stop`: Stop the proxy
- `restart`: Stop and then start the proxy  
- `reload`: Reload the configuration without stopping
- `status`: Show proxy status

### Command Line Arguments

- `-h, --help`: Show help message and exit
- `-v, --version`: Show version information and exit
- `-b, --bind`: Specify the IP address to bind to (default: 127.0.0.1)
- `-p, --port`: Specify the port to listen on (default: 2020)
- `-c, --config`: Specify an alternate config file path
- `--verbose`: Enable verbose output
- `--debug`: Enable debug output

## Usage

Start the proxy with defaults:

```shell
bin/openai-proxy
```

Start the proxy with verbose output:

```shell
bin/openai-proxy --verbose
```

Start the proxy with a custom configuration file:

```shell
bin/openai-proxy --config /path/to/custom/env
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

## See Also

- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [HAProxy Documentation](https://www.haproxy.org/#docs)

## License

This project is licensed under the MIT License.

## Installation

You can install openai-proxy either as a system service or user service:

### Quick Install

```bash
# Install using make (defaults to user installation)
make install

# For system-wide installation (requires root)
sudo make install ARGS="--system"
```

Or install manually using one of these methods:

### User Service (Recommended for development)

```bash
# Install as user service
bin/openai-proxy-install --user

# Start the service
systemctl --user enable openai-proxy
systemctl --user start openai-proxy

# Check status
systemctl --user status openai-proxy
```

### System Service (For production/servers)

```bash
# Install as system service (requires root)
sudo bin/openai-proxy-install --system

# Start the service
sudo systemctl enable openai-proxy
sudo systemctl start openai-proxy

# Check status
sudo systemctl status openai-proxy
```

## See Also

- [justsayit (addons.mozilla.org)](https://addons.mozilla.org/en-US/firefox/addon/justsayit/): Enables voice typing on many websites using any Whisper API service.
-  
