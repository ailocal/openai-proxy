# openai-proxy

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![HAProxy](https://img.shields.io/badge/HAProxy-2.4%2B-blue)](https://www.haproxy.org/)
[![Tests](https://github.com/ailocal/openai-proxy/actions/workflows/test.yml/badge.svg)](https://github.com/ailocal/openai-proxy/actions/workflows/test.yml)

Portable HTTP proxy for routing select OpenAI API paths to alternative endpoints.

Use unmodified tools (like [Aider](https://aider.chat])) with self-hosted services such as:

- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp): Voice transcription
- [Ollama](https://ollama.com): Large Language Models
- [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI): Text to Speech

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
    Generating HAProxy configuration...
    Starting openai-proxy...

    OpenAI Proxy started successfully

    OpenAI API Routing Table

    ● UP /v1/chat/completions           https://api.openai.com:443              
    ● UP /v1/audio/speech               https://api.openai.com:443
    ● UP /v1/audio/transcriptions       https://api.ailocal.org:443

    Default Backend: https://api.openai.com:443

    Listening on: http://0.0.0.0:2020
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

All environment variables have a common prefix `OPENAI_PROXY_`.

Below are the variables you can set:

- `PORT`: Port for the proxy to listen on (default: `2020`)
- `OPENAI_PROXY_BACKEND_<API_PATH>`: Map specific API paths to backend URLs.
    - **Format**: The `<API_PATH>` is derived from the API endpoint path. Replace slashes `/` with underscores `_` and convert to uppercase.
    - **Example**:
        - To map `/v1/chat/completions` to a local backend:

            ```shell
            OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS=http://localhost:11434
            ```

        - To map `/v1/audio/transcriptions` to a local backend:

            ```shell
            OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS=http://localhost:2022
            ```

- `OPENAI_PROXY_BACKEND_DEFAULT`: Default backend URL for unmapped API paths (default: `https://api.openai.com:443`)
- `OPENAI_PROXY_ERROR_PAGE`: Path to custom error page (optional)

**Example**:

```shell
export OPENAI_PROXY_PORT=2020
export OPENAI_PROXY_BACKEND_CHAT_COMPLETIONS=http://localhost:11434 # ollama
export OPENAI_PROXY_BACKEND_AUDIO_SPEECH=http://localhost:8880 # kokoro-fastapi
export OPENAI_PROXY_BACKEND_AUDIO_TRANSCRIPTIONS=http://localhost:2022 # whisper
export OPENAI_PROXY_BACKEND_DEFAULT=https://api.openai.com:443
```

### Command Line Arguments

- `-h, --help`: Show help message and exit
- `-v, --version`: Show version information and exit
- `-c, --config FILE`: Specify an alternate config file path
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

## System Service

To run openai-proxy as a system service:

1. Create system user and group:
    ```bash
    sudo useradd -r -s /bin/false openai-proxy
    ```

2. Create configuration directory:
    ```bash
    sudo mkdir -p /etc/openai-proxy
    sudo cp config/env /etc/openai-proxy/
    sudo chown -R openai-proxy:openai-proxy /etc/openai-proxy
    sudo chmod 640 /etc/openai-proxy/env
    ```

3. Install the binary:
    ```bash
    sudo cp bin/openai-proxy /usr/local/bin/
    sudo chmod 755 /usr/local/bin/openai-proxy
    ```

4. Install the systemd service:
    ```bash
    sudo cp config/systemd/openai-proxy.service /etc/systemd/system/
    sudo systemctl daemon-reload
    ```

5. Start and enable the service:
    ```bash
    sudo systemctl enable openai-proxy
    sudo systemctl start openai-proxy
    ```

Check service status:
```bash
sudo systemctl status openai-proxy
```
