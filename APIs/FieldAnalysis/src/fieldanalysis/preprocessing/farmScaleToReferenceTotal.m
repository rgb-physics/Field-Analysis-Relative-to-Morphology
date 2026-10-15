function [scaled,factor] = farmScaleToReferenceTotal(field,referenceTotal)
%FARMSCALETOREFERENCETOTAL Explicit optional total-intensity reference scaling.
% Reference selection/loading is caller-owned. No thresholding or range stretch.
field = farmFAField(field);
validateattributes(referenceTotal,{'numeric'},{'scalar','real','finite','positive'});
currentTotal = sum(field(:));
if currentTotal<=0, error('fieldanalysis:ReferenceTotal','Current total must be positive.'); end
factor = double(referenceTotal)/currentTotal; scaled = field*factor;
end
