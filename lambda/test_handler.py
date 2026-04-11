import json
import unittest

import handler


class HandlerLimitTests(unittest.TestCase):
    def _event(self, payload):
        return {
            "body": json.dumps(payload),
            "headers": {"content-type": "application/json"},
            "requestContext": {"http": {"method": "POST"}},
        }

    def test_accepts_valid_submission(self):
        response = handler.lambda_handler(
            self._event(
                {
                    "name": "Alice Example",
                    "email": "alice@example.com",
                    "message": "Hello there",
                }
            ),
            None,
        )

        self.assertEqual(response["statusCode"], 200)

    def test_rejects_oversized_body(self):
        response = handler.lambda_handler(
            self._event(
                {
                    "name": "Alice Example",
                    "email": "alice@example.com",
                    "message": "a" * (handler.MAX_REQUEST_BODY_SIZE + 1),
                }
            ),
            None,
        )

        self.assertEqual(response["statusCode"], 413)
        self.assertEqual(
            json.loads(response["body"])["message"],
            f"Request body must not exceed {handler.MAX_REQUEST_BODY_SIZE} bytes.",
        )

    def test_rejects_too_many_fields(self):
        payload = {
            "name": "Alice Example",
            "email": "alice@example.com",
            "message": "Hello there",
        }

        for index in range(handler.MAX_FIELD_COUNT - len(payload) + 1):
            payload[f"extra_{index}"] = "x"

        response = handler.lambda_handler(self._event(payload), None)

        self.assertEqual(response["statusCode"], 400)
        self.assertIn(
            f"Request must not include more than {handler.MAX_FIELD_COUNT} fields.",
            json.loads(response["body"])["errors"],
        )

    def test_rejects_field_value_over_limit(self):
        response = handler.lambda_handler(
            self._event(
                {
                    "name": "Alice Example",
                    "email": "alice@example.com",
                    "message": "a" * (handler.MAX_FIELD_LENGTH + 1),
                }
            ),
            None,
        )

        self.assertEqual(response["statusCode"], 400)
        self.assertIn(
            f"message must not exceed {handler.MAX_FIELD_LENGTH} characters.",
            json.loads(response["body"])["errors"],
        )


if __name__ == "__main__":
    unittest.main()
