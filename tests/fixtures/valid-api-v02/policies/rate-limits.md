---
type: Policy
title: Orders API rate limits
description: Defines request limits for authenticated write endpoints.
tags: [api, limits]
status: stable
generated:
  by: human:api-owner
  at: 2026-08-18T10:00:00Z
sources:
  - id: gateway-policy
    resource: https://gateway.example.com/policies/orders
    title: Deployed gateway policy
    usage_count: 42000
usage_window:
  from: 2026-08-01T00:00:00Z
  to: 2026-08-24T00:00:00Z
---

# Limits

Authenticated clients may create 100 orders per minute.[^gateway-policy]

[^gateway-policy]: Deployed gateway policy
