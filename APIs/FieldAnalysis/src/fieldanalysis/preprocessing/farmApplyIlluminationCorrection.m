function [corrected,info] = farmApplyIlluminationCorrection(field,model,options)
%FARMAPPLYILLUMINATIONCORRECTION Correct a quantitative field without stretching.
% BleachScale=false by default. Returns double; export conversion is external.
if nargin<3, options = struct(); end
o = farmFAOptions(options, struct('BleachScale',false));
validateattributes(o.BleachScale,{'logical'},{'scalar'});
field = farmFAField(field);
if ~isequal(size(field),size(model.Correction)), error('fieldanalysis:SizeMismatch','Correction and field grids must match.'); end
if any(~isfinite(model.Correction(:)))||any(model.Correction(:)<=0), error('fieldanalysis:Correction','Invalid correction.'); end
factor = 1;
if o.BleachScale
    [~,factor] = farmScaleToReferenceTotal(field,model.ReferenceTotal);
end
corrected = field./model.Correction*factor;
info = struct('BleachScale',o.BleachScale,'AppliedFactor',factor,'ReferenceTotal',model.ReferenceTotal);
end
