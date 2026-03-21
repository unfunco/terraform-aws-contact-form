# SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
# SPDX-License-Identifier: MIT

import base64
import binascii
import boto3
import json
import os
import re
from urllib.parse import parse_qs

ENABLE_LOGGING = os.getenv("ENABLE_LOGGING", "false").lower() == "true"
ENABLE_TRACING = os.getenv("ENABLE_TRACING", "false").lower() == "true"
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+$")
REQUIRED_CONTACT_FIELDS = ("name", "email", "message")

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


class ContactFormRequestError(ValueError):
    def __init__(self, message, *, status_code=400, errors=None):
        super().__init__(message)
        self.errors = errors or []
        self.status_code = status_code


def _json_response(status_code, payload):
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(payload),
    }


def _normalise_headers(event):
    headers = event.get("headers") or {}
    return {str(key).lower(): str(value) for key, value in headers.items()}


def _decode_request_body(event):
    body = event.get("body")

    if body is None:
        raise ContactFormRequestError("Request body is required.")

    if not isinstance(body, str):
        raise ContactFormRequestError("Request body must be a string.")

    if event.get("isBase64Encoded"):
        try:
            return base64.b64decode(body).decode("utf-8")
        except (binascii.Error, UnicodeDecodeError) as exc:
            raise ContactFormRequestError("Request body could not be decoded.") from exc

    return body


def _parse_json_body(body):
    try:
        payload = json.loads(body)
    except json.JSONDecodeError as exc:
        raise ContactFormRequestError("Request body is not valid JSON.") from exc

    if not isinstance(payload, dict):
        raise ContactFormRequestError("JSON request body must be an object.")

    return payload


def _parse_form_body(body):
    payload = {
        key: values[-1]
        for key, values in parse_qs(body, keep_blank_values=True).items()
        if values
    }

    if not payload:
        raise ContactFormRequestError(
            "Form request body must include at least one field."
        )

    return payload


def _parse_request_payload(event):
    if any(field in event for field in REQUIRED_CONTACT_FIELDS) and "body" not in event:
        return {field: event.get(field) for field in REQUIRED_CONTACT_FIELDS}

    body = _decode_request_body(event)
    if not body.strip():
        raise ContactFormRequestError("Request body is required.")

    content_type = (
        _normalise_headers(event)
        .get("content-type", "")
        .split(";", 1)[0]
        .strip()
        .lower()
    )

    if content_type == "application/json":
        return _parse_json_body(body)

    if content_type == "application/x-www-form-urlencoded":
        return _parse_form_body(body)

    if not content_type:
        if body.lstrip().startswith("{"):
            return _parse_json_body(body)

        return _parse_form_body(body)

    raise ContactFormRequestError(
        (
            "Unsupported content type. Use application/json or "
            "application/x-www-form-urlencoded."
        ),
        status_code=415,
    )


def _validate_contact_form(payload):
    errors = []
    cleaned_payload = {}

    for field in REQUIRED_CONTACT_FIELDS:
        value = payload.get(field)

        if not isinstance(value, str) or not value.strip():
            errors.append(f"{field} is required.")
            continue

        cleaned_payload[field] = value.strip()

    email = cleaned_payload.get("email")
    if email and not EMAIL_PATTERN.fullmatch(email):
        errors.append("email must be a valid email address.")

    if errors:
        raise ContactFormRequestError(
            "Invalid contact form submission.",
            errors=errors,
        )

    return cleaned_payload


def _build_email_message(contact_form):
    return {
        "Subject": {
            "Charset": "UTF-8",
            "Data": f"Contact Form Submission from {contact_form['name']}",
        },
        "Body": {
            "Text": {
                "Charset": "UTF-8",
                "Data": "\n".join(
                    [
                        f"Name: {contact_form['name']}",
                        f"Email: {contact_form['email']}",
                        "",
                        "Message:",
                        contact_form["message"],
                    ]
                ),
            }
        },
    }


def _handle_request(event, _context):
    if not isinstance(event, dict):
        return _json_response(
            400,
            {"message": "Event payload must be an object."},
        )

    method = (((event.get("requestContext") or {}).get("http") or {})).get("method")

    if method and method.upper() != "POST":
        return _json_response(
            405,
            {"message": "Only POST requests are supported."},
        )

    try:
        contact_form = _validate_contact_form(_parse_request_payload(event))
    except ContactFormRequestError as exc:
        if logger is not None:
            logger.warning(
                "Rejected invalid contact form submission.",
                extra={"errors": exc.errors or [str(exc)]},
            )

        payload = {"message": str(exc)}
        if exc.errors:
            payload["errors"] = exc.errors

        return _json_response(exc.status_code, payload)

    if logger is not None:
        logger.info("Received contact form submission.")

    if ses is not None and email_recipients:
        try:
            ses.send_email(
                Source=SES_SOURCE_EMAIL,
                Destination={"ToAddresses": email_recipients},
                Message=_build_email_message(contact_form),
                ReplyToAddresses=[contact_form["email"]],
            )
            if logger:
                logger.info("Email notification sent successfully.")
        except Exception:
            if logger:
                logger.exception("Failed to send email notification.")
            raise

    return _json_response(
        200,
        {"message": "Contact form submitted successfully."},
    )


lambda_handler = _handle_request

if tracer is not None:
    lambda_handler = tracer.capture_lambda_handler(lambda_handler)

if logger is not None:
    lambda_handler = logger.inject_lambda_context(lambda_handler)
