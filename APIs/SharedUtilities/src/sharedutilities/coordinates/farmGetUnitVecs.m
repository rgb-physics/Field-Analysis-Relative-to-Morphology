function outMat = farmGetUnitVecs(inMat)
%FARMGETUNITVECS Normalize row vectors; zero or nonfinite rows are undefined (NaN).
validateattributes(inMat,{'numeric'},{'2d','real'});
outMat = double(inMat); magnitudes = vecnorm(outMat,2,2);
valid = all(isfinite(outMat),2)&magnitudes>0&isfinite(magnitudes);
outMat(:) = NaN; outMat(valid,:) = double(inMat(valid,:))./magnitudes(valid);
end
