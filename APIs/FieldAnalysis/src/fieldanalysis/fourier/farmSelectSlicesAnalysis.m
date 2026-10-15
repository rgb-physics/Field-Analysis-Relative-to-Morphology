function results = farmSelectSlicesAnalysis(volume,slices,options)
%FARMSELECTSLICESANALYSIS Return one separate XY power spectrum per selected Z.
% Projection is external: farmPowerSpectrum2D(mean(volume,3),options), etc.
if nargin<3, options = struct(); end
volume = farmFAField(volume);
validateattributes(slices,{'numeric'},{'vector','integer','positive','finite','<=',size(volume,3)});
results = cell(numel(slices),1);
for k = 1:numel(slices)
    results{k} = farmPowerSpectrum2D(volume(:,:,slices(k)),options);
    results{k}.Slice = slices(k);
end
end
