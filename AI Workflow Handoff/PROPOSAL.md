# Starting proposal

Status: discussion draft. Items below are proposals, not confirmed requirements.

## Concept

Provide a portable handoff that users can pass to their own AI. The AI interviews
the user about their analysis goal and data, checks the installed package, and
helps build an inspectable workflow following the package's workflow standards.

The handoff would complement examples for different levels of coding comfort.
It should help users adapt supported analyses while making unsupported requests
and unresolved scientific assumptions explicit.

## Proposed interaction

1. Establish the scientific goal, desired outputs, and success criteria.
2. Establish data sources, channels, axes, calibration, frames, registration,
   and available segmentation.
3. Adapt explanation and code organization to the user's coding comfort.
4. Verify relevant APIs and choose a suitable released example where possible.
5. Build and inspect a small representative analysis before scaling up.
6. Deliver readable code, visible parameters, validation evidence, output
   descriptions, and rerun instructions.

Scientific choices such as thresholds, reference definitions, and inclusion
criteria should remain visible and be discussed with the user.

## Proposed materials

- A short copyable opening prompt.
- References to authoritative package documentation and workflow standards.
- A checklist defining a usable workflow delivery.
- A worked conversation from initial request to inspected workflow.

Avoid maintaining duplicate API or standards documentation inside the handoff.
Consider tying the handoff to a package version and verifying compatibility at
the start of a session.

## Proposed evaluation

Test whether a fresh AI session can help a new user produce a small, runnable,
understandable workflow and recognize requests beyond available capabilities.
Include different coding-comfort levels and both supported and unsupported goals.

At the start of this workshop, the documented released workflows are 1, 2, and
Active Foam E5. Individual API capabilities require separate verification.
