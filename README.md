# Text2Piper TTS System

A text-to-speech system combining FHEM home automation with Piper TTS, enabling voice output through a Flask server interface.

## Components

- FHEM Perl module for text-to-speech requests
- Python Flask server connecting to Piper TTS
- Docker container with Piper TTS engine

## Quick Start

### 1. Start TTS Server

```bash
docker build -t text2piper .
docker run -p 8765:8765 text2piper
```

### 2. Configure FHEM Module

```perl
define tts Text2Piper 192.168.1.100 8765
attr tts disable 0
```

### 3. Test TTS

```perl
set tts tts "Hello World"
```

## Server Setup

### Prerequisites

- Docker
- ARM64 architecture (for provided Dockerfile)
- Internet connection for voice model downloads

### Environment Variables

- `CODE_PATH`: Base path for installation (`/opt`)
- Default port: `8765`

### Voice Models

Default voice: German (Kerstin)
- Quality: Low
- Source: Hugging Face Repository

## FHEM Module Features

### Definition
```perl
define <name> Text2Piper <host> <port>
```

### Commands
```perl
set <name> tts <text>
```

### Attributes
- `disable`: Enable/disable TTS (0/1)
- Standard FHEM reading attributes

### Error Handling
- Connection failure detection
- Timeout handling (60s)
- Process cleanup
- Logging support

## Flask Server API

### Endpoint
- `POST /`: Accepts text for TTS conversion

### Request Format
```
Plain text in request body
```

### Response
- Audio stream (WAV format)
- Error messages for failed conversions

## Docker Container

### Included Components
- Ubuntu 24.04 base
- Piper TTS (v2023.11.14-2)
- Python Flask server
- Espeak-ng data
- German voice model

### Build Arguments
- `DEBIAN_FRONTEND=noninteractive`

### Exposed Ports
- 8765 (TCP)

## Troubleshooting

1. Server Connection
```bash
telnet <host> 8765
```

2. FHEM Module
```perl
attr global logfile ./log/fhem-%Y-%m.log
define FileLog FileLog ./log/fhem-%Y-%m.log tts.*
```

3. Docker Container
```bash
docker logs <container_id>
```

## Security Notes

- No authentication implemented
- Internal network usage recommended
- No input sanitization on TTS requests

## Performance

- Low latency for short texts
- Supports concurrent requests
- Memory usage depends on voice model size

## License

Refer to individual components:
- Piper TTS: Original license
- FHEM Module: FHEM license
- Flask Server: MIT License
