# Build a FARM workflow with your AI

Discussion draft — 2026-10-27.

## For the user

Give your AI this document and access to your FARM package folder. If it cannot
read local folders, provide the package README first and supply other files as
requested.

Start with: “Read this handoff and help me work out a workflow for my data.”

## Instructions for the AI

### Access and interview

1. Establish the package location and whether you or the user will edit files and
   run MATLAB. Accept any package location, including Downloads; do not require
   relocation or Git. Note the version if readily available.
2. Read the package-root README. Read additional documents only as needed using
   the map below.
3. Ask a few questions at a time about the user's scientific goal, available data,
   MATLAB familiarity, and preferred workflow: starter skeleton, interactive
   sections, repeatable batch analysis, or a combination. Refine preferences as
   the task develops.
4. Propose a short natural-language purpose and expected outcome from their
   answers: what they want to learn, the inputs, and the intended outputs.
   Invite correction before proceeding.
5. Ask only for data details needed by the proposed operations: formats, filename
   patterns, channels, axes, spacing and units, frames and timing, masks or labels,
   and registration when combining sources.

### Reading map

Resolve paths relative to the installed package root.

| Need | Read |
|---|---|
| Choose a starting workflow | `docs/README.md`; relevant entries in `Examples and Workflows/examples/README.md` |
| Clarify terminology or structures | Relevant entries in `GLOSSARY-CAPABILITIES.md`, `docs/reference/`, or `docs/READING-STRUCTURES.md` |
| Configure sources, experiments, or queries | Relevant sections of `CONFIGURATION-BUILDERS.md` and `APIs/Workflows/README.md` |
| Adapt an analysis | Relevant sections of `docs/CHANGING-AN-ANALYSIS.md`; chosen setup script or stage guide |
| Compose operations | Relevant API README and function help; implementation if needed |
| Format the generated script | `Examples and Workflows/examples/activeFoamE5Stages/setupActiveFoamE5Stages.m` for visible stage layout; relevant stage functions for API usage |
| Apply package writing style | Naming and Code layout and comments sections of `docs/FARM-CODE-CONVENTIONS-DRAFT.md` (review draft); explicit preferences below govern this handoff |

Skip unrelated APIs, historical handoffs, migration inventories, release planning,
and test data during onboarding. Request specific missing documents or excerpts.

### Scope and choices

- Propose a manageable first workflow using available package capabilities.
  Adapt a released example where suitable; check installed documentation for
  availability. At drafting time, released workflows are 1, 2, and Active Foam E5.
- Identify capability gaps. Distinguish package calls, custom helpers, and
  placeholders. Do not present guessed function names or fields as package APIs.
- Keep calibration, channel meanings, thresholds, references, and selection
  criteria explicit. Ask about choices that affect the analysis; use labeled
  placeholders for unresolved choices in a skeleton.
- Match the requested depth. A starter skeleton is a valid deliverable.
  Signature and structure checks, small-input runs, and display inspection are
  optional; offer them without making them prerequisites. Scientific validation
  of results is outside scope.

### Files and workflow construction

- Before creating files, establish where generated scripts and helper functions
  belong and where data outputs, tables, and figures should be saved. Use prior
  answers if supplied. Do not default to package test-data folders. Leave editable
  paths and defer saving when locations are undecided.
- Separate source data from generated outputs. Use explicit roots and `fullfile`;
  do not depend on the current MATLAB directory or require permanent path changes.
- Use `farmSetup` for package paths. For workflows calling example helpers:

```matlab
packageRoot = 'C:\path\to\FARM'; % actual extracted package folder
addpath(packageRoot);
farmSetup('IncludeExamples', true);
```

- Apply the script style below. Include only required dependencies.
- Separate calculation choices from display choices. State which downstream
  stages need rerunning after an earlier stage changes.
- Deliver the agreed skeleton or script with unresolved parts labeled. Briefly
  state what has been run and which optional checks were performed or deferred.

### Script style and visible API use

- Before writing code, read `setupActiveFoamE5Stages.m` at the path above. Use its
  visible, sequential stage layout as the preferred model. Copy its organization,
  not its dataset paths, scientific settings, optional logging, or incidental code.
- Use `%%` sections for major tasks and a short stage comment immediately before
  each FARM API call explaining the operation. Give each call its own statement;
  keep its inputs, options, and returned variables visible to the reader.
- Expose loading, segmentation, geometry, measurement, sampling, and display as
  distinct steps where applicable. Do not hide several analysis operations behind
  an anonymous loader or generic helper just to shorten the main script.
- When a callback is required by an API, keep it focused and show its implementation
  in a clearly labeled local function. Highlight and explain FARM calls there too.
  If reusing a composed stage function, identify it as such and point to the
  underlying API calls; do not imply it is a single primitive operation.
- Keep new helpers local when requested. Prefer explicit inputs and outputs;
  follow an existing stage's `c` / `c.Results` convention when adapting it, without
  forcing the entire workflow configuration into unrelated lower-level calls.
- Use one statement per line, expanded multiline `if`/`for` blocks, consistent
  indentation, spaces around assignments, and blank lines between operations.
- Use short descriptive names and meaningful indices such as `frameInd` or
  `objInd`. Use named figure and axes handles for plots. Keep comments operational;
  put lengthy discussion in the companion notes.

### Highlight user choices and batch inputs

- Mark suggested edits consistently: `% USER INPUT:` for required values and
  `% OPTIONAL INPUT:` for adjustable choices. Group paths and frame selection in
  an obvious input section near the top of the script, immediately after the short
  purpose/how-to-run comments. Prefer placing all required user inputs there,
  including required scientific settings, before setup or processing code. Keep
  optional analysis choices near the calls that consume them; reference the
  top-level required settings at their point of use rather than duplicating them.
- Mark unresolved values `% REQUIRED:` and illustrative values `% EXAMPLE:`.
  State units and expected formats. Do not present example thresholds as selected
  scientific settings.
- For regularly named batches, prefer a source folder, an `sprintf` filename
  pattern, and acquisition frame values over individually listed filenames or
  repeated file-selection prompts. Ask for one representative filename and the
  numbering convention. Use the installed source builder's `NamePattern` when
  appropriate; otherwise show the same pattern explicitly in the frame loop.

```matlab
%% USER INPUT -- source files and frames
sourceRoot = ''; % USER INPUT: folder containing probability stacks
namePattern = 'frame%03i_probabilities.tif'; % EXAMPLE: replace with your pattern
frames = 1:10; % USER INPUT: acquisition frame values

for frameInd = 1:numel(frames)
    frame = frames(frameInd);
    probabilityFile = fullfile(sourceRoot, sprintf(namePattern, frame));

    % Loading: place the relevant FARM API call and its options here.
end
```

- Offer an explicit manifest for irregular filenames or per-file metadata, or
  when the user prefers one. Distinguish acquisition frame values from stored
  page/time indices. Ask about multi-time-point files before choosing a loader.
- Before delivery, check that editable inputs are marked and each FARM call is
  visibly explained. This is a formatting review, not a required runtime test.

### Continuity

Offer either a copyable chat recap or an optional `WORKFLOW-NOTES.md` beside the
user's scripts. Confirm the note's location before creating it. Record only:

- Natural-language purpose and expected outcome.
- Working preferences and requested deliverable.
- Package location/version and script/output locations.
- Relevant data configuration and scientific choices.
- Current stages, placeholders, and checks performed or deferred.
- Next step and relevant file links.

Update it when meaningful choices change.
