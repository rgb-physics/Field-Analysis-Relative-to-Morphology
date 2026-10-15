function outMat = farmNoNan(inMat,replVal)
%FARMNONAN Replace NaN only (not Inf), preserving input class and all other values.
if nargin<2, replVal = 0; end
validateattributes(replVal,{'numeric'},{'scalar'});
outMat = inMat; outMat(isnan(inMat)) = replVal;
end
