---
type: Alert
title: API latency P99 above two seconds
description: Fires when API P99 latency exceeds two seconds for five minutes.
tags: [api, latency, critical]
status: stable
generated:
  by: human:sre-owner
  at: 2026-08-01T09:00:00Z
verified:
  by: process:monitoring-config-check
  at: 2026-08-24T02:00:00Z
stale_after: 2026-11-01T09:00:00Z
sources:
  - id: alert-config
    resource: https://monitoring.example.com/alerts/api-latency-p99
    title: Production alert configuration
    last_modified: 2026-07-31T18:00:00Z
---

# Trigger

The production alert fires when P99 latency exceeds two seconds for five
minutes.[^alert-config]

# Response

Follow the [incident escalation runbook](/runbooks/escalate-incident.md) if the
alert remains active for ten minutes.

[^alert-config]: Production alert configuration
