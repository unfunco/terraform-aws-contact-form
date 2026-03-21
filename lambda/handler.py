import json
import os

POWERTOOLS_SERVICE_NAME = os.getenv("POWERTOOLS_SERVICE_NAME")

ENABLE_LOGGING = os.getenv("ENABLE_LOGGING", "false").lower() == "true"
ENABLE_TRACING = os.getenv("ENABLE_TRACING", "false").lower() == "true"

if ENABLE_LOGGING and POWERTOOLS_SERVICE_NAME:
    try:
        from aws_lambda_powertools import Logger
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "POWERTOOLS_SERVICE_NAME is set and ENABLE_LOGGING is true, "
            "but aws-lambda-powertools is unavailable. "
            "Attach the Powertools Lambda layer or disable logging."
        ) from exc
    logger = Logger(service=POWERTOOLS_SERVICE_NAME)
else:
    logger = None

if ENABLE_TRACING and POWERTOOLS_SERVICE_NAME:
    try:
        from aws_lambda_powertools import Tracer
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "POWERTOOLS_SERVICE_NAME is set and ENABLE_TRACING is true, "
            "but aws-lambda-powertools is unavailable. "
            "Attach the Powertools Lambda layer or disable tracing."
        ) from exc
    tracer = Tracer(service=POWERTOOLS_SERVICE_NAME)
else:
    tracer = None


def _handle_request(event, _context):
    if ENABLE_LOGGING and logger is not None:
        logger.info("Contact form request", extra={"event": event})

    return {
        "statusCode": 501,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"message": "Not Implemented"}),
    }


lambda_handler = _handle_request

if ENABLE_TRACING and tracer is not None:
    lambda_handler = tracer.capture_lambda_handler(lambda_handler)

if ENABLE_LOGGING and logger is not None:
    lambda_handler = logger.inject_lambda_context(lambda_handler)
