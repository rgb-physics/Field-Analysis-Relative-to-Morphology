function result = farmAutoCorrelation(data, options)
%FARMAUTOCORRELATION Unnormalized linear self-correlation.
% Inputs:
%   data            Real numeric image or volume.
%   options         Operation settings struct.
% Outputs:
%   result          Linear self-correlation array with lag and normalization metadata.

if nargin < 2
    options = struct();
end
result = farmCrossCorrelation(data, data, options);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMAUTOCORRELATION Unnormalized linear self-correlation.
