# Decision log

## Confirmed

| ID | Date | Decision | Basis |
|---|---|---|---|
| D001 | 2026-10-27 | Use a dedicated root-level folder to workshop the AI workflow handoff proposal step by step. | User request in the proposal discussion. |
| D002 | 2026-10-27 | Teach the AI to interview users and construct their natural-language purpose and expected outcome rather than prescribe that purpose in the handoff. | User correction before the first draft. |
| D003 | 2026-10-27 | Support arbitrary package locations, including downloaded folders, with lightweight access setup. | User correction before the first draft. |
| D004 | 2026-10-27 | Read relevant documentation progressively; avoid unrelated initial reading. | User correction before the first draft. |
| D005 | 2026-10-27 | Include interview, feasibility, and workflow construction; allow a base skeleton and make validation or checks optional. | User correction before the first draft. |
| D006 | 2026-10-27 | Ask where generated functions and data should go; distinguish package functionality from custom code and checks. | User correction before the first draft. |
| D007 | 2026-10-27 | Keep scientific choices explicit and calculation separate from presentation. Treat the handoff as a sandbox aid, with scientific result validation outside scope. | User correction before the first draft. |

## Additional confirmed style decisions

| ID | Date | Decision | Basis |
|---|---|---|---|
| D008 | 2026-10-27 | Prefer the visible stage layout of setupActiveFoamE5Stages.m and highlight FARM API calls, including calls inside necessary local helpers. | User review of the onboarding simulation. |
| D009 | 2026-10-27 | Clearly mark suggested user inputs and prefer sprintf filename patterns for regular batches; retain manifests for irregular inputs. | User review of the onboarding simulation. |
| D010 | 2026-10-27 | Include explicit expanded MATLAB formatting preferences and reference the package code-conventions document. | User request to edit the handoff after the script comparison. |

## Open review items

- Review the first draft against the scope corrections above.
- Proposal: probe preferred working style early with the actual user, then refine it.
- Proposal: offer an optional WORKFLOW-NOTES.md beside user scripts, with a chat recap as an alternative.
- Later steps: see [Workshop steps](WORKSHOP-STEPS.md).

The starting proposal and suggested workshop sequence are working drafts.
Folder creation does not approve their individual design choices.

## Recording future decisions

Add a dated entry with the agreed decision and its basis. When a decision is
replaced, retain the earlier entry and identify the replacement so the reasoning
remains traceable.
