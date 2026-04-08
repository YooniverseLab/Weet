# Weet Project

## Overview
Weet is a Flutter application that allows users to connect with friends, chat, and manage their relationships through a visual relationship map. The app utilizes Supabase for backend services, including authentication and real-time messaging.

## Features
- User authentication via email or ID
- Registration with mandatory ID input
- Password recovery functionality
- Chat functionality for messaging friends
- Visual representation of relationships through a relationship map
- QR code scanning for connecting with friends

## Setup Instructions

### Prerequisites
- Flutter SDK installed
- Dart SDK installed
- Supabase account and project created

### Installation
1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd Weet
   ```
3. Install dependencies:
   ```
   flutter pub get
   ```

### Configuration
1. Replace the Supabase URL and anon key in `lib/main.dart` with your Supabase project credentials:
   ```dart
   await Supabase.initialize(
     url: 'https://your-supabase-url.supabase.co',
     anonKey: 'your-anon-key',
   );
   ```

### Running the App
To run the application, use the following command:
```
flutter run
```

## Usage
- Launch the app and log in using your email or ID.
- If you are a new user, register by providing your ID, email, and password.
- Use the QR code feature to connect with friends.
- Access the chat functionality to send and receive messages.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for details.