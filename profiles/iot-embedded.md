---
name: iot-embedded
version: 1.0
description: ESP32 and ESPHome IoT development (sensors, displays, OTA flashing)
requires: []
winget:
  - id: Python.Python.3.12
    check: py
  - id: astral-sh.uv
    check: uv
manual:
  - id: esphome
    check: esphome
    install: uv tool install esphome
    note: ESPHome framework for ESP32 devices
  - id: esptool
    check: esptool.py
    install: uv tool install esptool
    note: ESP32 serial flashing tool
vscode-extensions:
  - esphome.esphome-vscode
  - ms-python.python
  - redhat.vscode-yaml
claude-skills:
  - systematic-debugging
  - bash-linux
---

# ESP32 and ESPHome IoT Development

Complete environment for building, compiling, and deploying firmware to ESP32 devices using ESPHome.

## Overview

ESPHome is a YAML-based framework that converts configuration files into compiled C++ firmware for microcontrollers like the ESP32. This profile handles the full development workflow: writing YAML configs, compiling on Windows, and flashing devices via USB or OTA (Over-The-Air) updates.

## Environment Setup

### Package Management with uv

This profile uses `uv` (Astral's universal Python tool installer) instead of pip to manage ESPHome and esptool in isolated environments. This prevents PATH conflicts and version collisions with other Python tools.

Why `uv` over `pip`:

- Installs tools in a dedicated virtual environment
- No pollution of system Python site-packages
- Faster dependency resolution
- Self-contained tool isolation

### Installation

winget installs Python 3.12 and uv. Manual tools (esphome, esptool) are installed via `uv tool install` into `~/.local/bin`.

After initial setup, verify both tools are available:

```bash
esphome version
esptool.py version
```

## ESPHome Project Structure

A typical ESP32 ESPHome project looks like:

```text
my-esp32-project/
├── config.yaml              # Main ESPHome configuration
├── secrets.yaml             # WiFi SSID, passwords, API keys (NEVER commit)
├── .gitignore               # Must include secrets.yaml
├── compiled/                # Build artifacts (*.bin files, .elf, .map)
└── README.md                # Device description, pin layout, sensors
```

### secrets.yaml Pattern

Store sensitive data in `secrets.yaml`, never in `config.yaml`:

```yaml
# secrets.yaml
wifi_ssid: "MyNetwork"
wifi_password: "SuperSecret123"
api_key: "abcd1234efgh5678ijkl9012mnop3456"
```

Reference in config:

```yaml
# config.yaml
esphome:
  name: bedroom-sensor
  platform: esp32
  board: esp32doit-devkit-v1

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
  encryption:
    key: !secret api_key
```

Add to `.gitignore`:

```text
secrets.yaml
compiled/
.esphome/
*.bin
```

## Compilation

Compile a device configuration on Windows:

```bash
uv run esphome compile config.yaml
```

ESPHome generates a `.elf` file and binary `.bin` files in the `compiled/` directory. The process is deterministic—same config always produces the same binary hash.

## Flashing Devices

### OTA Flashing (Preferred)

Once a device is on the network and running ESPHome, update it wirelessly:

```bash
uv run esphome upload config.yaml
```

Requires the device to be reachable on the network and the API key to match the device's config.

### Serial Flashing (Initial Setup or Recovery)

For first-time flashing or when OTA fails, use a USB-to-serial adapter:

```bash
uv run esphome upload config.yaml --port COM3
```

#### Detecting the COM Port on Windows

The device appears as a COM port when connected via USB. Identify it via Device Manager or command line:

PowerShell:

```powershell
Get-WmiObject Win32_SerialPort | Select-Object Name, DeviceID, Description
```

Bash (Git Bash or WSL):

```bash
mode
```

Common USB-to-serial chips on ESP32 dev boards:

- **CP210x (Silicon Labs)**: Found in many dev boards. Driver: [Silicon Labs CP210x VCP driver](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)
- **CH340 (WCH)**: Budget alternative, sometimes missing drivers. Driver: [WCH CH340 driver](http://www.wch.cn/downloads/CH341SER_EXE.html)
- **Built-in FTDI**: Less common on ESP32, usually already installed

If Device Manager shows an unknown device or yellow exclamation mark, the driver is missing. Download the appropriate driver above and install.

Baud rate for flashing: 115200 (esptool detects automatically).

## Common Sensors

ESPHome has built-in support for many sensor types. Reference the [ESPHome sensor docs](https://esphome.io/components/index.html).

### DHT22 (Temperature and Humidity)

```yaml
sensor:
  - platform: dht
    model: DHT22
    pin: GPIO4
    temperature:
      name: "Bedroom Temperature"
    humidity:
      name: "Bedroom Humidity"
    update_interval: 60s
```

### BH1750 (Ambient Light)

Requires I2C bus (SCL on GPIO22, SDA on GPIO21 for typical dev boards):

```yaml
i2c:
  sda: GPIO21
  scl: GPIO22

sensor:
  - platform: bh1750
    name: "Bedroom Light Level"
    address: 0x23
    update_interval: 60s
```

### SSD1306 OLED Display

Small 128x64 pixel display for status and sensor readouts:

```yaml
i2c:
  sda: GPIO21
  scl: GPIO22

display:
  - platform: ssd1306_i2c
    model: "SSD1306 128x64"
    address: 0x3C
    pages:
      - id: page1
        lambda: |-
          it.printf(0, 0, id(title_font), "Temperature");
          it.printf(0, 15, id(big_font), "%.1f°C", id(temp_sensor).state);

font:
  - file: "Roboto_Bold.ttf"
    id: big_font
    size: 20
```

## OTA Updates

Devices running ESPHome are configured for OTA by default. When you change the config and upload, ESPHome:

1. Downloads the new binary over WiFi
2. Verifies the checksum
3. Writes to the inactive partition (A/B boot)
4. Reboots and validates the new partition
5. Falls back to the previous partition if the new one fails to boot

This makes updates safe—a bad config doesn't brick the device.

## Known Windows-Specific Issues

### USB Driver Installation

After plugging in an ESP32 dev board for the first time, Windows may not recognize it. Install the appropriate driver (CP210x or CH340, see Serial Flashing above) and reconnect.

### Python Path Issues (Rare)

If `esphome` or `esptool.py` commands fail with "command not found," verify uv installed them:

```powershell
uv tool list
```

Expected output includes `esphome` and `esptool`. If missing, reinstall:

```bash
uv tool install esphome
uv tool install esptool
```

### Compilation Hangs on Slow Disks

ESPHome compilation can take 30-60 seconds on first run (includes toolchain download). Subsequent compilations are faster. If the process appears stuck for >2 minutes, it may be downloading the ESP32 build tools for the first time. Be patient or check Windows Task Manager to confirm `uv` process is still active.

## Integration with Home Assistant

ESPHome devices expose themselves to Home Assistant via the ESPHome integration. Devices emit native MQTT or ESPHome API messages. Home Assistant auto-discovers new entities once you add the device's API key.

Configure ESPHome for Home Assistant:

```yaml
api:
  encryption:
    key: !secret ha_api_key

homeassistant:
```

## Next Steps

1. Create a new directory for your first project: `mkdir my-esp32-sensor`
2. Run `uv run esphome wizard my-esp32-sensor/config.yaml` to generate a starter config
3. Fill in `secrets.yaml` with your WiFi details
4. Compile with `uv run esphome compile my-esp32-sensor/config.yaml`
5. Flash to your ESP32 dev board (serial or OTA)
6. Integrate with Home Assistant or other automation platform

## Resources

- [ESPHome Official Docs](https://esphome.io/)
- [ESPHome Component Library](https://esphome.io/components/index.html)
- [Home Assistant ESPHome Integration](https://www.home-assistant.io/integrations/esphome/)
- [uv Documentation](https://docs.astral.sh/uv/)
