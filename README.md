# Smart Kisan: Digital Farming Assistant
Welcome to the Smart Kisan project. This app is designed to help farmers make data-driven decisions about their crops, monitor weather conditions, and get AI-powered advice for disease management.

## What does this app do?
I built this app to bridge the gap between traditional farming and modern technology. Here are the core features:

- **AI Crop Advisory**: A chat-based interface where you can ask questions about your crops and receive real-time, context-aware farming advice.

- **Pest & Disease Identification**: Upload images or describe symptoms to get instant identification and recommended treatments for common crop diseases.

- **Weather Monitoring**: Get accurate local weather forecasts so you can plan your planting and harvesting schedules effectively.

- **Market Price Updates**: Keep track of the current market rates for your crops to ensure you get the best value for your produce.

- **Water Optimization**: Tools to help manage irrigation schedules, ensuring crops get the right amount of water based on local conditions.

##  How to get it running
If you want to run this project on your local machine, follow these steps:

### Prerequisites
- Make sure you have Flutter installed.
- Ensure you have a Python environment set up for the backend (check the `ml_backend` folder).

### Step-by-Step Setup
1. **Clone the repository**: `git clone [https://github.com/Surajsah1595/smart_kisan]`
2. **Install dependencies**: Navigate to the project folder and run: `flutter pub get`
3. **Start the ML Backend**: Open a terminal in the `ml_backend` folder and run the server (refer to `start_ml_server.bat` for quick access).
4. **Run the app**: Use your favorite IDE (VS Code recommended) or run the command: `flutter run`

## Project Structure
- `/lib`: Contains all the Flutter UI and logic code.
- `/ml_backend`: Contains the machine learning scripts that power the disease detection and AI chat.
- `/assets`: Holds images, fonts, and icons used in the app.
- `/scripts`: Utility tools used for maintenance and translation management.

---
Built for the Final Year Project. For detailed specs, refer to `SMART_KISAN_FULL_COMPONENTS_SPEC.md`
