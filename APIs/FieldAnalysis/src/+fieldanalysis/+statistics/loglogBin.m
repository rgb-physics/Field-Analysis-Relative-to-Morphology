function [meanLogXVals,meanLogYVals]=loglogBin(xVals,yVals,numBins)
%LOGLOGBIN Paired log-domain means in occupied X bins (not arithmetic means).
validateattributes(xVals,{'numeric'},{'vector','real','finite','positive'});
validateattributes(yVals,{'numeric'},{'vector','real','finite','positive'});
validateattributes(numBins,{'numeric'},{'scalar','integer','positive','finite'});
if numel(xVals)~=numel(yVals), error('sharedutilities:SizeMismatch','X/Y samples must correspond.'); end
xVals=xVals(:); yVals=yVals(:);
[~,edges,bins]=histcounts(log(xVals),numBins);
mx=NaN(1,numel(edges)-1); my=mx;
for k=1:numel(mx)
    selected=bins==k;
    if any(selected), mx(k)=mean(log(xVals(selected))); my(k)=mean(log(yVals(selected))); end
end
keep=isfinite(mx)&isfinite(my); meanLogXVals=mx(keep); meanLogYVals=my(keep);
end
