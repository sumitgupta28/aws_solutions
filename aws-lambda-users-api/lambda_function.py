import json
import logging
import boto3
import uuid
from datetime import datetime, timezone

# Logger — integrates with CloudWatch. Level is configurable via the
# LOG_LEVEL env var (defaults to INFO) without a code change.
import os

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())

# DynamoDB resource — reused across warm invocations
dynamodb = boto3.resource("dynamodb")
userTable = dynamodb.Table("users")


# ── Entry point ───────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    """
    Main Lambda handler. Routes to the correct function based on
    the API Gateway routeKey (e.g. "POST /users", "GET /users/{userId}").
    """
    request_id = getattr(context, "aws_request_id", "unknown")
    route_key = event.get("routeKey", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path   = event.get("requestContext", {}).get("http", {}).get("path", "")
    logger.info("Request received: requestId=%s routeKey=%s method=%s path=%s",
                request_id, route_key, method, path)

    routes = {
        "POST /users":            handle_create,
        "GET /users/{userId}":    handle_get,
        "PUT /users/{userId}":    handle_update,
        "DELETE /users/{userId}": handle_delete,
    }

    handler = routes.get(route_key)
    if not handler:
        logger.warning("No route matched: routeKey=%s", route_key)
        return _response(404, {"error": f"Route not found: {route_key}"})

    response = handler(event)
    logger.info("Request completed: routeKey=%s status=%s",
                route_key, response.get("statusCode"))
    return response


# ── POST /users ───────────────────────────────────────────────────────────────

def handle_create(event):
    """Create a new user. Requires name and email in the request body."""
    body = _parse_body(event)
    if isinstance(body, dict) and "error" in body:
        logger.warning("Create rejected: invalid body")
        return _response(400, body)

    missing = [f for f in ["name", "email"] if not body.get(f)]
    if missing:
        logger.warning("Create rejected: missing fields=%s", missing)
        return _response(400, {"error": f"Missing required fields: {', '.join(missing)}"})

    user = {
        "userId":    str(uuid.uuid4()),
        "name":      body["name"].strip(),
        "email":     body["email"].strip().lower(),
        "phone":     body.get("phone", "").strip(),
        "createdAt": _now(),
        "updatedAt": _now(),
    }

    try:
        userTable.put_item(Item=user)
    except Exception:
        logger.exception("DynamoDB put_item failed")
        return _response(500, {"error": "Failed to save user"})

    logger.info("User created: userId=%s", user["userId"])
    return _response(201, {"message": "User created", "user": user})


# ── GET /users/{userId} ───────────────────────────────────────────────────────

def handle_get(event):
    """Fetch a single user by userId."""
    user_id = _path_param(event, "userId")
    if not user_id:
        logger.warning("Get rejected: missing userId in path")
        return _response(400, {"error": "Missing userId in path"})

    try:
        result = userTable.get_item(Key={"userId": user_id})
    except Exception:
        logger.exception("DynamoDB get_item failed: userId=%s", user_id)
        return _response(500, {"error": "Failed to fetch user"})

    user = result.get("Item")
    if not user:
        logger.info("User not found: userId=%s", user_id)
        return _response(404, {"error": f"User not found: {user_id}"})

    logger.info("User fetched: userId=%s", user_id)
    return _response(200, {"user": user})


# ── PUT /users/{userId} ───────────────────────────────────────────────────────

def handle_update(event):
    """Update an existing user's name, email, or phone."""
    user_id = _path_param(event, "userId")
    if not user_id:
        logger.warning("Update rejected: missing userId in path")
        return _response(400, {"error": "Missing userId in path"})

    body = _parse_body(event)
    if isinstance(body, dict) and "error" in body:
        logger.warning("Update rejected: invalid body, userId=%s", user_id)
        return _response(400, body)

    allowed = {"name", "email", "phone"}
    updates = {k: v for k, v in body.items() if k in allowed and v}
    if not updates:
        logger.warning("Update rejected: no valid fields, userId=%s", user_id)
        return _response(400, {"error": f"Provide at least one field to update: {', '.join(allowed)}"})

    # Build DynamoDB update expression dynamically
    expr_parts = []
    expr_values = {":updatedAt": _now()}
    expr_names  = {}

    for key, value in updates.items():
        placeholder = f":val_{key}"
        name_token  = f"#attr_{key}"
        expr_parts.append(f"{name_token} = {placeholder}")
        expr_values[placeholder] = value.strip().lower() if key == "email" else value.strip()
        expr_names[name_token]   = key

    expr_parts.append("#attr_updatedAt = :updatedAt")
    expr_names["#attr_updatedAt"] = "updatedAt"

    update_expr = "SET " + ", ".join(expr_parts)

    try:
        result = userTable.update_item(
            Key={"userId": user_id},
            UpdateExpression=update_expr,
            ExpressionAttributeValues=expr_values,
            ExpressionAttributeNames=expr_names,
            ConditionExpression="attribute_exists(userId)",  # 404 if not found
            ReturnValues="ALL_NEW",
        )
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        logger.info("Update target not found: userId=%s", user_id)
        return _response(404, {"error": f"User not found: {user_id}"})
    except Exception:
        logger.exception("DynamoDB update_item failed: userId=%s", user_id)
        return _response(500, {"error": "Failed to update user"})

    logger.info("User updated: userId=%s fields=%s", user_id, sorted(updates))
    return _response(200, {"message": "User updated", "user": result["Attributes"]})


# ── DELETE /users/{userId} ────────────────────────────────────────────────────

def handle_delete(event):
    """Delete a user by userId. Returns 404 if the user doesn't exist."""
    user_id = _path_param(event, "userId")
    if not user_id:
        logger.warning("Delete rejected: missing userId in path")
        return _response(400, {"error": "Missing userId in path"})

    try:
        userTable.delete_item(
            Key={"userId": user_id},
            ConditionExpression="attribute_exists(userId)",  # 404 if not found
        )
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        logger.info("Delete target not found: userId=%s", user_id)
        return _response(404, {"error": f"User not found: {user_id}"})
    except Exception:
        logger.exception("DynamoDB delete_item failed: userId=%s", user_id)
        return _response(500, {"error": "Failed to delete user"})

    logger.info("User deleted: userId=%s", user_id)
    return _response(200, {"message": f"User {user_id} deleted"})


# ── Helpers ───────────────────────────────────────────────────────────────────

def _parse_body(event):
    """Parse the JSON request body. Returns a dict or an error dict."""
    try:
        return json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return {"error": "Invalid JSON body"}


def _path_param(event, key):
    """Safely extract a path parameter from the event."""
    params = event.get("pathParameters") or {}
    return params.get(key, "").strip()


def _now():
    """Return current UTC time as an ISO 8601 string."""
    return datetime.now(timezone.utc).isoformat()


def _response(status_code, body):
    """Build a standard API Gateway response."""
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }
