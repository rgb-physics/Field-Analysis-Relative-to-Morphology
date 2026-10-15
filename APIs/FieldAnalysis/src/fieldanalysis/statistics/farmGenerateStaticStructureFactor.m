function [structFact,scaledvanHove,vanHove] = farmGenerateStaticStructureFactor(inputField,subWin)
%FARMGENERATESTATICSTRUCTUREFACTOR Takes in a field and returns the static
%structure factor over some sampled subwindow with length 2*subWin. If
%subWin is not defined by the user, it is taken to be the smallest of the
%dimensions of the inputField. The factor is calculated by applying a
%Fourier transform on the van Hove of the field after taking the edges to
%zero by multiplying with an appropriately sized Hann function

% Define subWin if not passed
if nargin == 1
    subWin = round(min(size(inputField)/2));
end

% Pad field before generating van Hove
currPadded = padarray(inputField, ceil(size(inputField)/2), 0); %pad array for proper fftn
vanHove = farmGenerateVanHove(currPadded);

% Take central portion of the van hove with window-size = 2*subWin
if numel(size(inputField)) == 2
    partvanHove = vanHove(size(inputField,1) + (-subWin:subWin), size(inputField,2) + (-subWin:subWin));
else
    partvanHove = vanHove(size(inputField,1) + (-subWin:subWin), ...
        size(inputField,2) + (-subWin:subWin),size(inputField,3) + (-subWin:subWin));
end
% Calculate the structure factor
hannFunc = farmGenerateNDHann(size(partvanHove));
scaledvanHove = hannFunc.*partvanHove;
structFact = abs(fftshift(fftn(scaledvanHove)));

end

