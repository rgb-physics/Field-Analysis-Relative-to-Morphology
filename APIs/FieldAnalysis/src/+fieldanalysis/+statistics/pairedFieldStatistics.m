function result=pairedFieldStatistics(a,b)
%PAIREDFIELDSTATISTICS Native covariance/correlation of corresponding values.
if ~isequal(size(a),size(b))&&~(isvector(a)&&isvector(b)&&numel(a)==numel(b))
    error('fieldanalysis:SizeMismatch','Arrays must correspond.');
end
a=fieldanalysis.internal.field(a); b=fieldanalysis.internal.field(b);
if numel(a)<2
    covariance=NaN(2); correlation=NaN(2);
else
    covariance=cov([a(:),b(:)]); correlation=corrcoef(a(:),b(:));
end
result=struct('Count',numel(a),'Mean',[mean(a(:)),mean(b(:))], ...
    'Covariance',covariance,'Correlation',correlation);
end
