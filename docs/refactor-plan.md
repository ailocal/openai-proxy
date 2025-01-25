# OpenAI Proxy Refactoring Plan

## Objective
Simplify the OpenAI Proxy by moving from a template-based HAProxy configuration to a standard HAProxy configuration file that users can directly edit and install as a conf.d style include.

## Current Architecture Review
- Currently uses a template system with environment variables
- Manages HAProxy as a separate service
- Complex installation process with user/system service options
- Includes welcome page and error pages
- Supports multiple backend configurations through environment variables

## Key Changes

1. **Remove Template System**
   - Remove template-based configuration generation
   - Remove environment variable configuration
   - Remove custom service management
   - Simplify to a single static HAProxy configuration file

2. **New Configuration Approach**
   - Create static HAProxy configuration for `/etc/haproxy/conf.d/`
   - Default all backends to OpenAI API endpoints
   - Include commented examples for local alternatives
   - Maintain current routing logic but in static form
   - Keep useful features like stats socket and logging

3. **Files to Remove**
   - `config/haproxy/openai-proxy.cfg.template`
   - `config/env-example`
   - `config/systemd/*`
   - `bin/openai-proxy`
   - `bin/openai-proxy-install`

4. **Files to Create**
   - `config/haproxy/conf.d/openai-proxy.cfg` - Main configuration file
   - `docs/configuration.md` - Configuration documentation
   - `docs/migration.md` - Migration guide for existing users

## New Configuration Example

```haproxy
# OpenAI API Proxy Configuration
# Install in: /etc/haproxy/conf.d/openai-proxy.cfg

global
    # Inherit from main HAProxy global config

defaults
    # Inherit from main HAProxy defaults

frontend openai_proxy
    bind 127.0.0.1:2020
    mode http

    # Required headers for OpenAI API compatibility
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request set-header X-Forwarded-For %[src]

    # Route based on path
    acl path_audio_transcriptions path_beg /v1/audio/transcriptions
    acl path_chat_completions path_beg /v1/chat/completions
    acl path_audio_speech path_beg /v1/audio/speech

    use_backend backend_audio_transcriptions if path_audio_transcriptions
    use_backend backend_chat_completions if path_chat_completions
    use_backend backend_audio_speech if path_audio_speech

    # Default to OpenAI backend
    default_backend backend_openai

# Chat Completions Backend
backend backend_chat_completions
    mode http
    option forwardfor
    server openai api.openai.com:443 ssl verify none sni str(api.openai.com)

    # Local Ollama Example (uncomment to use)
    # server ollama localhost:11434
    #   - Supports: llama2, codellama, mistral and other models
    #   - Install: curl https://ollama.ai/install.sh | sh
    #   - Run: ollama serve

# Audio Transcriptions Backend
backend backend_audio_transcriptions
    mode http
    option forwardfor
    server openai api.openai.com:443 ssl verify none sni str(api.openai.com)

    # Local Whisper Example (uncomment to use)
    # server whisper localhost:9000
    #   - Supports: Whisper models for audio transcription
    #   - Install: pip install whisper-api
    #   - Run: whisper-api --port 9000

# Audio Speech Backend
backend backend_audio_speech
    mode http
    option forwardfor
    server openai api.openai.com:443 ssl verify none sni str(api.openai.com)

    # Local TTS Example (uncomment to use)
    # server tts localhost:8880
    #   - Supports: Multiple voices and languages
    #   - Install: pip install kokoro-tts
    #   - Run: kokoro-tts serve --port 8880

# Default OpenAI Backend
backend backend_openai
    mode http
    option forwardfor
    server openai api.openai.com:443 ssl verify none sni str(api.openai.com)
```

## Implementation Steps

1. **Create New Configuration**
   - Write static HAProxy configuration file
   - Test with all supported backends
   - Verify compatibility with existing tools

2. **Update Documentation**
   - Update README.md for new approach
   - Create configuration guide
   - Document each backend option
   - Add troubleshooting section

3. **Update Tests**
   - Modify E2E tests to work with standard HAProxy
   - Add configuration validation tests
   - Update test fixtures

4. **Create Migration Tools**
   - Script to help users migrate existing configurations
   - Documentation for manual migration

## Testing Plan

1. **Test Environment**
   - Tests run with isolated HAProxy instance
   - Separate from system HAProxy service
   - No sudo required for testing
   - Safe for CI/CD environments

2. **Configuration Tests**
   - Validate HAProxy syntax
   - Test with default OpenAI backend
   - Test with each local service option

3. **E2E Tests**
   - Maintain existing test scenarios:
     - Chat completions with Ollama
     - Audio transcription with Whisper
     - Text to speech with local service
   - Add new tests for configuration validation
   - Run against test HAProxy instance

## Migration Guide for Users

1. **For Existing Users**
   - Stop openai-proxy service
   - Install HAProxy if not present
   - Copy new configuration to `/etc/haproxy/conf.d/`
   - Update any custom backend configurations
   - Restart HAProxy service

2. **For New Users**
   - Install HAProxy
   - Copy configuration file
   - Modify as needed
   - Restart HAProxy

## Success Criteria

- Simplified installation process
- Reduced codebase complexity
- Maintained functionality
- Better integration with system HAProxy
- Clear upgrade path for users

## Timeline

1. Week 1
   - Create new configuration file
   - Basic documentation updates
   - Initial testing

2. Week 2
   - Complete documentation
   - Migration guide
   - Test suite updates

3. Week 3
   - User testing
   - Feedback incorporation
   - Final adjustments

4. Week 4
   - Release preparation
   - Final testing
   - Release

## Future Considerations

1. **Configuration Management**
   - Consider providing example configurations for common setups
   - Add validation tools for configuration

2. **Documentation**
   - Add more examples for different local services
   - Create troubleshooting guide
   - Add performance tuning recommendations

3. **Testing**
   - Add performance benchmarks
   - Add configuration validation tools
   - Expand E2E test coverage
