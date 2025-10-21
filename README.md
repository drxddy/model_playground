# Okara Chat

Okara Chat is a flutter app that allows users to chat with multiple AI models and compare results & performance side-by-side.

## Screenshots

| Side-by-Side Comparison | SSE Streaming | Markdown Formatting | Follow-up Suggestions | Conversation History | Fast Response Mode |
| :---: | :---: | :---: | :---: | :---: | :---: |
| ![Side-by-Side Model Output and Perf](assets/screenshots/Side-by-Side%20Model%20Output%20and%20Perf.png) | ![SSE Output Streaming with Stop Option](assets/screenshots/SSE%20Output%20Streaming%20with%20Stop%20Option.png) | ![Markdown Formatting](assets/screenshots/Markdown%20Formatting.png) | ![Followup Suggestions](assets/screenshots/Followup%20Suggestions.png) | ![Conversation History](assets/screenshots/Conversation%20History.png) | ![Fast Response Mode With Groq llama](assets/screenshots/Fast%20Response%20Mode%20With%20Groq%20llama.png) |


## Architecture

Follows clean architecture, separating concerns into distinct layers:

-   **UI Layer**: Built with Flutter, this layer is responsible for rendering the user interface and handling user input. It includes screens like `ChatScreen` and widgets such as `ModelResponsesView`.
-   **State Management**: It use **Riverpod** for state management, ensuring a reactive and predictable state flow throughout the application. The `ChatStateProvider` manages the conversation history and model responses.
-   **Service Layer**: This layer contains the business logic. The `AIGatewayService` is responsible for making API calls to the AI Gateway, which in turn routes requests to the appropriate AI models.
-   **Data Layer**: The data layer handles data persistence. It use **Sembast**, a NoSQL database, to store conversation history locally on the device.

## Key Features 

-   **Real-time Streaming with SSE**: The application utilizes Server-Sent Events (SSE) to stream responses from the AI models in real-time. The `AIGatewayService` uses the `flutter_client_sse` package to subscribe to the event stream, allowing the UI to update character-by-character as the response is being generated.

-   **Parallel Response Handling**: A core feature is the ability to query multiple AI models simultaneously. The `ParallelResponseHandler` manages these concurrent requests, listening to multiple streams and updating the application's state via Riverpod as data from each model arrives.

-   **Performance Comparison**: The app calculates and displays key performance metrics for each model's response, including latency and throughput (tokens per second). This allows for a direct comparison of the models' performance on a given prompt. The `TokenCalculator` assists in this process.

-   **Follow-up Suggestions**: After a model provides a response, the app can generate and display relevant follow-up questions. This is achieved by sending the conversation history back to the AI model with a prompt asking it to suggest the next logical questions a user might have.

-   **Local Conversation Caching**: To provide a persistent chat history, all conversations are cached locally using **Sembast**, a lightweight NoSQL database. A `DatabaseService` and associated DAOs manage the storage and retrieval of messages and conversations.


## File Structure

The project is organized into the following directories:

```
lib/
├── data/
│   ├── daos/               # Data Access Objects for Sembast
│   └── repositories/       # Repositories to abstract data sources
├── models/                 # Data models for the application
├── providers/              # Riverpod providers for state management
├── screens/                # UI screens for the application
├── services/               # Business logic and API communication
├── utils/                  # Utility functions and constants
└── widgets/                # Reusable UI widgets
```

## Setup Instructions

To get the project up and running, follow these steps:

1.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Set up API Key**:
    This project uses the `envied` package to manage environment variables. You will need to create a `.env` file in the root of the project and add your API key:
    ```
    AI_GATEWAY_API_KEY==your_api_key
    ```

3.  **Run Code Generator**:
    The project uses `build_runner` to generate code for data models and environment variables. Run the following command to generate the necessary files:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the application**:
    ```bash
    flutter run
    ```

## Code Generation

This project relies on code generation for two main purposes:

-   **JSON Serialization**: It use `json_serializable` to generate `toJson` and `fromJson` methods for our data models. This simplifies the process of converting Dart objects to and from JSON.
-   **Environment Variables**: The `envied` package is used to securely manage API keys and other environment-specific variables.

To run the code generator, use the following command:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This command will generate the necessary `.g.dart` files for your models and the `env.g.dart` file for your environment variables. It's important to run this command whenever you make changes to your models or the `.env` file.
