# SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
# SPDX-License-Identifier: MIT

import boto3
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

email_recipients = []
ses = None

EMAIL_RECIPIENTS_SSM_PARAMETER_ARN = os.getenv("EMAIL_RECIPIENTS_SSM_PARAMETER_ARN")
SES_SOURCE_EMAIL = os.getenv("SES_SOURCE_EMAIL")

if EMAIL_RECIPIENTS_SSM_PARAMETER_ARN:
    try:
        from aws_lambda_powertools.utilities import parameters
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "EMAIL_RECIPIENTS_SSM_PARAMETER_ARN is set but aws-lambda-powertools is unavailable. "
            "Attach the Powertools Lambda layer or unset EMAIL_RECIPIENTS_SSM_PARAMETER_ARN."
        ) from exc

    if not SES_SOURCE_EMAIL:
        raise RuntimeError(
            "SES_SOURCE_EMAIL must be set when email notifications are enabled."
        )

    email_recipients = [
        recipient.strip()
        for recipient in parameters.get_parameter(
            EMAIL_RECIPIENTS_SSM_PARAMETER_ARN, decrypt=True
        ).split(",")
        if recipient.strip()
    ]

    if not email_recipients:
        raise RuntimeError(
            "EMAIL_RECIPIENTS_SSM_PARAMETER_ARN resolved to an empty recipient list."
        )

    ses = boto3.client("ses")


def _handle_request(_event, _context):
    if logger is not None:
        logger.info("Contact has been made")

    if ses is not None and email_recipients:
        try:
            ses.send_email(
                Source=SES_SOURCE_EMAIL,
                Destination={"ToAddresses": email_recipients},
                Message={
                    "Subject": {"Data": "Contact Form Submission"},
                    "Body": {"Text": {"Data": "A contact form has been submitted."}},
                },
            )
            if logger:
                logger.info("Email notification sent successfully.")
        except Exception:
            if logger:
                logger.exception("Failed to send email notification.")
            raise

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
