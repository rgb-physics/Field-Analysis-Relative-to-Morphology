function farmSUKeyError(options,code,message,varargin)
%FARMSUKEYERROR Domain wrappers preserve their established error identifiers.
if isfield(options.ErrorNames,code), code = options.ErrorNames.(code); end
error([options.ErrorPrefix ':' code],message,varargin{:});
end
