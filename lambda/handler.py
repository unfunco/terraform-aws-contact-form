# SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
# SPDX-License-Identifier: MIT

import json
import os

ENABLE_LOGGING = os.getenv("ENABLE_LOGGING", "false").lower() == "true"
ENABLE_TRACING = os.getenv("ENABLE_TRACING", "false").lower() == "true"

if ENABLE_LOGGING:
    try:
        from aws_lambda_powertools import Logger
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "ENABLE_LOGGING is true but aws-lambda-powertools is unavailable. "
            "Attach the Powertools Lambda layer or disable logging."
        ) from exc
    logger = Logger()
else:
    logger = None

if ENABLE_TRACING:
    try:
        from aws_lambda_powertools import Tracer
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "ENABLE_TRACING is true but aws-lambda-powertools is unavailable. "
            "Attach the Powertools Lambda layer or disable tracing."
        ) from exc
    tracer = Tracer()
else:
    tracer = None


def _handle_request(_event, _context):
    if logger is not None:
        logger.info("Contact has been made")

    return {
        "statusCode": 501,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"message": "Not Implemented"}),
    }


lambda_handler = _handle_request

if tracer is not None:
    lambda_handler = tracer.capture_lambda_handler(lambda_handler)

if logger is not None:
    lambda_handler = logger.inject_lambda_context(lambda_handler)
