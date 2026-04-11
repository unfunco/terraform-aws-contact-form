// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

output "contact_form_url" {
  description = "Public URL for the contact form endpoint."
  value       = module.contact_form.endpoint_url
}
