#!/bin/bash

# Santa Maria Backend Test Script
BASE_URL="http://localhost:8000/api/v1"

echo "--- 1. Health Check ---"
curl -s $BASE_URL/health | jq .

echo -e "\n--- 2. Register Consumer ---"
curl -s -X POST $BASE_URL/auth/register-consumer \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Consumer",
    "phone": "08999999999",
    "pin": "1234"
  }' | jq .

echo -e "\n--- 3. Login Admin ---"
token=$(curl -s -X POST $BASE_URL/auth/login-internal \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "08123456789",
    "password": "password123"
  }' | jq -r '.data.access_token')

echo "Admin Token: ${token:0:10}..."

echo -e "\n--- 4. Admin Dashboard Stats ---"
curl -s -X GET $BASE_URL/admin/dashboard \
  -H "Authorization: Bearer $token" | jq .

echo -e "\n--- 5. Get Available Drivers ---"
curl -s -X GET "$BASE_URL/admin/drivers/available?scheduled_at=2026-04-12%2010:00:00" \
  -H "Authorization: Bearer $token" | jq .
