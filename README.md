# Weet: Connect the Mind
Weet is a Flutter application designed to visualize personal networks based on relationship scores and facilitate seamless connection through QR scanning. This project is licensed under the GNU GPL v3.

---

## Getting Started

Follow these steps to build and run the project in your local environment.

### 1. Prerequisites
* Flutter SDK (Latest stable version recommended)
* Supabase Account and Project

### 2. Environment Variables Configuration

For security, API keys and URLs are managed via environment variables. You must convert the template file into a functional `.env` file to run the app.

1. Locate the `.env.example` file in the root directory.
2. Rename or copy it to `.env` using the following command:
   ```bash
   cp .env.example .env
   ```
Open the newly created .env file and enter your Supabase credentials:

SUPABASE_URL=[https://your-project-id.supabase.co](https://your-project-id.supabase.co)
SUPABASE_ANON_KEY=your_sb_public_anon_key
3. Installation and Execution
Run the following commands in your terminal to install dependencies and launch the application:

```bash
# Install dependencies
flutter pub get
```
```bash
# Run the application
flutter run
```
Key Features
Network Visualization: A dynamic map where the distance between the center and nodes is determined by relationship scores.

Bidirectional QR Connection: Scanning a friend's QR code automatically adds you to their list and them to yours.

Privacy-Focused Chat: Chat history is automatically cleared after 30 days to protect user privacy.

License
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

For more details, see the LICENSE file.

Copyright (C) 2026 Yooniverse Lab
