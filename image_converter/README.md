# Handwritten Invoice Converter

This is a Flutter application that helps in converting handwritten invoices into digital format.

## Overview

The app allows users to capture or select images of handwritten invoices, process them to extract information using AI (Gemini), and manage them locally. Users can generate digital PDF invoices from the extracted data, print them, or share them. The app also supports multiple languages and a dark/light theme mode.

## Technologies Used

- **Framework**: [Flutter](https://flutter.dev/)
- **Programming Language**: [Dart](https://dart.dev/)
- **AI / OCR**: Google Gemini API (for extracting invoice data from images)
- **Local Database**: SQLite (via `sqflite` package)
- **State Management & UI**: Flutter's native state management (setState, ValueNotifier)

## Packages & Libraries

The project relies on the following key packages:
- **`image_picker`**: For capturing photos from the camera or selecting images from the gallery.
- **`http`**: For making network requests to the Gemini API.
- **`pdf` & `printing`**: For generating digital PDF invoices and providing printing capabilities.
- **`widgets_to_image`**: To convert Flutter widgets (like the invoice receipt) directly into images/PDFs.
- **`sqflite` & `path`**: For local database storage, enabling offline access to saved invoices.
- **`path_provider`**: To access commonly used locations on the device filesystem.
- **`intl`**: For internationalization and proper date formatting.
- **`cupertino_icons`**: For iOS-style icons.

## Features
- 📸 Capture or upload handwritten invoices.
- 🧠 AI-powered data extraction using Gemini.
- 💾 Local storage of recent invoices.
- 📄 Export to PDF and print functionality.
- 🌓 Dark mode and Light mode support.
- 🌐 Multi-language support (English and Urdu).
