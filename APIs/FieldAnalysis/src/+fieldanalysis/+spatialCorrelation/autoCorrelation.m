function result=autoCorrelation(data,options)
%AUTOCORRELATION Unnormalized linear self-correlation.
if nargin<2, options=struct(); end
result=fieldanalysis.spatialCorrelation.crossCorrelation(data,data,options);
end
