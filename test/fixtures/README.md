# Test Fixtures

This directory contains test data and configuration files used by the test suite.

## Files

### Configuration
- `test.env` - Environment variables used for testing
- `e2e.env` - Environment variables specific to end-to-end testing

### Test Data
- `for-the-benefit-of-all-huge-manatees.mp3` - Sample audio file for testing transcription services
  - Format: Mono MP3, 160kbps/24kHz
  - Content: Speech recording suitable for testing audio transcription functionality
  - Used by: `test/e2e/services.bats` transcription tests
