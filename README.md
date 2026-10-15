# Andhika Switch

<p align="center">
  <strong>A personal dead man's switch system designed to automate actions when a user stops checking in.</strong>
</p>

<p align="center">
  <em>Stay connected. Stay in control. Let automation handle the rest.</em>
</p>

---

## Overview

**Andhika Switch** is a personal automation and safety project inspired by the concept of a *Dead Man's Switch*.

The system monitors a user's activity through periodic check-ins. If the user fails to confirm that they are still active within a configured time window, the system can transition through predefined states and execute configured actions when the trigger conditions are met.

The project is designed around a web-based management dashboard and a mobile application, separating switch configuration from everyday check-ins.

## Key Features

- **Switch Management** — Create and manage switches through the web dashboard.
- **Periodic Check-ins** — Confirm that you are still active using the mobile application.
- **Automated State Transitions** — Track switch status based on check-ins, deadlines, and grace periods.
- **Configurable Triggers** — Define actions to execute when a switch reaches its trigger condition.
- **Notifications** — Receive notifications about relevant switch status changes.
- **Event History** — Maintain records of check-ins and switch events for monitoring and debugging.
- **Server-side Scheduling** — Keep deadlines and trigger decisions on the backend rather than relying on the mobile device's local clock.

## How It Works

1. **Configure a switch**  
   Create a switch and define its check-in interval, grace period, and intended trigger behavior through the web dashboard.

2. **Check in through mobile**  
   Open the mobile application and confirm that you are still active.

3. **Monitor the deadline**  
   The backend evaluates check-ins and determines whether the switch remains active or requires further action.

4. **Enter the grace period**  
   If a check-in deadline is missed, the system can provide a configured grace period before triggering an action.

5. **Execute the configured action**  
   If the trigger conditions are satisfied, the backend executes the associated action, such as sending an email notification.

6. **Receive status updates**  
   The mobile application can receive notifications when relevant switch status changes occur.

## Architecture

The project follows a client-server architecture.

```text
                 ┌──────────────────────┐
                 │    Web Dashboard     │
                 │ Switch Configuration │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │      Flask API       │
                 │ Authentication       │
                 │ Check-in Processing  │
                 │ Deadline Monitoring  │
                 │ Trigger Execution    │
                 └──────────┬───────────┘
                            │
                 ┌──────────┴───────────┐
                 ▼                      ▼
        ┌────────────────┐     ┌────────────────┐
        │ MySQL Database │     │ Notification   │
        │ Users & Switches│    │ Services       │
        │ Events & Logs  │     └────────────────┘
        └────────────────┘
                            ▲
                            │ HTTPS / REST API
                 ┌──────────┴───────────┐
                 │   Flutter Mobile     │
                 │ Alive Check-in       │
                 │ Status Notifications │
                 └──────────────────────┘
```

The backend is responsible for evaluating deadlines and trigger conditions. The mobile application acts as a check-in client and notification receiver, while the web dashboard handles switch management.

## Technology Stack

| Component | Technology |
|---|---|
| Web backend / API | Python, Flask |
| Database | MySQL / MariaDB |
| Mobile application | Flutter, Dart |
| API communication | HTTP / REST |
| Push notifications | Firebase Cloud Messaging (planned integration) |
| Email notifications | Resend (planned / configurable integration) |

*The technology list and integration status should be updated as implementation progresses.*

## Switch Lifecycle

A switch can follow a lifecycle such as:

```text
       ARMED
          │
          │ Check-in deadline missed
          ▼
        GRACE
          │
          ├── Valid check-in ──► ARMED
          │
          │ Grace period expires
          ▼
      TRIGGERED
```

- **ARMED** — The switch is monitoring the user's check-in deadline.
- **GRACE** — The deadline has been missed, and the grace period is in progress.
- **TRIGGERED** — The configured trigger conditions have been satisfied and the corresponding action is initiated.

Exact transition rules depend on the backend implementation.

## Project Structure

The repository may evolve as the web application, backend, and mobile client are developed.

A possible high-level structure is:

```text
switch/
├── app/                 # Backend application
│   ├── routes/          # API and web routes
│   ├── services/        # Business logic and triggers
│   ├── models/          # Data models
│   └── config.py        # Application configuration
├── mobile/              # Flutter application
├── web/                 # Web dashboard assets and templates
├── migrations/          # Database migrations
├── tests/               # Automated tests
├── requirements.txt     # Python dependencies
├── .env.example         # Example environment variables
└── README.md
```

*This is an illustrative structure, not a guarantee of the repository's current file layout.*

## Getting Started

### Prerequisites

Before running the project, prepare:

- Python 3.11 or another supported Python version.
- MySQL or MariaDB.
- Flutter SDK for mobile development.
- Git.
- Required service credentials for enabled notification integrations.

### 1. Clone the repository

```bash
git clone https://github.com/FajarFarel/switch.git
cd switch
```

### 2. Set up the Python environment

```bash
python -m venv .venv
```

Activate the environment.

**Windows PowerShell**
```powershell
.\.venv\Scripts\Activate.ps1
```

**Linux**
```bash
source .venv/bin/activate
```

Install dependencies if `requirements.txt` is present:

```bash
pip install -r requirements.txt
```

### 3. Configure environment variables

Create a local `.env` file based on `.env.example`, if provided.

Typical configuration may include:

```env
SECRET_KEY=replace_with_a_secure_random_secret
DATABASE_URL=mysql_connection_string
RESEND_API_KEY=your_resend_api_key
MAIL_FROM=your_verified_sender_address
```

Use the actual variable names expected by the application. Never commit real credentials, API keys, or production database passwords.

### 4. Configure the database

Create the database and apply the migrations or SQL schema supplied by the project.

Ensure the application can connect to the database before starting the backend.

### 5. Run the backend

Use the application's actual entry point. For a Flask application configured with `app` as its package:

```bash
flask --app app run --debug
```

The development server should not be exposed directly to the public internet in production.

### 6. Run the mobile application

If the Flutter application is available in the `mobile/` directory:

```bash
cd mobile
flutter pub get
flutter run
```

Complete the API base URL and Firebase configuration required by the mobile client before testing.

*These commands are a setup template. Adjust paths, entry points, database migrations, and configuration to match the implementation.*

## Security Considerations

Because this system can execute automated actions, security and reliability are important design requirements.

- Keep API keys and secrets outside version control.
- Authenticate API requests and authorize access to individual switches.
- Use HTTPS for communication between clients and the backend.
- Validate check-ins and enforce deadlines on the server.
- Prevent duplicate trigger execution when background jobs retry.
- Record important state transitions and execution results.
- Test missed check-ins, expired grace periods, network failures, and notification delivery.
- Use explicit confirmation and appropriate safeguards for potentially irreversible actions.

A missed check-in is not definitive proof that a user is unavailable. Network outages, device failures, and other circumstances should be considered when designing trigger behavior.

## Development Status

Andhika Switch is a work in progress. Features, API contracts, deployment procedures, and integrations may change as development continues.

## Roadmap

- [ ] Complete the web-based switch management dashboard.
- [ ] Finalize the backend API and authentication flow.
- [ ] Implement server-side deadline and grace-period processing.
- [ ] Develop the Flutter check-in interface.
- [ ] Add mobile push notifications for switch status changes.
- [ ] Implement and verify configurable trigger actions.
- [ ] Add automated tests for lifecycle transitions and failure scenarios.
- [ ] Prepare production deployment and operational monitoring.

## Contributing

Suggestions, bug reports, and improvements are welcome. Please open an issue to discuss significant changes before submitting a pull request.

## Disclaimer

Andhika Switch is an experimental personal automation project. It should not be relied upon as the sole mechanism for emergency response, critical data protection, or other safety-critical operations without appropriate testing and safeguards.

## License

No license has been specified yet. Until a license is added to the repository, permission to reuse, distribute, or modify this project's code should not be assumed.
