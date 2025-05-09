# Bank Transaction Tracker App Architecture

## App Structure Overview

```
lib/
├── main.dart                  # App entry point
├── models/                    # Data models
│   ├── transaction.dart       # Transaction model
│   └── app_config.dart        # App configuration model
├── providers/                 # State management
│   └── app_state_provider.dart # Global state provider
├── screens/                   # UI screens
│   ├── home_screen.dart       # Main screen with transaction list
│   ├── app_selection_screen.dart # Screen to select banking apps
│   ├── google_sheets_config_screen.dart # Google Sheets setup
│   └── settings_screen.dart   # App settings
├── services/                  # Core functionality
│   ├── sms_service.dart       # SMS listening service
│   ├── notification_service.dart # Notification listening service
│   ├── background_service.dart  # Background processing service
│   ├── google_sheets_service.dart # Google Sheets integration
│   ├── database_service.dart  # Local storage service
│   └── transaction_parser.dart # Message parsing logic
├── utils/                     # Utilities
│   ├── constants.dart         # App constants
│   └── permission_helper.dart # Permission handling
└── widgets/                   # Reusable UI components
    └── transaction_list_item.dart # Transaction UI component
```

## Core Features

1. **SMS & Notification Listening**
   - Monitors incoming SMS messages from banking services
   - Listens to notifications from selected banking apps
   - Uses Android platform integration via Method Channels

2. **Transaction Parsing**
   - Extracts transaction details from messages
   - Identifies amount, sender, timestamp, and direction (IN/OUT)
   - Supports multiple Vietnamese banks (Vietcombank, MB Bank, etc.)

3. **Google Sheets Integration**
   - OAuth authentication via Google Sign-In
   - Uploads transaction data to selected spreadsheet
   - Creates sheets and headers automatically
   - Handles offline syncing and duplicates

4. **Background Processing**
   - Runs as a foreground service with persistent notification
   - Uses WorkManager for periodic background synchronization
   - Battery-optimized operation

## Data Flow

1. **SMS/Notification Received** → Handled by respective services
2. **Message Parsed** → Transaction object created
3. **Transaction Stored** → Saved to local SQLite database
4. **User Notified** → Notification shows transaction details
5. **Data Synced** → Transaction uploaded to Google Sheets
6. **UI Updated** → Transaction list refreshed

## Key Technologies

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **SQLite (sqflite)** - Local database
- **Telephony** - SMS interception
- **flutter_notification_listener** - Notification access
- **Google APIs** - Sheets API integration
- **WorkManager** - Background task scheduling