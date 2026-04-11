# SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
# SPDX-License-Identifier: MIT

import base64
import binascii
import html
import json
import os
import re
from string import Template
from urllib.parse import parse_qs


def _env_int(name, default, *, minimum=1):
    raw_value = os.getenv(name)

    if raw_value in (None, ""):
        return default

    try:
        value = int(raw_value)
    except ValueError as exc:
        raise RuntimeError(f"{name} must be an integer.") from exc

    if value < minimum:
        raise RuntimeError(f"{name} must be greater than or equal to {minimum}.")

    return value


ENABLE_LOGGING = os.getenv("ENABLE_LOGGING", "false").lower() == "true"
ENABLE_TRACING = os.getenv("ENABLE_TRACING", "false").lower() == "true"
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+$")
CONTACT_FORM_FIELDS = json.loads(
    os.getenv(
        "CONTACT_FORM_FIELDS",
        '[{"name":"name","type":"text"},{"name":"email","type":"email"},{"name":"message","type":"textarea"}]',
    )
)
FIELD_NAMES = tuple(field["name"] for field in CONTACT_FORM_FIELDS)
MAX_FIELD_COUNT = _env_int(
    "MAX_FIELD_COUNT",
    max(len(FIELD_NAMES), 1),
    minimum=max(len(FIELD_NAMES), 1),
)
MAX_FIELD_LENGTH = _env_int("MAX_FIELD_LENGTH", 2000)
MAX_REQUEST_BODY_SIZE = _env_int("MAX_REQUEST_BODY_SIZE", 16384, minimum=1024)
EMAIL_TEMPLATE = os.getenv("EMAIL_TEMPLATE")

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

    try:
        import boto3
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "EMAIL_RECIPIENTS_SSM_PARAMETER_ARN is set but boto3 is unavailable. "
            "Ensure the Lambda runtime includes boto3 or bundle it explicitly."
        ) from exc

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
            decoded = base64.b64decode(body, validate=True)
        except (binascii.Error, UnicodeDecodeError) as exc:
            raise ContactFormRequestError("Request body could not be decoded.") from exc

        if len(decoded) > MAX_REQUEST_BODY_SIZE:
            raise ContactFormRequestError(
                f"Request body must not exceed {MAX_REQUEST_BODY_SIZE} bytes.",
                status_code=413,
            )

        try:
            return decoded.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise ContactFormRequestError("Request body could not be decoded.") from exc

    if len(body.encode("utf-8")) > MAX_REQUEST_BODY_SIZE:
        raise ContactFormRequestError(
            f"Request body must not exceed {MAX_REQUEST_BODY_SIZE} bytes.",
            status_code=413,
        )

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
    if any(field in event for field in FIELD_NAMES) and "body" not in event:
        return {field: event.get(field) for field in FIELD_NAMES}

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

    if len(payload) > MAX_FIELD_COUNT:
        errors.append(f"Request must not include more than {MAX_FIELD_COUNT} fields.")

    for field_name, value in payload.items():
        if not isinstance(field_name, str) or not field_name:
            errors.append("Field names must be non-empty strings.")
            continue

        if not isinstance(value, str):
            errors.append(f"{field_name} must be a string.")
            continue

        if len(value) > MAX_FIELD_LENGTH:
            errors.append(
                f"{field_name} must not exceed {MAX_FIELD_LENGTH} characters."
            )

    for field in CONTACT_FORM_FIELDS:
        field_name = field["name"]
        field_type = field["type"]
        value = payload.get(field_name)

        if value is None:
            errors.append(f"{field_name} is required.")
            continue

        if not isinstance(value, str):
            continue

        if not value.strip():
            errors.append(f"{field_name} is required.")
            continue

        cleaned_value = value.strip()
        cleaned_payload[field_name] = cleaned_value

        if field_type == "email" and (
            len(cleaned_value) > 320 or not EMAIL_PATTERN.fullmatch(cleaned_value)
        ):
            errors.append(f"{field_name} must be a valid email address.")

    if errors:
        raise ContactFormRequestError(
            "Invalid contact form submission.",
            errors=errors,
        )

    return cleaned_payload


def _build_html_fields(contact_form):
    html_parts = []

    for field in CONTACT_FORM_FIELDS:
        label = field["name"].replace("_", " ").title()
        value = html.escape(contact_form.get(field["name"], ""))

        if field["type"] == "email":
            html_parts.append(
                f'<p><strong>{label}:</strong> <a href="mailto:{value}">{value}</a></p>'
            )
        elif field["type"] == "textarea":
            html_parts.extend(
                [
                    f"<p><strong>{label}:</strong></p>",
                    f"<pre>{value}</pre>",
                ]
            )
        else:
            html_parts.append(f"<p><strong>{label}:</strong> {value}</p>")

    return "\n  ".join(html_parts)


def _build_email_message(contact_form):
    subject_value = contact_form.get("name")
    if not subject_value:
        text_fields = [f["name"] for f in CONTACT_FORM_FIELDS if f["type"] == "text"]
        subject_value = contact_form.get(text_fields[0]) if text_fields else None

    subject = (
        f"Contact Form Submission from {subject_value}"
        if subject_value
        else "Contact Form Submission"
    )

    text_parts = []
    for field in CONTACT_FORM_FIELDS:
        label = field["name"].replace("_", " ").title()
        value = contact_form.get(field["name"], "")
        if field["type"] == "textarea":
            text_parts.extend(["", f"{label}:", value])
        else:
            text_parts.append(f"{label}: {value}")

    message = {
        "Subject": {"Charset": "UTF-8", "Data": subject},
        "Body": {
            "Text": {"Charset": "UTF-8", "Data": "\n".join(text_parts)},
        },
    }

    if EMAIL_TEMPLATE:
        escaped = {k: html.escape(v) for k, v in contact_form.items()}
        escaped["fields_html"] = _build_html_fields(contact_form)
        html_body = Template(EMAIL_TEMPLATE).safe_substitute(escaped)
        message["Body"]["Html"] = {"Charset": "UTF-8", "Data": html_body}

    return message


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
            reply_to = [
                contact_form[f["name"]]
                for f in CONTACT_FORM_FIELDS
                if f["type"] == "email" and f["name"] in contact_form
            ]
            ses.send_email(
                Source=SES_SOURCE_EMAIL,
                Destination={"ToAddresses": email_recipients},
                Message=_build_email_message(contact_form),
                ReplyToAddresses=reply_to,
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
