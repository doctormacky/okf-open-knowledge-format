---
type: API Endpoint
title: Create order
description: Creates a new customer order with idempotency protection.
resource: https://api.example.com/v1/orders
tags: [orders, write, idempotent]
status: stable
generated:
  by: process:openapi-import
  at: 2026-08-20T06:00:00Z
verified: { by: human:api-owner, at: 2026-08-23T11:00:00Z }
sources:
  - id: openapi
    resource: /references/orders-openapi.md
    title: Orders OpenAPI contract
---

# Request

Clients send `POST /v1/orders` with an `Idempotency-Key` header.[^openapi]
The endpoint follows the [rate-limit policy](/policies/rate-limits.md).

[^openapi]: Orders OpenAPI contract
