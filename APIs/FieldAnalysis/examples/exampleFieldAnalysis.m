%EXAMPLEFIELDANALYSIS Same-frame analysis without an XYZT stack.
% Add FieldAnalysis/src and SharedUtilities/src to the MATLAB path.
[y,x,z]=ndgrid(1:48,1:64,1:12);
intensity=10+cos(2*pi*x/8)+.2*cos(2*pi*y/12);
distance=sqrt((y-24).^2+(x-32).^2+(z-6).^2);
opts=struct('Spacing',[1 1],'NumBins',30);
sliceSpectra=fieldanalysis.fourier.selectSlicesAnalysis(intensity,[3 6 9],opts);
projectionSpectrum=fieldanalysis.fourier.powerSpectrum2D(mean(intensity,3),opts);
volumeSpectrum=fieldanalysis.fourier.powerSpectrum3D(intensity,struct('Spacing',[1 1 1]));
% samAdapted normalization can be applied afterward; stored power is raw.
normalizedRadial=volumeSpectrum.Radial.Mean/volumeSpectrum.Normalization.VoxelCount;
% Identical numerical core for whole matrices and selected samples.
fullProfile=fieldanalysis.conditional.conditionalStatistics(intensity,distance,struct('Edges',0:2:50));
indices=find(distance<15);
selectedProfile=fieldanalysis.conditional.conditionalStatistics(intensity(indices),distance(indices), ...
    struct('Edges',0:2:16,'Statistics',{{'Mean','Variance','Median'}}));
% 3D linear correlation; this temporary map can be reduced then discarded.
correlation=fieldanalysis.spatialCorrelation.autoCorrelation(intensity,struct('MeanSubtract',true));
radialCorrelation=fieldanalysis.fourier.radialAverage(correlation.Correlation, ...
    struct('Coordinates',{correlation.LagAxes},'NumBins',30));
% For real batches: load the current XYZ field(s), perform these operations,
% store only the requested tables/profiles with DatasetID/Frame, then overwrite
% the arrays with the next frame. Do not accumulate all XYZ fields in memory.
