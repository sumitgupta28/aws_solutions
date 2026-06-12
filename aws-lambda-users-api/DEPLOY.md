# Deployment

The function code is `lambda_function.py` + `models.py`. The third-party
dependencies (`pydantic`, `email-validator`) ship as a **Lambda layer**.

Pydantic v2 bundles a compiled `pydantic-core` (Rust). It **must be built for
Amazon Linux**, not macOS, or the function will fail at import with a
`pydantic_core` load error. Build the layer inside the matching Lambda runtime
image so the wheels match.

> Adjust `python:3.12` below to match your function's runtime.

## 1. Build the layer (Docker)

```bash
mkdir -p layer/python
docker run --rm --entrypoint /bin/sh \
  -v "$PWD":/var/task public.ecr.aws/lambda/python:3.12 \
  -c "pip install -r /var/task/requirements.txt -t /var/task/layer/python"
cd layer && zip -r ../pydantic-layer.zip python && cd ..
```

## 2. Publish the layer

```bash
aws lambda publish-layer-version \
  --layer-name users-api-pydantic \
  --zip-file fileb://pydantic-layer.zip \
  --compatible-runtimes python3.12
```

Note the `LayerVersionArn` in the output.

## 3. Attach the layer to the function

```bash
aws lambda update-function-configuration \
  --function-name <your-fn-name> --layers <LayerVersionArn>
```

## 4. Deploy the function code

Zip and deploy `lambda_function.py` + `models.py` as usual (the heavy deps live
in the layer, not in this zip):

```bash
zip function.zip lambda_function.py models.py
aws lambda update-function-code \
  --function-name <your-fn-name> --zip-file fileb://function.zip
```
