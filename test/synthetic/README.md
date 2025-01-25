# Synthetic Tests

These tests run against a fresh HAProxy instance spun up specifically for testing.
They verify the core functionality works in isolation.

## Requirements

- HAProxy installed
- OpenAI API key for full test suite
- Test services (optional):
  - Ollama for chat completions
  - Whisper for transcription 
  - TTS service for speech

## Running

```bash
bats test/synthetic
```

Skip service-specific tests by not configuring their backends in test/fixtures/synthetic.env
