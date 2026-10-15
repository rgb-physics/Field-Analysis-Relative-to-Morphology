function data = farmFAField(data)
%FARMFAFIELD Require a finite real scalar field. Repair invalid inputs upstream.
if ~(isnumeric(data)||islogical(data))||~isreal(data)||isempty(data)||ndims(data)>3
    error('fieldanalysis:Field','Supply a nonempty real 2D or 3D numeric array.');
end
data = double(data);
if any(~isfinite(data(:)))
    error('fieldanalysis:InvalidData','Input contains NaN or Inf. Find invalid indices and repair the matrix before analysis.');
end
end
