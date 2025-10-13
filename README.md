# Altas AI

Altas AI is a Flutter application that allows users to take a photo of a menu, and the app will translate and explain the menu items.

## Features

*   **Menu Translation**: Translate menu items from a photo.
*   **Menu Explanation**: Get explanations of menu items.
*   **Cross-Platform**: Works on iOS, Android, and Web.
*   **Subscription Model**: Offers a subscription for premium features.

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

*   [Flutter](https://flutter.dev/docs/get-started/install)
*   A [Supabase](https://supabase.io/) account

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/altas_ai_app.git
    cd altas_ai_app
    ```

2.  **Set up Supabase:**
    *   Create a new project on Supabase.
    *   Navigate to the **SQL Editor** in your Supabase project dashboard.
    *   Open the `supabase_setup.sql` file from this project, copy its content, and run it in the Supabase SQL Editor. This will set up the necessary tables and policies.
    *   Find your project's **URL** and **anon key** in **Project Settings > API**.

3.  **Configure the application:**
    *   Open the `lib/main.dart` file.
    *   Replace the placeholder values for `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` with your actual Supabase URL and anon key:
        ```dart
        await Supabase.initialize(
          url: 'YOUR_SUPABASE_URL',
          anonKey: 'YOUR_SUPABASE_ANON_KEY',
        );
        ```

4.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

5.  **Run the application:**
    ```sh
    flutter run
    ```

## Built With

*   [Flutter](https://flutter.dev/) - The UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
*   [Supabase](https://supabase.io/) - The open source Firebase alternative.
*   [Stripe](https://stripe.com/) - For handling payments.