# Look up package terminology in MATLAB

For reading in a browser, start with the [scientific topic pages](reference/README.md)
or [alphabetical index](reference/terms.md). Those generated pages and the MATLAB
lookups use the same editable glossary source. Each entry has one topic-page
location; definitions and MATLAB return fields are unchanged by this presentation.

From the MeMo repository root, run:

```matlab
farmGlossary
farmGlossary("Experiment")
farmGlossary("Source") % Same entry as Data source; created with farmMakeSource.
farmGlossary("Support")
```

The first command displays a catalog. A term displays its data type,
definition and additional notes, followed by Inputs at the bottom. Inputs
can describe supplied data or list named settings. Concepts without a fixed
input list say so explicitly. An unknown term produces an
error, so a misspelled term cannot be mistaken for one without input fields.

All entries come directly from the [written glossary and data dictionary](../GLOSSARY-CAPABILITIES.md).
Edits to that document are available on the next call; no generated copy
needs updating. Keep the document with the package when distributing it.

## Get individual pieces

```matlab
entry = farmGlossary("Experiment");
description = entry.Definition;
dataType = farmGlossary("Experiment", "DataType");
inputs = farmGlossary("Experiment", "Inputs");
options = farmGlossary("Experiment", "InputOptions");
notes = farmGlossary("Experiment", "Notes");
```

`entry` is a scalar struct of strings. `options` is a table with `Name`,
`Type` and `Required` columns. `Required` records the written asterisk;
conditions such as file-source requirements remain in the type text and
entry notes. Descriptive inputs without named settings return a zero-row options table.

An input layout is documentation, not executable validation or a builder.
Inputs describes what users supply. Contents describes stored or generated
fields and appears in the additional notes. For example, axial-alignment
scores are returned contents, while the directions being compared are inputs.

## Search and browse

```matlab
matches = farmGlossary("search", "distance");
matches = farmGlossary("search", "geometry", "SearchIn", ["Term", "Definition"]);
matches = farmGlossary("search", "Count", "SearchIn", "Term", "Section", "DataDictionary");
matches = farmGlossary("search", "geometry", "Section", ["Glossary", "DataDictionary"]);
terms = farmGlossary("list");
catalog = farmGlossary;
dictionary = farmGlossary("catalog", "Section", "DataDictionary");
openvar('catalog');
```

Search is a case-insensitive, literal text search. Without options it searches
all entries and all text columns. It returns a table, including zero rows
when nothing matches. The catalog can be inspected in MATLAB's Variable
Editor without opening a browser.

`SearchIn` accepts one column name or a string array: `Term`, `Section`,
`Group`, `DataType`, `Definition`, `Inputs`, `Notes`. Matching any selected
column includes an entry. `Section` independently restricts entries to
`Glossary`, `DataDictionary`, or both as a string array. Both options default
to `"all"`. `"Data Dictionary"` is also accepted as a section name.

`Section` identifies the main document division. `Group` records the topical
heading, such as `Geometry, supports and references` or `Sampling diagnostics`.
To search topical headings, use `"SearchIn", "Group"`; searching `Section`
searches the main division names instead. Unknown sections/columns raise an
error rather than silently falling back to searching everything.

Direct lookups and all explicit getters also accept the optional section filter:

```matlab
entry = farmGlossary("SelectedCount", "Section", "DataDictionary");
dataType = farmGlossary("SelectedCount", "DataType", "Section", "DataDictionary");
section = farmGlossary("SelectedCount", "Section"); % get the entry's section name
```

Exact spelling takes precedence because the written glossary distinguishes
concepts from workflow variables: `Geometry` and `geometry` have separate
entries. Case-insensitive lookup works when only one entry matches. Otherwise
use the spelling shown in the catalog or search results.
The section filter is applied before resolving exact or case-insensitive matches.

## Explicit getter functions

After running `farmSetup` from the repository root:

```matlab
entry = farmGetGlossaryEntry("Experiment");
dataType = farmGetGlossaryDataType("Experiment");
inputs = farmGetGlossaryInputs("Experiment");
options = farmGetGlossaryInputOptions("Experiment");
matches = farmSearchGlossary("distance");
catalog = farmGlossaryEntries();
inputs = farmGetGlossaryInputs( ...
    "SelectedCount", "Section", "DataDictionary");
```

The root `farmGlossary` command adds that source directory if needed. The
ordinary getter functions work after `farmSetup` adds the API source folders.

## Other MATLAB presentations

The catalog table and Command Window lookup are the simplest starting points.
MATLAB's `help farmGlossary` shows usage examples. A future small app could put
a search box beside the same catalog and an entry-details panel, reusing
these getters. Such a viewer would be an optional presentation of the same
entries, not another source of definitions.

## Expanding the Data Dictionary

The dictionary currently defines the ten scalar/component sampling diagnostic
fields listed under `diagnostics`. Their Inputs describe the sampled values
or geometry records used to calculate them. In tables they normally appear with a
field, query or vector-component prefix rather than as bare names.

The dictionary is not an exhaustive inventory of implementation variables.
An occurrence in code does not establish a shared meaning or a supported public
contract.

## Maintain the topic pages

Edit definitions, representations and input layouts in
[GLOSSARY-CAPABILITIES.md](../GLOSSARY-CAPABILITIES.md).
Keep interpretation notes there as well. The topic pages are generated views,
so do not edit their copies independently. Topic assignments and construct labels
are maintained in [APIs/SharedUtilities/tools/build_reference.py](../APIs/SharedUtilities/tools/build_reference.py).
The generated [entry map](reference/ENTRIES.csv) records each topic, anchor and
source line; it is a documentation entry map, not a public-function inventory.

Python 3.10 or later is needed only to rebuild/check documentation. No Python
packages or tracking installation are required. From the repository root:

```text
python APIs/SharedUtilities/tools/build_reference.py
python APIs/SharedUtilities/tools/build_reference.py --check
```

The check verifies current generated content, local links and anchors, one
topic-page location per entry, and balanced expandable sections/code blocks.
MATLAB continues to read the source directly, so its lookups need no build step.

The full public-function and test inventory is deferred until the remaining
functionality has been evaluated. These pages publish the current entries and
do not claim to document every output of every retained function.
