function out = farmFAOptions(user, defaults)
%FARMFAOPTIONS Complete user options using defaults; reject unknown names.
% Input order matches farmOGOptions and farmSUOptions.
if nargin < 2, error('fieldanalysis:Options', 'Provide user options and defaults.'); end
out = defaults;
if isempty(user), return; end
if ~isstruct(user) || ~isscalar(user), error('fieldanalysis:Options', 'Options must be a scalar struct.'); end
names = fieldnames(user);
for k = 1:numel(names)
    if ~isfield(defaults, names{k}), error('fieldanalysis:Options', 'Unknown option: %s.', names{k}); end
    out.(names{k}) = user.(names{k});
end
end
