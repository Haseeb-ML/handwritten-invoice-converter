# Handwritten Invoice Converter

This is a Flutter application that helps in converting handwritten invoices into digital format.

## Overview

The app allows users to capture or select images of handwritten invoices, process them to extract information, and potentially generate digital PDF invoices. 

## Packages/Libraries Used

The project relies on the following key packages:
- **image_picker**: For capturing photos from the camera or selecting images from the gallery.
- **http**: For making network requests (e.g., to an OCR API).
- **pdf & printing**: For generating digital PDF invoices and printing them.
- **widgets_to_image**: To convert Flutter widgets directly into images.
- **sqflite & path**: For local database storage of invoices.
- **path_provider**: To find commonly used locations on the filesystem.
- **intl**: For internationalization and date formatting.
