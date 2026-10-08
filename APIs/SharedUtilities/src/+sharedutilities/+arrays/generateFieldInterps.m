function [outFields] = generateFieldInterps(ivec,inFields)
%GENERATEFIELDINTERPS ivec are vectors corresponding to the range of x, y, 
%and z values over which the inputted field(s) are defined. Each of these
%should be of the form (x_i(min):spacing:x_i(max)) in a cell array.
% The input fields are expected to be in the matrix shape associated with
% the tensor they represent (i.e. 3D tensor for a field defined in 3D).
% IMPORTANT: The syntax used here, namely a cell array of ranges passed to
% the griddedInterpolant function, assumes grid vector syntax (ndgrid).
% Since the user is expected to pass COORDINATES, one must permute
% dimensions 1 and 2 of the queried fields. This generates the correct
% matrix dimension size and returns gridded interpolant objects that accept
% queries in the form (x_q,y_q,...) rather than (rowind_q,colind_q,...)
% 2023-11-28

% Define permVec to permute fields col,row to row,col (for ndgrid)
permVec = 1:numel(ivec);    permVec(2:-1:1) = permVec(1:2);
% Check if fields is a cell, if so, iterate over each
if iscell(inFields)
    outFields = cell(size(inFields));
    for fieldInd = 1:numel(inFields)
        outFields{fieldInd} = griddedInterpolant(ivec,permute(inFields{fieldInd},permVec));
    end
else
    outFields = griddedInterpolant(ivec,permute(inFields,permVec));
end
% Effectively doing ndgrid on x,y,z and transpose of field matrix. This
% returns gridded interpolant objects that take in x,y,... instead of
% row,col,...
end

