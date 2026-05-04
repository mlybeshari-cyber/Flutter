# Traccar GPS Flutter

## Shqip

Aplikacion Flutter për integrimin me **Traccar GPS Tracking Server API** në Android dhe iOS.

### Përshkrimi

Ky aplikacion ofron:
- 🔐 **Autentikim** me Traccar Server (Basic Auth)
- 📋 **Listën e pajisjeve** GPS me statuse online/offline
- 🗺️ **Hartë interaktive** me OpenStreetMap për çdo pajisje
- 📍 **Informacion pozicioni** në kohë reale (koordinata, shpejtësi, lartësi, drejtim)
- 💾 **Ruajtje lokale** e kredencialeve
- 🌓 **Temë e errët dhe e çelët** (dark/light mode)

### Instalimi

```bash
# Klonimi i projektit / Clone the project
git clone https://github.com/mlybeshari-cyber/Flutter.git
cd Flutter

# Instalimi i varësive / Install dependencies
flutter pub get

# Drejtimi i aplikacionit / Run the application
flutter run
```

### Si të lidhesh me Traccar Server

1. Hap aplikacionin
2. Fut URL-në e serverit (p.sh. `https://demo.traccar.org/api`)
3. Fut email-in dhe fjalëkalimin
4. Kliko **"Lidhu / Connect"**

#### Server Demo
- **URL**: `https://demo.traccar.org/api`
- **Email**: `demo@traccar.org`
- **Password**: `demo`

### Struktura e Projektit

```
lib/
  main.dart                 # Pika e hyrjes / Entry point
  models/
    device.dart             # Model i pajisjes / Device model
    position.dart           # Model i pozicionit / Position model
    session.dart            # Model i sesionit / Session model
  services/
    traccar_service.dart    # Shërbimi API / API service
  screens/
    login_screen.dart       # Ekrani i kyçjes / Login screen
    devices_screen.dart     # Lista e pajisjeve / Devices list
    map_screen.dart         # Harta / Map screen
  widgets/
    device_card.dart        # Kartë pajisje / Device card widget
```

### Veçoritë / Features

| Veçoria / Feature | Statusi / Status |
|---|---|
| Login me Traccar | ✅ |
| Lista e pajisjeve | ✅ |
| Statusi online/offline | ✅ |
| Pull-to-refresh | ✅ |
| Harta me OpenStreetMap | ✅ |
| Informacion pozicioni | ✅ |
| Histori pozicionesh | ✅ |
| Ruajtja e kredencialeve | ✅ |
| Dark/Light theme | ✅ |

---

## English

A Flutter application for integrating with **Traccar GPS Tracking Server API** on Android and iOS.

### Description

This application provides:
- 🔐 **Authentication** with Traccar Server (Basic Auth)
- 📋 **Device list** with online/offline status indicators
- 🗺️ **Interactive map** with OpenStreetMap for each device
- 📍 **Real-time position info** (coordinates, speed, altitude, course)
- 💾 **Local credential storage**
- 🌓 **Dark/Light theme** support

### Installation

```bash
# Clone the project
git clone https://github.com/mlybeshari-cyber/Flutter.git
cd Flutter

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### How to Connect to Traccar Server

1. Open the application
2. Enter the server URL (e.g. `https://demo.traccar.org/api`)
3. Enter your email and password
4. Click **"Lidhu / Connect"**

#### Demo Server
- **URL**: `https://demo.traccar.org/api`
- **Email**: `demo@traccar.org`
- **Password**: `demo`

### Dependencies

```yaml
http: ^1.2.0                # HTTP client
shared_preferences: ^2.2.2  # Local storage
flutter_map: ^6.1.0         # OpenStreetMap widget
latlong2: ^0.9.0            # Lat/Lon support
intl: ^0.19.0               # Date/time formatting
provider: ^6.1.2            # State management
```

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/session` | Login |
| DELETE | `/session` | Logout |
| GET | `/session` | Get current session |
| GET | `/devices` | List all devices |
| GET | `/devices/{id}` | Get specific device |
| GET | `/positions` | Get current positions |
| GET | `/positions?deviceId=&from=&to=` | Position history |

### Requirements

- Flutter SDK `>=3.0.0`
- Android SDK 21+
- iOS 12+

### Screenshots

| Login | Devices | Map |
|-------|---------|-----|
| ![Login Screen](docs/login.png) | ![Devices Screen](docs/devices.png) | ![Map Screen](docs/map.png) |

> Screenshots available after first run / Pamjet e ekranit disponohen pas xhirimit të parë