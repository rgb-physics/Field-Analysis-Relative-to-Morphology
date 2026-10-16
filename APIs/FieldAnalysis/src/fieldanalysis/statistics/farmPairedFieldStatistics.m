function result = farmPairedFieldStatistics(a, b)
%FARMPAIREDFIELDSTATISTICS Native covariance/correlation of corresponding values.
% Inputs:
%   a               First numeric field or sample vector.
%   b               Corresponding second numeric field or sample vector.
% Outputs:
%   result          Corresponding-sample covariance/correlation results.

if ~isequal(size(a), size(b)) && ~(isvector(a) && isvector(b) && numel(a) == numel(b))
    error('fieldanalysis:SizeMismatch', 'Arrays must correspond.');
end
a = farmFAField(a);
b = farmFAField(b);
if numel(a) < 2
    covariance = NaN(2);
    correlation = NaN(2);
else
    covariance = cov([a(:), b(:)]);
    correlation = corrcoef(a(:), b(:));
end
result = struct('Count', numel(a), 'Mean', [mean(a(:)), mean(b(:))], ...
                'Covariance', covariance, 'Correlation', correlation);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMPAIREDFIELDSTATISTICS Native covariance/correlation of corresponding values.
