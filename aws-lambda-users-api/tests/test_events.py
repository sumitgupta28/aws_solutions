# ─────────────────────────────────────────────────────────────────────────────
# Test events for Lambda console → Test tab
# Copy each block and create a separate named test event for each.
# ─────────────────────────────────────────────────────────────────────────────


# ── 1. POST /users — happy path ───────────────────────────────────────────────
POST_CREATE_USER = {
    "routeKey": "POST /users",
    "body": "{\"name\": \"Alice Smith\", \"email\": \"alice@example.com\", \"phone\": \"+1-555-0101\"}"
}

# ── 2. POST /users — missing email (expect 400) ───────────────────────────────
POST_MISSING_FIELD = {
    "routeKey": "POST /users",
    "body": "{\"name\": \"Bob Jones\"}"
}

# ── 3. POST /users — invalid JSON (expect 400) ───────────────────────────────
POST_BAD_JSON = {
    "routeKey": "POST /users",
    "body": "not valid json"
}

# ── 4. GET /users/{userId} — replace the userId with a real one ───────────────
GET_USER = {
    "routeKey": "GET /users/{userId}",
    "pathParameters": {
        "userId": "REPLACE_WITH_REAL_USER_ID"
    }
}

# ── 5. GET /users/{userId} — user not found (expect 404) ─────────────────────
GET_USER_NOT_FOUND = {
    "routeKey": "GET /users/{userId}",
    "pathParameters": {
        "userId": "does-not-exist"
    }
}

# ── 6. PUT /users/{userId} — update name and phone ───────────────────────────
PUT_UPDATE_USER = {
    "routeKey": "PUT /users/{userId}",
    "pathParameters": {
        "userId": "REPLACE_WITH_REAL_USER_ID"
    },
    "body": "{\"name\": \"Alice Johnson\", \"phone\": \"+1-555-9999\"}"
}

# ── 7. PUT /users/{userId} — no valid fields (expect 400) ────────────────────
PUT_NO_FIELDS = {
    "routeKey": "PUT /users/{userId}",
    "pathParameters": {
        "userId": "REPLACE_WITH_REAL_USER_ID"
    },
    "body": "{\"unknownField\": \"value\"}"
}

# ── 8. DELETE /users/{userId} ─────────────────────────────────────────────────
DELETE_USER = {
    "routeKey": "DELETE /users/{userId}",
    "pathParameters": {
        "userId": "REPLACE_WITH_REAL_USER_ID"
    }
}

# ── 9. DELETE /users/{userId} — already deleted (expect 404) ─────────────────
DELETE_NOT_FOUND = {
    "routeKey": "DELETE /users/{userId}",
    "pathParameters": {
        "userId": "does-not-exist"
    }
}

# ── 10. Unknown route (expect 404) ────────────────────────────────────────────
UNKNOWN_ROUTE = {
    "routeKey": "PATCH /users"
}
