---
type: Runbook
title: Escalate an API incident
description: Escalates an unresolved API incident to the response team.
tags: [oncall, incident, escalation]
status: stable
generated:
  by: human:sre-owner
  at: 2026-08-01T09:30:00Z
verified:
  - by: human:incident-commander
    at: 2026-08-24T03:00:00Z
sources:
  - id: incident-policy
    resource: https://docs.example.com/sre/incident-policy
    title: Incident response policy
---

# Preconditions

The [API latency alert](/alerts/api-latency-p99.md) has remained active for ten
minutes.

# Steps

1. Page the secondary on-call.
2. Open an incident channel.
3. Assign an incident commander.
4. Publish the first status update.

The escalation roles follow the incident response policy.[^incident-policy]

[^incident-policy]: Incident response policy
