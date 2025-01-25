# System Tests

These tests run against the installed system HAProxy instance.
They verify the basic proxy functionality works in production.

## Requirements

- HAProxy installed and running
- OpenAI API key for API tests

## Running

```bash
bats test/system
```
