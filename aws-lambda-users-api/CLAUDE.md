# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A serverless Users CRUD REST API: AWS Lambda (Python) behind API Gateway (HTTP API), backed by a DynamoDB table named `users` (partition key `userId`, String). There is no build step and no web framework — the Lambda is hand-routed.

## Commands

```bash
# Syntax-check the handler (there is no pytest suite)
python3 -m py_compile lambda_function.py models.py
```

`tests/test_events.py` is **not** an automated test suite — it is a collection of JSON event payloads to paste into the Lambda console's Test tab. Each `*_USER` / `*_ROUTE` constant is one named test event. To exercise logic locally, import `lambda_handler` and pass it one of these dicts (DynamoDB calls require AWS credentials / a real `users` table).

## Architecture

- **`lambda_function.py`** — everything: the `lambda_handler` entry point plus all route handlers and helpers. Routing is a dict mapping API Gateway `routeKey` strings (e.g. `"POST /users"`, `"GET /users/{userId}"`) to `handle_*` functions. An unmatched `routeKey` returns 404. Adding an endpoint = add a route to this dict + a handler.
- **`models.py`** — Pydantic v2 request models. `CreateUserRequest` (name + email required, phone optional) and `UpdateUserRequest` (subclass, all fields optional). Validation conventions baked into the models: `extra="forbid"` rejects unknown body keys as a 400, strings are whitespace-stripped, emails are lowercased, phone matches a loose regex. The PUT "at least one field" rule is enforced in the handler via `model_dump(exclude_unset=True)`, not in the model.

### Conventions to preserve

- **All responses go through `_response(status, body)`** — it sets `Content-Type` and JSON-encodes with `default=str`. Never build a raw dict response.
- **Pydantic `ValidationError` → `_validation_error_response`**, which flattens errors into `{"error": "Validation failed", "details": [{field, message}]}` with a 400.
- **404-on-missing for update/delete** is done with DynamoDB `ConditionExpression="attribute_exists(userId)"` and catching `ConditionalCheckFailedException` — not a separate read. Keep this pattern; don't add a get-before-write.
- The DynamoDB resource and `userTable` are module-level so they're reused across warm invocations. Log level comes from the `LOG_LEVEL` env var.

## Dependencies & deployment

`pydantic` and `email-validator` are **not** packaged in the function zip — they ship as a Lambda layer. Because Pydantic v2 bundles compiled `pydantic-core` (Rust), the layer **must be built for Amazon Linux** (via the `public.ecr.aws/lambda/python:3.x` Docker image), not on macOS, or the function fails at import. The function zip contains only `lambda_function.py` + `models.py`. See `DEPLOY.md` for the exact build/publish/attach steps; keep `requirements.txt` in sync with what the layer provides.
