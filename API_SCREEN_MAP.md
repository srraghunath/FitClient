cd # FitBond: Screen to API Endpoint Mapping

This document maps the primary screens and user actions in the FitBond mobile app to the corresponding backend API endpoints. The flow is ordered logically from onboarding to core application usage.

---

## 1. Onboarding & Authentication

These endpoints handle the initial user journey of creating an account and logging in.

| Screen / Feature | User Role | HTTP Method & Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Signup** | Client / Trainer | `POST /api/auth/signup` | Creates a new user account. The request body must specify the `role` as either `CLIENT` or `TRAINER`. |
| **Login** | Client / Trainer | `POST /api/auth/login` | Authenticates a user and returns a JWT access token for subsequent requests. |

---

## 2. Trainer-Specific Features

These endpoints are used by users with the `TRAINER` role to manage their clients and their clients' schedules.

| Screen / Feature | User Role | HTTP Method & Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Link New Client** | Trainer | `POST /api/trainer/clients` | Links a client to the trainer's account using the client's email address. |
| **Create/Edit Schedule** | Trainer | `POST /api/schedule/template/:clientId/:dayOfWeek` | Creates or updates a weekly schedule template for a specific client on a given day of the week. |
| **Add Workout to Schedule**| Trainer | `POST /api/schedule/workout/:templateId` | Adds a specific exercise (workout) to a client's schedule template. |
| **Add Meal to Schedule** | Trainer | `POST /api/schedule/meal/:templateId` | Adds a specific food item (meal) to a client's schedule template. |
| **View Client Progress** | Trainer | `GET /api/activity/summary/:clientId` | Retrieves the activity log history for a specific client. |

---

## 3. Client-Specific Features

These endpoints are used by users with the `CLIENT` role to view their schedules and log their activities.

| Screen / Feature | User Role | HTTP Method & Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **View Today's Plan** | Client | `GET /api/schedule/today` | Fetches the client's complete schedule for the current day, including workouts and meals. |
| **Log Daily Activity** | Client | `PUT /api/activity/log` | Allows the client to log their activity for a specific date (e.g., workout completion, water intake). |
| **View Own Progress** | Client | `GET /api/activity/summary/:clientId` | Retrieves the client's own activity log history. The `:clientId` must match the user's ID from the token. |
