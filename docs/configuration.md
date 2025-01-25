# OpenAI Proxy Configuration Guide

The OpenAI Proxy uses HAProxy to route API requests to different backends. This guide explains how to configure the routing.

## Configuration File

The proxy configuration lives in `/etc/haproxy/conf.d/openai-proxy.cfg`. An example configuration is provided at `config/haproxy/conf.d/openai-proxy.cfg-example`.

When you first run any openai-proxy command that needs the config file, it will offer to copy the example configuration for you.

## Configuring Backends

Each OpenAI API endpoint can be routed to a different backend server. Here's how to configure the audio transcription endpoint as an example:

1. Locate the backend configuration in the config file:

```haproxy
backend backend_audio_transcriptions
    mode http
    option forwardfor
    
    # Required headers for OpenAI API
    http-request set-header Host api.openai.com
    http-request set-header Authorization %[req.hdr(Authorization)]
    http-request set-header Content-Type %[req.hdr(Content-Type)]
    
    # Default OpenAI backend
    server openai api.openai.com:443 ssl verify none sni str(api.openai.com)
    
    # Local Whisper Example (uncomment to use)
    #
    # http-request set-header Host localhost
    # server whisper localhost:2022
```

1. To route to a different backend:
   - Comment out or remove the OpenAI backend
   - Uncomment and modify the alternative backend configuration
   - Update the host and port to match your service

For example, to use a local Whisper server:

```haproxy
backend backend_audio_transcriptions
    mode http
    option forwardfor
    
    # Required headers
    http-request set-header Host localhost
    
    # Local Whisper server
    server whisper localhost:2022
```

## Verifying Your Configuration

1. Check the HAProxy config syntax:
 
```bash
openai-proxy check-config
```

1. Test the endpoints:
 
```bash
# Set your OpenAI API key
export OPENAI_API_KEY=sk-...

# Test all endpoints
openai-proxy check-endpoints

# Get detailed response info
openai-proxy check-endpoints -v
```

The check-endpoints command will:

- Test the audio transcription endpoint with a sample audio file
- Test the chat completions endpoint with a simple prompt
- Test the text-to-speech endpoint
- Show if each endpoint is working correctly

Example output:

```
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

## Auto-start Configuration

You can configure the proxy to start automatically with your system:

### Container Mode

Enable auto-start:
```bash
openai-proxy enable-container
```

Disable auto-start:
```bash
openai-proxy disable-container
```

This will:
- On Linux: Configure systemd user service
- On macOS: Configure brew services

### Native Mode

For native mode, use your system's service manager directly:

Linux (systemd):
```bash
sudo systemctl enable haproxy
sudo systemctl start haproxy
```

macOS (brew):
```bash
brew services start haproxy
```

## Available Endpoints

The proxy supports routing these OpenAI API endpoints:

- `/v1/audio/transcriptions` - Audio transcription (e.g. Whisper)
- `/v1/chat/completions` - Chat completions (e.g. Ollama)
- `/v1/audio/speech` - Text to speech
- All other `/v1/*` paths - Routed to OpenAI by default

## Troubleshooting

If check-endpoints shows an error:

1. Verify your backend service is running:

```bash
curl http://localhost:2022/health # Example for Whisper
```

2. Check HAProxy logs:

```bash
sudo tail -f /var/log/haproxy.log
```

3. Test with verbose output:

```bash
openai-proxy check-endpoints -v
```

4. Verify the config syntax:

```bash 
openai-proxy check-config -v
```
