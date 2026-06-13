# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A serverless Users CRUD REST API: AWS Lambda (Python) behind API Gateway (HTTP API), backed by a DynamoDB table named `users` (partition key `userId`, String). There is no build step and no web framework — the Lambda is hand-routed.

## Commands

```bash
# Syntax-check the handler (there is no pytest suite)
python3 -m py_compile lambda_function.py
```

`tests/test_events.py` is **not** an automated test suite — it is a collection of JSON event payloads to paste into the Lambda console's Test tab. Each `*_USER` / `*_ROUTE` constant is one named test event. To exercise logic locally, import `lambda_handler` and pass it one of these dicts (DynamoDB calls require AWS credentials / a real `users` table).

## Architecture

- **`lambda_function.py`** — everything: the `lambda_handler` entry point plus all route handlers and helpers. Routing is a dict mapping API Gateway `routeKey` strings (e.g. `"POST /users"`, `"GET /users/{userId}"`) to `handle_*` functions. An unmatched `routeKey` returns 404. Adding an endpoint = add a route to this dict + a handler.
- **Validation is hand-rolled** in the handlers: `handle_create` checks for required `name`/`email`; `handle_update` filters the body to the `{name, email, phone}` allow-list and rejects an empty update. Strings are whitespace-stripped and emails lowercased inline.

### Conventions to preserve

- **All responses go through `_response(status, body)`** — it sets `Content-Type` and JSON-encodes with `default=str`. Never build a raw dict response.
- **404-on-missing for update/delete** is done with DynamoDB `ConditionExpression="attribute_exists(userId)"` and catching `ConditionalCheckFailedException` — not a separate read. Keep this pattern; don't add a get-before-write.
- The DynamoDB resource and `userTable` are module-level so they're reused across warm invocations. Log level comes from the `LOG_LEVEL` env var.

## Dependencies & deployment

The function has **no third-party dependencies** — validation is plain Python, so there is no Lambda layer to build. The deployment zip contains only `lambda_function.py`. Terraform in `terraform-infra/` packages and deploys it (see `terraform-infra/README.md`).
