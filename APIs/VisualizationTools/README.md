# VisualizationTools: ownership cleanup

The broader visualization API is still awaiting design. This pass only
relocates three existing implementations without changing their plotting
or numerical behavior:

| Canonical function | Former path (still supported) |
|---|---|
| visualizationtools.export.figSaves | sharedutilities.plotting.figSaves |
| visualizationtools.display.manVlnPlot | sharedutilities.plotting.manVlnPlot |
| visualizationtools.display.plotVlns | sharedutilities.plotting.plotVlns |

Add VisualizationTools/src and SharedUtilities/src to the MATLAB path.
Existing historical scripts remain; they are not modern API examples.
No mesh workflow or mixed script was moved or archived.
Original helper implementations are preserved in
SharedUtilities/archive/2026-10-13-ownership.

These helpers still use their historical current-axes/figure behavior.
plotVlns creates a figure; manVlnPlot draws on current axes.
They still calculate and return their historical means/medians.
Axes injection, separation of statistics from rendering, and export redesign
are deferred to the Visualization implementation.

Four compatibility checks are included in runSharedUtilitiesTests:
old/new numerical entry points, violin geometry/statistics, grouped violins,
and PNG/FIG exports. Figures are hidden and test-created figures are closed;
pre-existing figures and the default visibility setting are preserved.
