# How to Run the IoT Platform Application in VSCode

This document provides step-by-step instructions to set up and run the IoT Platform application, including the Flutter frontend and the Node.js/Express backend with a MySQL database, within Visual Studio Code.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

1.  **Visual Studio Code (VSCode):** [Download VSCode](https://code.visualstudio.com/)
2.  **Flutter SDK:** [Install Flutter](https://flutter.dev/docs/get-started/install)
    *   Ensure Flutter is correctly set up and `flutter doctor` reports no issues.
3.  **Node.js and npm:** [Download Node.js](https://nodejs.org/en/download/)
    *   npm (Node Package Manager) is installed automatically with Node.js.
4.  **MySQL Server:** [Download MySQL Community Server](https://dev.mysql.com/downloads/mysql/)
    *   You will need a running MySQL instance. You can use XAMPP, MAMP, Docker, or a standalone MySQL installation.
5.  **Git:** [Download Git](https://git-scm.com/downloads)

## Project Setup

1.  **Clone the Repository:**
    If you received this project as a Git repository, clone it to your local machine:
    ```bash
    git clone <repository_url>
    cd iot_platform
    ```
    If you received it as a zip file, extract it and navigate into the `iot_platform` directory.

2.  **Open in VSCode:**
    Open the `iot_platform` folder in VSCode:
    ```bash
    code .
    ```

## Backend Setup (Node.js/Express & MySQL)

1.  **Navigate to Backend Directory:**
    Open a new terminal in VSCode (Terminal > New Terminal) and navigate to the backend folder:
    ```bash
    cd backend
    ```

2.  **Install Dependencies:**
    Install the Node.js dependencies:
    ```bash
    npm install
    ```

3.  **Configure Environment Variables:**
    Create a `.env` file in the `backend` directory with your MySQL database credentials. Replace the placeholders with your actual database information.
    ```
    # .env file in backend/
    PORT=5000
    DB_HOST=localhost
    DB_USER=root
    DB_PASSWORD=your_mysql_password
    DB_NAME=iot_platform_db
    ```
    *   **`DB_HOST`**: Usually `localhost` if MySQL is running on your machine.
    *   **`DB_USER`**: Your MySQL username (commonly `root`).
    *   **`DB_PASSWORD`**: Your MySQL password.
    *   **`DB_NAME`**: The name of the database to be created (`iot_platform_db`).

4.  **Setup MySQL Database:**
    *   Ensure your MySQL server is running.
    *   Open a MySQL client (e.g., MySQL Workbench, command-line client, phpMyAdmin) and execute the SQL script located at `database/schema.sql`.
    *   Alternatively, you can use the command line:
        ```bash
        mysql -u root -p < database/schema.sql
        # Enter your MySQL password when prompted
        ```
    *   This script will create the `iot_platform_db` database and necessary tables, along with initial project data.

5.  **Run the Backend Server:**
    Start the Node.js backend server. You can use `nodemon` for automatic restarts during development.
    ```bash
    npm run dev
    # Or for production:
    # npm start
    ```
    You should see messages indicating the server is running and connected to the database.

## Frontend Setup (Flutter)

1.  **Navigate to Frontend Directory:**
    Open another new terminal in VSCode and navigate to the Flutter application folder:
    ```bash
    cd flutter_app
    ```

2.  **Get Flutter Dependencies:**
    Fetch the Flutter packages:
    ```bash
    flutter pub get
    ```

3.  **Run the Flutter Application:**
    *   Ensure you have an Android emulator, iOS simulator, or a physical device connected and recognized by Flutter (`flutter devices`).
    *   Run the application:
    ```bash
    flutter run
    ```
    The application should launch on your selected device or emulator.

## VSCode Extensions (Recommended)

For a better development experience in VSCode, consider installing these extensions:

*   **Dart:** Provides Dart language support and debugging features.
*   **Flutter:** Adds Flutter development tools, including widgets inspector and hot reload.
*   **ESLint:** For JavaScript/Node.js linting.
*   **Prettier - Code formatter:** For consistent code formatting.
*   **MySQL:** For managing MySQL databases directly from VSCode.

## Troubleshooting

*   **Flutter Doctor Issues:** Run `flutter doctor` and address any reported issues.
*   **Backend Port in Use:** If the backend fails to start, the port (default 5000) might be in use. Change the `PORT` in your `.env` file or free up the port.
*   **MySQL Connection Errors:** Double-check your `DB_HOST`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME` in the `.env` file and ensure your MySQL server is running.
*   **Network Issues:** Ensure both your development machine and any physical IoT devices are on the same network for scanning functionalities.

## Next Steps (Development)

*   Implement actual API calls from Flutter to the Node.js backend for authentication and project data.
*   Integrate GitHub OAuth for repository access.
*   Develop real-time communication for serial monitor and IoT device data.
*   Implement actual network scanning and Bluetooth pairing logic.

---

**Author:** Manus AI
**Date:** June 18, 2026
