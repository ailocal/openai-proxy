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

### 1. Configure Your Environment

The `OPENAI_BASE_URL` environment variable is used by OpenAI's `openai-python` SDK.
Some other tools / libraries still use the old variable `OPENAI_API_BASE`.

```bash
OPENAI_BASE_URL=http://localhost:2020/v1
OPENAI_API_BASE="$OPENAI_BASE_URL"
```

You can set this in several ways:

- In your shell startup file (~/.bashrc, ~/.zshrc, etc)
- For the current session: `export OPENAI_BASE_URL=http://localhost:2020/v1`
- When running a command: `OPENAI_BASE_URL=http://localhost:2020/v1 aider`
- In a project's .env file
- In your tool's configuration file (e.g. .aiderrc)

### 2. Edit openai-proxy.cfg

The config file has comments explains how to configure alternative targets for OpenAI endpoints.

### 3. Run HAProxy with the provided config

You can manually start HAProxy by running:

```shell
haproxy -f openai-proxy.cfg
```

You can also run it as a system service, in a container, etc.

### 4. Verify It Works

Use the provided endpoint checker to verify your setup:

```bash
$ bin/test-endpoints

Testing OpenAI Proxy endpoints...

1. Testing /v1/chat/completions...
✓ Chat completions endpoint working
   HAProxy Backend: chat_ollama
   Generated text: "
Quesadillas are the ultimate food for space travelers because they're lightweight, flavorful, and can be easily reheated in a microwave on a distant planet. #quesadillacosmos"

2. Testing /v1/audio/speech...
   Using voice: af_alloy
   Using payload: {
    "model": "tts-1",
    "input": "
Quesadillas are the ultimate food for space travelers because they're lightweight, flavorful, and can be easily reheated in a microwave on a distant planet. #quesadillacosmos",
    "voice": "af_alloy"
  }
✓ Audio speech endpoint working
   HAProxy Backend: speech_local
   Generated audio file: 164K
   Audio file type: Audio file with ID3 version 2.4.0, contains:
- MPEG ADTS, layer III, v2, 128 kbps, 24 kHz, Monaural

3. Testing /v1/audio/transcriptions...
✓ Audio transcription endpoint working
   HAProxy Backend: transcriptions_ailocal
   Transcribed text: " Quesadillas are the ultimate food for space travelers because they're lightweight, flavorful,
 and can be easily reheated in a microwave on a distant planet.
 Hash Quesadilla Cosmos.
"
   ✓ Found similarities between original text and transcription

=== Test Summary ===
1. Chat completions: PASS
2. Audio speech: PASS
3. Audio transcription: PASS

All tests passed successfully!
```

## Troubleshooting

- **HAProxy not found**: Make sure HAProxy is installed and in your system's PATH.
- **Port already in use**: Change the `PORT` to a different port if the default is in use.
- **Configuration errors**: Check the environment variables and ensure they are correctly set.
- **Missing Backend Mapping**: If a specific API path is not routed as expected, ensure the corresponding environment variable is defined correctly.

## License

This project is licensed under the MIT License.

## See Also

- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [HAProxy Documentation](https://www.haproxy.org/#docs)
