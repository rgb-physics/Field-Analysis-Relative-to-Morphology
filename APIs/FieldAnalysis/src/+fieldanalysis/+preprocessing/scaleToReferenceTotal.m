function [scaled,factor]=scaleToReferenceTotal(field,referenceTotal)
%SCALETOREFERENCETOTAL Explicit optional total-intensity reference scaling.
% Reference selection/loading is caller-owned. No thresholding or range stretch.
field=fieldanalysis.internal.field(field);
validateattributes(referenceTotal,{'numeric'},{'scalar','real','finite','positive'});
currentTotal=sum(field(:));
if currentTotal<=0, error('fieldanalysis:ReferenceTotal','Current total must be positive.'); end
factor=double(referenceTotal)/currentTotal; scaled=field*factor;
end
