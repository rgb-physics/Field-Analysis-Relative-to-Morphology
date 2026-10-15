# Look up package terminology in MATLAB

From the MeMo repository root, run:

```matlab
farmGlossary
farmGlossary("Experiment")
farmGlossary("Support")
```

The first command displays a catalog. A term displays its data type,
definition, input-field layout and any notes. An entry without a documented
input layout displays exactly `Inputs: {''}`. An unknown term produces an
error, so a misspelled term cannot be mistaken for one without input fields.

All entries come directly from the [written glossary and data dictionary](../GLOSSARY-CAPABILITIES-MOCKUP.md).
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
entry notes. An entry without listed inputs returns a zero-row options table.

An input layout is documentation, not executable validation or a builder.
Some entries show the fields of generated results rather than arguments a
user must supply. Always retain the notes when presenting these layouts.
For example, the axial-alignment entry lists generated result fields.

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
namespaced getters also work when only the API source directory has been
added and the repository root is not on the MATLAB path.

## Other MATLAB presentations

The catalog table and Command Window lookup are the simplest starting points.
MATLAB's `help farmGlossary` shows usage examples. A future small app could put
a search box beside the same catalog and an entry-details panel, reusing
these getters. Such a viewer would be an optional presentation of the same
entries, not another source of definitions.

## Expanding the Data Dictionary

The dictionary currently defines the ten scalar/component sampling diagnostic
fields listed under `diagnostics`. These are generated quantities, so their
input getter returns `Inputs: {''}`. In tables they normally appear with a
field, query or vector-component prefix rather than as bare names.

The [candidate inventory](DATA-DICTIONARY-CANDIDATES.md) and
[CSV with source evidence](DATA-DICTIONARY-CANDIDATES.csv) list other names to
review. This inventory is separate from the published dictionary: an occurrence
in code does not establish a shared meaning or a supported public contract.
