# Users API — AWS Lambda + DynamoDB

A serverless REST API for managing users, built with Python, AWS Lambda,
API Gateway (HTTP API), and DynamoDB.

---

## Project structure

```
users-api/
├── lambda_function.py     # All Lambda code — handlers + helpers
├── tests/
│   └── test_events.py     # Test event payloads for the Lambda console
└── README.md
```

---

## API routes

| Method | Route | Description | Success |
|--------|-------|-------------|---------|
| POST | /users | Create a new user | 201 |
| GET | /users/{userId} | Fetch a user by ID | 200 |
| PUT | /users/{userId} | Update name, email, or phone | 200 |
| DELETE | /users/{userId} | Delete a user | 200 |

---

## Request / response examples

### POST /users

**Request body** — `name` and `email` are required, `phone` is optional:
```json
{
  "name": "Alice Smith",
  "email": "alice@example.com",
  "phone": "+1-555-0101"
}
```

**201 Created:**
```json
{
  "message": "User created",
  "user": {
    "userId": "e3f2a1b4-7c3d-4e2f-a1b4-9f8e7d6c5b4a",
    "name": "Alice Smith",
    "email": "alice@example.com",
    "phone": "+1-555-0101",
    "createdAt": "2026-06-12T09:14:22+00:00",
    "updatedAt": "2026-06-12T09:14:22+00:00"
  }
}
```

---

### GET /users/{userId}

**200 OK:**
```json
{
  "user": {
    "userId": "e3f2a1b4-7c3d-4e2f-a1b4-9f8e7d6c5b4a",
    "name": "Alice Smith",
    "email": "alice@example.com",
    "phone": "+1-555-0101",
    "createdAt": "2026-06-12T09:14:22+00:00",
    "updatedAt": "2026-06-12T09:14:22+00:00"
  }
}
```

**404 Not Found:**
```json
{ "error": "User not found: e3f2a1b4-xxxx" }
```

---

### PUT /users/{userId}

**Request body** — send only the fields you want to change:
```json
{
  "name": "Alice Johnson",
  "phone": "+1-555-9999"
}
```

**200 OK:**
```json
{
  "message": "User updated",
  "user": { ...updated fields... }
}
```

---

### DELETE /users/{userId}

**200 OK:**
```json
{ "message": "User e3f2a1b4-xxxx deleted" }
```

**404 Not Found:**
```json
{ "error": "User not found: e3f2a1b4-xxxx" }
```

---

## Curl examples

Replace the base URL with your own invoke URL from API Gateway.

```bash
BASE="https://dige3j3pfb.execute-api.us-east-1.amazonaws.com/default"

# Create a user
curl -X POST "$BASE/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Smith", "email": "alice@example.com", "phone": "+1-555-0101"}'

# Fetch a user (paste a real userId)
curl "$BASE/users/e3f2a1b4-7c3d-4e2f-a1b4-9f8e7d6c5b4a"

# Update a user
curl -X PUT "$BASE/users/e3f2a1b4-7c3d-4e2f-a1b4-9f8e7d6c5b4a" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Johnson", "phone": "+1-555-9999"}'

# Delete a user
curl -X DELETE "$BASE/users/e3f2a1b4-7c3d-4e2f-a1b4-9f8e7d6c5b4a"
```

---

## API Gateway routes to create

Make sure all four routes exist in API Gateway → Routes,
each pointing to your Lambda function:

```
POST   /users
GET    /users/{userId}
PUT    /users/{userId}
DELETE /users/{userId}
```

---

## DynamoDB table settings

| Setting | Value |
|---------|-------|
| Table name | users |
| Partition key | userId (String) |
| Capacity mode | Provisioned — 1 RCU / 1 WCU (free tier) |

---

## IAM — Lambda execution role

The Lambda role needs this policy (minimum required permissions):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/users"
    }
  ]
}
```

---

## Error reference

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 201 | User created |
| 400 | Bad request — missing fields, invalid JSON |
| 404 | User or route not found |
| 405 | Method not allowed |
| 500 | DynamoDB error — check CloudWatch logs |
