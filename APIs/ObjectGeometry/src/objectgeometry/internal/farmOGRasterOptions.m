function options = farmOGRasterOptions(varargin)
%FARMOGRASTEROPTIONS Shared point/segment representation options.
options = farmParseOptions(struct('CoordinateOrder','XYZ', ...
    'Rounding','nearest','BoundsPolicy','error','Sigma',0,'Threshold',[]),varargin{:});
options.CoordinateOrder = validatestring(options.CoordinateOrder,{'XYZ','YXZ'});
options.Rounding = validatestring(options.Rounding,{'nearest','floor','ceil'});
options.BoundsPolicy = validatestring(options.BoundsPolicy,{'error','omit'});
validateattributes(options.Sigma,{'numeric'},{'vector','nonempty','real','finite','nonnegative'});
if ~isempty(options.Threshold), validateattributes(options.Threshold,{'numeric'},{'scalar','real','finite','nonnegative'}); end
end
