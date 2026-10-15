function [midSection] = farmInBetweenFill(mat1, mat2)
%FARMINBETWEENFILL Takes in two matrices containing binarized info of sheet
%locations, then returns a matrix indicating the space between said sheets
% 2023-06-28
 
    lap1 = cumsum(mat1); lap2 = cumsum(mat2,'reverse');
    midSection = (logical(lap1) & logical(lap2));

end

