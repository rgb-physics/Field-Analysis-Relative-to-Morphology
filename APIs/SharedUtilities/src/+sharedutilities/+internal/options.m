function out=options(user,defaults)
%OPTIONS Shared helpers reject unrecognized option names.
out=defaults;
if nargin<1||isempty(user), return; end
if ~isstruct(user)||~isscalar(user), error('sharedutilities:Options','Options must be a scalar struct.'); end
for name=fieldnames(user)'
    if ~isfield(defaults,name{1}), error('sharedutilities:Options','Unknown option: %s.',name{1}); end
    out.(name{1})=user.(name{1});
end
end
