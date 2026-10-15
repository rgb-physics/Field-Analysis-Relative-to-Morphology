# VisualizationTools

The broader visualization API is still awaiting design. The retained helpers
are farmFigSaves, farmManVlnPlot and farmPlotVlns. Their plotting and numerical
behavior is unchanged by the naming migration.

Run farmSetup from the repository root. Historical experiment scripts and
redundant SharedUtilities plotting aliases are preserved at their original
relative locations in the sibling MeMo-Archive. They are outside the release
path; the old aliases are no longer supported entry points.

These helpers retain their historical current-axes/figure behavior.
farmPlotVlns creates a figure; farmManVlnPlot draws on current axes.
They calculate and return their historical means/medians. Axes injection,
separation of statistics from rendering, and export redesign are deferred.

testCanonicalUtilities checks expected numeric results, violin statistics,
grouped violins and PNG/FIG exports. Figures are hidden and test-created figures
are closed; pre-existing figures and the default visibility setting are preserved.
The suite is included in runSharedUtilitiesTests and runAllTests.
