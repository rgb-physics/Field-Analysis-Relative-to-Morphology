function model = farmFitIlluminationCorrection(frames, loader, options)
%FARMFITILLUMINATIONCORRECTION Stream early XYZ references, following corr3DTiff.
% Inputs:
%   frames          Acquisition frame numbers in the requested processing order.
%   loader          Function handle that loads one acquisition frame.
%   options         Optional scalar struct with the fields:
%                   Spacing = positive numeric three-element vector;
%                   FirstSigma = positive numeric scalar;
%                   SecondSigma = positive numeric scalar;
%                   OutlierPercentile = numeric scalar in [0, 100];
%                   PercentileScope = character vector or string scalar;
% Outputs:
%   model           Illumination/focal correction model derived from the supplied frames.

if nargin < 3
    options = struct();
end
o = farmFAOptions(options, struct('Spacing', [1 1 1], 'FirstSigma', 24, ...
                                  'SecondSigma', 20, 'OutlierPercentile', 97, 'PercentileScope', 'columns'));
validateattributes(frames, {'numeric'}, {'vector', 'nonempty', 'integer', 'positive', 'finite'});
validateattributes(o.Spacing, {'numeric'}, {'vector', 'numel', 3, 'positive', 'finite'});
validateattributes(o.FirstSigma, {'numeric'}, {'scalar', 'positive', 'finite'});
validateattributes(o.SecondSigma, {'numeric'}, {'scalar', 'positive', 'finite'});
validateattributes(o.OutlierPercentile, {'numeric'}, {'scalar', '>=', 0, '<=', 100});
scope = validatestring(o.PercentileScope, {'columns', 'global'});
for k = 1:numel(frames)
    a = farmFAField(loader(frames(k)));
    if k == 1
        dims = size(a);
        referenceTotal = sum(a(:));
        background = zeros(dims);
        if referenceTotal <= 0
            error('fieldanalysis:ReferenceTotal', 'Reference total must be positive.');
        end
    elseif ~isequal(size(a), dims)
        error('fieldanalysis:SizeMismatch', 'Reference grids must match.');
    end
    [a, ~] = farmScaleToReferenceTotal(a, referenceTotal);
    background = background + a / numel(frames);
end
if ndims(background) ~= 3
    error('fieldanalysis:Dimensions', 'Correction example requires XYZ volumes.');
end
workingSize = max(2, round(dims .* o.Spacing / min(o.Spacing)));
broad = imresize3(imgaussfilt3(imresize3(background, workingSize), o.FirstSigma, 'Padding', 'replicate'), dims);
if any(broad(:) <= 0)
    error('fieldanalysis:Correction', 'Broad correction contains nonpositive values.');
end
firstPass = background ./ broad * (referenceTotal / numel(background));
if strcmp(scope, 'global')
    threshold = prctile(firstPass(:), o.OutlierPercentile);
else
    threshold = prctile(firstPass, o.OutlierPercentile);
end
outliers = firstPass > threshold;
patched = background;
patched(outliers) = broad(outliers);
broad = imresize3(imgaussfilt3(imresize3(patched, workingSize), o.SecondSigma, 'Padding', 'replicate'), dims);
focal = median(background ./ broad, 3);
correction = broad .* focal / (referenceTotal / numel(background));
if any(~isfinite(correction(:))) || any(correction(:) <= 0)
    error('fieldanalysis:Correction', 'Correction contains nonfinite/nonpositive values.');
end
model = struct('Correction', correction, 'Broad', broad, 'Focal', focal, ...
               'ReferenceTotal', referenceTotal, 'ReferenceFrames', frames, 'Size', dims, 'Options', o);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMFITILLUMINATIONCORRECTION Stream early XYZ references, following corr3DTiff.
% Historical two-pass broad illumination and Z-median focal correction.
% Reference frames are scaled to the first frame total before averaging.
% PercentileScope='columns' reproduces native prctile(A,p) in the old script;
% 'global' is explicit alternate behavior. Correction model stays double.
