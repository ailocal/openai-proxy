# Migration Guide: Template to Static Configuration

This guide helps users migrate from the template-based configuration to the new static HAProxy configuration approach.

## Key Changes

- Removed template-based configuration generation
- Switched to a standard HAProxy configuration file
- Simplified installation process
- Removed environment variable configuration
- Removed custom service management

## Migration Steps

1. **Stop Existing Service**

```bash
# For user service
systemctl --user stop openai-proxy
systemctl --user disable openai-proxy

# For system service
sudo systemctl stop openai-proxy
sudo systemctl disable openai-proxy
```

2. **Install HAProxy** (if not already installed)

```bash
# Debian/Ubuntu
sudo apt install haproxy

# Fedora/RHEL
sudo dnf install haproxy

# macOS
brew install haproxy
```

3. **Copy New Configuration**

```bash
# Create conf.d directory if it doesn't exist
sudo mkdir -p /etc/haproxy/conf.d

# Copy new configuration
sudo cp config/haproxy/conf.d/openai-proxy.cfg /etc/haproxy/conf.d/
```

4. **Update Configuration**

Edit `/etc/haproxy/conf.d/openai-proxy.cfg` to configure your backends:

```haproxy
# Example: Enable Ollama backend
backend backend_chat_completions
    mode http
    option forwardfor
    #server openai api.openai.com:443 ssl verify none sni str(api.openai.com)
    server ollama localhost:11434
```

5. **Start HAProxy**

```bash
# Verify configuration
haproxy -c -f /etc/haproxy/haproxy.cfg

# Restart HAProxy
sudo systemctl restart haproxy
```

6. **Clean Up Old Files**

```bash
# Remove old service files
sudo rm /etc/systemd/system/openai-proxy.service
rm ~/.config/systemd/user/openai-proxy.service

# Remove old configuration
sudo rm -rf /etc/openai-proxy
rm -rf ~/.config/openai-proxy
```

## Testing the Migration

1. Verify the proxy is accessible:
```bash
curl http://localhost:2020/
```

2. Test with your OpenAI tools:
```bash
export OPENAI_BASE_URL=http://localhost:2020/v1
```

## Troubleshooting

- Check HAProxy logs: `sudo journalctl -u haproxy`
- Verify HAProxy is listening: `ss -tlnp | grep 2020`
- Test backend connectivity: `curl http://localhost:11434/` (for Ollama)

## Need Help?

If you encounter issues during migration:
1. Check the HAProxy error logs
2. Verify your backend services are running
3. Open an issue on GitHub with details about your setup
