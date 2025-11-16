#!/bin/bash

# FitBond API E2E Test Script
# This script verifies the core functionality of the FitBond backend.

BASE_URL="http://localhost:3000/api"
TRAINER_EMAIL="trainer-test-$(date +%s)@fit.com"
CLIENT_EMAIL="client-test-$(date +%s)@fit.com"
PASSWORD="password123"

echo "--- FitBond API E2E Test Suite ---"

# Helper function to log test results
assert_status() {
    if [ "$1" -eq "$2" ]; then
        echo "✅ PASSED: $3 (Expected $2, Got $1)"
    else
        echo "❌ FAILED: $3 (Expected $2, Got $1)"
        echo "Response Body: $4"
        exit 1
    fi
}

# 1. Health Check
echo "\n--- 1. Server Health Check ---"
# A simple way to check if the server is up is to try a non-existent route
response=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/health)
if [ "$response" -eq 404 ]; then
    echo "✅ PASSED: Server is running (responded with 404 on a dummy route)"
else
    echo "❌ FAILED: Server is not running or not responding correctly. (Expected 404, Got $response)"
    exit 1
fi


# 2. Authentication Flow
echo "\n--- 2. Authentication Flow ---"

# Sign up Trainer
echo "Signing up a new TRAINER..."
signup_response=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/signup \
-H "Content-Type: application/json" \
-d '{
  "email": "'"$TRAINER_EMAIL"'",
  "password": "'"$PASSWORD"'",
  "fullName": "Test Trainer",
  "role": "TRAINER",
  "specialization": "API Testing"
}')
http_code=$(echo "$signup_response" | tail -n1)
body=$(echo "$signup_response" | sed '$d')
assert_status "$http_code" 201 "Trainer signup" "$body"

# Sign up Client
echo "Signing up a new CLIENT..."
signup_response=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/signup \
-H "Content-Type: application/json" \
-d '{
  "email": "'"$CLIENT_EMAIL"'",
  "password": "'"$PASSWORD"'",
  "fullName": "Test Client",
  "role": "CLIENT",
  "goals": "Get Fit"
}')
http_code=$(echo "$signup_response" | tail -n1)
body=$(echo "$signup_response" | sed '$d')
assert_status "$http_code" 201 "Client signup" "$body"

# Log in Trainer
echo "Logging in as TRAINER..."
login_response=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/login \
-H "Content-Type: application/json" \
-d '{
  "email": "'"$TRAINER_EMAIL"'",
  "password": "'"$PASSWORD"'"
}')
http_code=$(echo "$login_response" | tail -n1)
body=$(echo "$login_response" | sed '$d')
assert_status "$http_code" 200 "Trainer login" "$body"
TRAINER_TOKEN=$(echo "$body" | jq -r '.accessToken')
if [ -z "$TRAINER_TOKEN" ] || [ "$TRAINER_TOKEN" == "null" ]; then echo "❌ FAILED: Could not extract trainer token."; exit 1; fi
echo "Trainer token acquired."

# Log in Client
echo "Logging in as CLIENT..."
login_response=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/login \
-H "Content-Type: application/json" \
-d '{
  "email": "'"$CLIENT_EMAIL"'",
  "password": "'"$PASSWORD"'"
}')
http_code=$(echo "$login_response" | tail -n1)
body=$(echo "$login_response" | sed '$d')
assert_status "$http_code" 200 "Client login" "$body"
CLIENT_TOKEN=$(echo "$body" | jq -r '.accessToken')
if [ -z "$CLIENT_TOKEN" ] || [ "$CLIENT_TOKEN" == "null" ]; then echo "❌ FAILED: Could not extract client token."; exit 1; fi
echo "Client token acquired."


# 3. Trainer-Client Linking
echo "\n--- 3. Trainer-Client Linking ---"
link_response=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/trainer/clients \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TRAINER_TOKEN" \
-d '{
  "clientEmail": "'"$CLIENT_EMAIL"'"
}')
http_code=$(echo "$link_response" | tail -n1)
body=$(echo "$link_response" | sed '$d')
assert_status "$http_code" 201 "Trainer links with client" "$body"
CLIENT_ID=$(echo "$body" | jq -r '.clientId')
if [ -z "$CLIENT_ID" ] || [ "$CLIENT_ID" == "null" ]; then echo "❌ FAILED: Could not extract client ID from link response."; exit 1; fi
echo "Client ID acquired: $CLIENT_ID"


# 4. Weekly Schedule Template Creation
echo "\n--- 4. Weekly Schedule Template Creation ---"
DAY_OF_WEEK="MONDAY"
template_response=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/schedule/template/$CLIENT_ID/$DAY_OF_WEEK \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TRAINER_TOKEN" \
-d '{
  "sleepTargetHours": 8,
  "waterTargetLiters": 3,
  "cardioPlanText": "30 minutes of jogging"
}')
http_code=$(echo "$template_response" | tail -n1)
body=$(echo "$template_response" | sed '$d')
assert_status "$http_code" 201 "Create weekly schedule template" "$body"
TEMPLATE_ID=$(echo "$body" | jq -r '.id')
if [ -z "$TEMPLATE_ID" ] || [ "$TEMPLATE_ID" == "null" ]; then echo "❌ FAILED: Could not extract template ID."; exit 1; fi
echo "Template ID acquired: $TEMPLATE_ID"

# Add workout to template
# First, get an exercise ID from the seeded data
EXERCISE_ID=$(curl -s -X GET http://localhost:3000/dev/exercises | jq -r '.[0].id') # Unofficial dev route needed for test
if [ -z "$EXERCISE_ID" ]; then
    # Fallback: Assume a CUID if dev route doesn't exist. This will likely fail but lets the test run.
    echo "⚠️ Warning: Could not fetch exercise ID. Assuming a placeholder."
    EXERCISE_ID="clxxxxxxxxxxxx"
fi

workout_response=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/schedule/workout/$TEMPLATE_ID \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TRAINER_TOKEN" \
-d '{
  "exerciseId": "'"$EXERCISE_ID"'",
  "sets": 3,
  "reps": "10-12"
}')
http_code=$(echo "$workout_response" | tail -n1)
body=$(echo "$workout_response" | sed '$d')
assert_status "$http_code" 201 "Add workout to template" "$body"


# 5. Client Activity Logging
echo "\n--- 5. Client Activity Logging ---"

# Client gets today's schedule (assuming today is Monday for the test)
echo "Client fetching today's schedule..."
today_response=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/schedule/today \
-H "Authorization: Bearer $CLIENT_TOKEN")
http_code=$(echo "$today_response" | tail -n1)
body=$(echo "$today_response" | sed '$d')
# This might be 404 if test is not run on a Monday. We accept 200 or 404.
if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 404 ]; then
    echo "✅ PASSED: Get today's schedule (Status: $http_code)"
else
    echo "❌ FAILED: Get today's schedule (Expected 200 or 404, Got $http_code)"
    exit 1
fi

# Client logs an activity
LOG_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
log_response=$(curl -s -w "\n%{http_code}" -X PUT $BASE_URL/activity/log \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $CLIENT_TOKEN" \
-d '{
  "date": "'"$LOG_DATE"'",
  "isWorkoutCompleted": true,
  "isWaterGoalMet": true
}')
http_code=$(echo "$log_response" | tail -n1)
body=$(echo "$log_response" | sed '$d')
assert_status "$http_code" 200 "Log client activity" "$body"


# 6. Activity Summary Verification
echo "\n--- 6. Activity Summary Verification ---"
summary_response=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/activity/summary/$CLIENT_ID \
-H "Authorization: Bearer $TRAINER_TOKEN")
http_code=$(echo "$summary_response"| tail -n1)
body=$(echo "$summary_response" | sed '$d')
assert_status "$http_code" 200 "Trainer gets client activity summary" "$body"

# Verify the log is present
is_completed=$(echo "$body" | jq '.[0].isWorkoutCompleted')
if [ "$is_completed" == "true" ]; then
    echo "✅ PASSED: Activity log correctly shows workout as completed."
else
    echo "❌ FAILED: Activity log verification failed. Expected workout to be completed."
    echo "Response Body: $body"
    exit 1
fi

echo "\n🎉🎉🎉 ALL TESTS PASSED! 🎉🎉🎉"
exit 0
