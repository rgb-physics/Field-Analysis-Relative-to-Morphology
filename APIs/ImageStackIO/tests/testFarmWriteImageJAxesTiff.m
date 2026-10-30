function tests = testFarmWriteImageJAxesTiff
%TESTFARMWRITEIMAGEJAXESTIFF Check axes, channel ordering, and contiguous storage.
tests = functiontests(localfunctions);
end

function testPermutedAxesAndContiguousPixels(testCase)
filePath = [tempname, '.tif'];
cleanup = onCleanup(@() delete(filePath));
% Deliberately unequal spatial, channel, Z and T sizes reveal axis exchanges.
data = reshape(uint16(1:720), [3 4 2 5 6]); % Y X Z C T
input = permute(data, [4 2 5 1 3]); % C X T Y Z
farmWriteImageJAxesTiff(input, filePath, struct('SourceAxes', 'CXTYZ'));
info = imfinfo(filePath);
verifyNumElements(testCase, info, 60);
pageInd = 0;
for tInd = 1:6
    for zInd = 1:2
        for cInd = 1:5
            pageInd = pageInd + 1;
            verifyEqual(testCase, imread(filePath, pageInd), data(:, :, zInd, cInd, tInd));
        end
    end
end

% Read the physical bytes as ImageJ's contiguous stack path would, ignoring IFDs.
fileID = fopen(filePath, 'r', 'ieee-le');
fileCleanup = onCleanup(@() fclose(fileID));
fseek(fileID, 8, 'bof');
pixels = fread(fileID, numel(data), '*uint16');
expected = permute(data, [2 1 4 3 5]); % row-major XY, then C Z T
verifyEqual(testCase, pixels, expected(:));
verifyTrue(testCase, contains(info(1).ImageDescription, 'channels=5'));
verifyTrue(testCase, contains(info(1).ImageDescription, 'slices=2'));
verifyTrue(testCase, contains(info(1).ImageDescription, 'frames=6'));
end

function testNumericAxesAndOddByteCount(testCase)
filePath = [tempname, '.tif'];
cleanup = onCleanup(@() delete(filePath));
data = reshape(uint8(1:27), [3 3 3]);
farmWriteImageJAxesTiff(data, filePath, struct('SourceAxes', [1 2 4]));
info = imfinfo(filePath);
verifyNumElements(testCase, info, 3);
for cInd = 1:3
    verifyEqual(testCase, imread(filePath, cInd), data(:, :, cInd));
end
verifyTrue(testCase, contains(info(1).ImageDescription, 'slices=1'));
verifyTrue(testCase, contains(info(1).ImageDescription, 'channels=3'));
verifyError(testCase, @() farmWriteImageJAxesTiff(data, filePath, ...
    struct('SourceAxes', 'YXC')), 'imagestackio:OutputExists');
end

function testInvalidAxes(testCase)
verifyError(testCase, @() farmWriteImageJAxesTiff(zeros(2, 'uint8'), ...
    [tempname '.tif'], struct('SourceAxes', 'YY')), 'imagestackio:InvalidAxes');
end
