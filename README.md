# Sabay Shop E-Commerce Project

A complete e-commerce solution featuring a Laravel backend, a React-based web dashboard, and a Flutter mobile application.

## Project Structure

- **`/backend`**: Laravel 13+ REST API.
- **`/frontend`**: React + TypeScript + Vite web dashboard/admin panel.
- **`/sabay_shop_app`**: Flutter mobile application.

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **PHP 8.3+** & **Composer**
- **Node.js 18+** & **npm**
- **Flutter SDK (3.0.0+)** & **Dart**
- **MySQL** or any supported database
- **Android Studio / Xcode** (for mobile development)

---

## 1. Backend Setup (Laravel)

1.  Navigate to the backend directory:
    ```bash
    cd backend
    ```
2.  Install and setup the project automatically:
    ```bash
    composer install
    composer run setup
    ```
    *Note: The setup script will copy `.env`, generate the app key, run migrations, and install npm dependencies.*

3.  Configure your database in `.env`:
    ```env
    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=sabay_shop_db
    DB_USERNAME=root
    DB_PASSWORD=your_password
    ```

4.  Seed the database (optional but recommended):
    ```bash
    php artisan db:seed
    ```

5.  Start the development environment:
    ```bash
    composer run dev
    ```
    *This starts the server, queue listener, and Vite simultaneously.*

---

## 2. Frontend Setup (React)

1.  Navigate to the frontend directory:
    ```bash
    cd frontend
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Configure environment variables:
    ```bash
    cp .env.example .env
    ```
    *(Ensure `VITE_API_URL` points to your Laravel server, e.g., `http://localhost:8000/api`)*
4.  Start the development server:
    ```bash
    npm run dev
    ```

---

## 3. Mobile App Setup (Flutter)

1.  Navigate to the mobile app directory:
    ```bash
    cd sabay_shop_app
    ```
2.  Install Flutter dependencies:
    ```bash
    flutter pub get
    ```
3.  Run code generation (for Riverpod and other generators):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
4.  Run the app:
    - For Android: `flutter run`
    - For iOS: `cd ios && pod install && cd .. && flutter run`

---

## Cloudinary Configuration

This project uses **Cloudinary** for image storage. To enable image uploads, add your Cloudinary credentials to `backend/.env`:

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## API Documentation

Once the backend is running, you can explore the API structure in the `routes/api.php` file.

## Features

- **Auth**: Secure authentication using Laravel Sanctum.
- **Products**: Complete product management with categories and favorites.
- **Chat**: Integrated chat system for customer support.
- **Dashboard**: Store dashboard for managing orders and products.
- **Localization**: Multi-language support in both mobile and web apps.
