function result = farmAutoCorrelation(data,options)
%FARMAUTOCORRELATION Unnormalized linear self-correlation.
if nargin<2, options = struct(); end
result = farmCrossCorrelation(data,data,options);
end
