# T-Racks SoftDev 1

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Before you begin, ensure you have the following installed:

* **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (ensure it's in your PATH).
* **IDE**: Visual Studio Code (with Flutter/Dart extensions) or Android Studio.
* **Target Device**: An Android Emulator, iOS Simulator (macOS only), or a physical device connected via USB.

### Installation

1.  **Clone the repository**
    Open your terminal and run:
    ```bash
    git clone [https://github.com/Scorch879/t_racks_softdev_1.git](https://github.com/Scorch879/t_racks_softdev_1.git)
    ```

2.  **Navigate to the project directory**
    ```bash
    cd t_racks_softdev_1
    ```

3.  **Install dependencies**
    Fetch all necessary packages listed in `pubspec.yaml`:
    ```bash
    flutter pub get
    ```
4.  **Set Up Environment Variables**
    This project uses an .env file for environment variables (like API keys or Supabase URLs).
    After creating the file, open .env in your editor and fill in the required values.
    The environemntal variables are shared in our private group chat on Discord.

   

### Running the App

1.  Ensure your target device is running and connected. You can check this by running:
    ```bash
    flutter devices
    ```

2.  Run the app:
    ```bash
    flutter run
    ```

### Troubleshooting

If you encounter issues, run the standard Flutter diagnostic tool to check your environment setup:
```bash
flutter doctor
