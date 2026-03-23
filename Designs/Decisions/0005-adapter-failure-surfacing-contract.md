# ADR 0005: Adapter Failure-Surfacing Contract

- Date: 2026-03-23
- Status: Accepted

## Context

Cookle already separates shared mutations from target adapters, but that
boundary alone does not prevent silent failures.

Without a repository-wide contract:

- a form can dismiss after a blocking failure
- an App Intent can return a success dialog after a missing entity
- a destructive action can rely on assertions instead of explicit failure
  semantics
- follow-up work can blur the difference between a failed mutation and a failed
  adapter-only side effect

## Decision

Every adapter-owned mutation or destructive-reset path must classify failures
into one of these phases and surface them consistently.

| Phase | Examples | Contract |
| --- | --- | --- |
| Preflight failure before mutation | Missing model, invalid local dependency wiring, parameter conversion that cannot produce a valid shared call | Block success. Keep the current UI or throw from the App Intent. Do not dismiss, navigate away, or return a success result. |
| Primary domain mutation failure | Validation failure, fetch failure, persistence error, shared service throw | Block success. Surface the error to the current caller. The caller must not present the operation as saved, created, updated, or deleted. |
| Post-commit follow-up failure | Notification refresh, widget reload, review prompt follow-up, other adapter-only work after the shared write committed | Treat as degraded success, not as rollback. Preserve the committed mutation result, but keep the failure observable and repairable when practical. |

## Required Surface Behavior

### UI adapters

- Keep the current screen or destructive confirmation context on blocking
  failures.
- Show explicit error presentation for user-initiated blocking failures.
- Do not dismiss create or edit flows after a blocking failure.

### App Intents

- Throw on blocking failures.
- Do not return `.result(...)` when adapter preconditions or primary mutations
  failed.
- If adapter follow-up work fails after a committed mutation, do not claim the
  mutation was rolled back.

## Observability Requirements

For degraded-success cases, adapters should emit enough context for diagnosis:

- operation name
- surface
- failure phase
- error payload
- follow-up hint or stage when applicable

Assertions may help in debug builds, but they do not satisfy the contract on
their own.

## Consequences

- App code must use explicit success semantics instead of assertions or success
  sentinel dialogs.
- Mutation workflows can be reviewed against a repository-level contract.
- Future adapter refactors can distinguish primary mutation failures from
  adapter-only follow-up issues.
