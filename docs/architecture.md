# OpenAI Proxy Architecture

This diagram shows how the OpenAI Proxy routes API requests to different backends based on the endpoint path.

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#fff',
    'primaryTextColor': '#000',
    'primaryBorderColor': '#666',
    'lineColor': '#666',
    'textColor': '#000'
  }
}}%%
graph LR
    A["Client Tool<br/>(e.g. Aider)"] -->|"OPENAI_BASE_URL=<br/>localhost:2020"| B["OpenAI Proxy<br/>(HAProxy)"]
    
    B -->|"audio/transcriptions"| C["Whisper Server<br/>(port 2022)"]
    B -->|"chat/completions"| D["LLM Server<br/>(port 11434)"]
    B -->|"audio/speech"| E["TTS Server<br/>(port 8880)"]
    B -->|"other /v1/* paths"| F["api.openai.com"]

    classDef default stroke-width:2px;
    classDef client fill:#e3f2fd,stroke:#666;
    classDef proxy fill:#fff3e0,stroke:#666;
    classDef service fill:#f9fbe7,stroke:#666;
    classDef remote fill:#f5f5f5,stroke:#666;
    
    class A client;
    class B proxy;
    class C,D,E service;
    class F remote;
```

## How It Works

1. **Tool Configuration**: Tools that use the OpenAI API (like Aider) check the `OPENAI_BASE_URL` environment variable
2. **Request Routing**: When set to `http://localhost:2020`, all API requests go through the OpenAI Proxy
3. **Selective Routing**: The proxy examines the request path and routes to different backends:
   - `/v1/audio/transcriptions` → Local Whisper server for voice-to-text
   - `/v1/chat/completions` → Local LLM server (e.g. Ollama)
   - `/v1/audio/speech` → Local Text-to-Speech server
   - All other `/v1/*` paths → OpenAI's API

This allows you to:
- Use local services for specific features (faster, private, cheaper)
- Fall back to OpenAI's API for everything else
- Use standard tools without modification

The proxy is transparent to the tools - they continue to work as if talking directly to OpenAI's API.
