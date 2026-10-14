function keyError(options,code,message,varargin)
%KEYERROR Domain wrappers preserve their established error identifiers.
if isfield(options.ErrorNames,code), code=options.ErrorNames.(code); end
error([options.ErrorPrefix ':' code],message,varargin{:});
end
