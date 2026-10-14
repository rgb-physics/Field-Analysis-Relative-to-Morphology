function out=options(defaults,user)
%OPTIONS Reject misspelled options instead of silently ignoring them.
out=defaults;
if nargin<2||isempty(user), return; end
if ~isstruct(user)||~isscalar(user), error('fieldanalysis:Options','Options must be a scalar struct.'); end
names=fieldnames(user);
for k=1:numel(names)
    if ~isfield(defaults,names{k}), error('fieldanalysis:Options','Unknown option: %s.',names{k}); end
    out.(names{k})=user.(names{k});
end
end
