function tests = testFarmLOG
%TESTFARMLOG Compare shared imfilter calculations with the historical filter.
repo = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(repo);
farmSetup;
tests = functiontests(localfunctions);
end

function testTwoAndThreeDimensionalImages(t)
% Include image-edge impulses and several Gaussian support sizes.
for dimensions = [2 3]
    sz = [17 18 19];
    sz = sz(1:dimensions);
    data = reshape(mod(1:prod(sz), 101), sz) / 10;
    data(1) = 150;
    data(end) = -70;
    for sigma = [.5 1 2]
        expected = localHistoricalLOG(data, sigma);
        actual = farmLOG(data, sigma);
        verifySize(t, actual, sz);
        verifyEqual(t, actual, expected, 'AbsTol', 1e-10);
        verifyEqual(t, -actual > 20, -expected > 20);
    end
end
end

function testInputClasses(t)
for shape = {[7 8], [7 8 9]}
    base = reshape(mod(1:prod(shape{1}), 41), shape{1});
    for type = {'single', 'double', 'uint8', 'uint16', 'int16', 'logical'}
        data = cast(base, type{1});
        expected = localHistoricalLOG(data, 1);
        actual = farmLOG(data, 1);
        verifyClass(t, actual, class(expected));
        tolerance = 1e-10;
        if isa(data, 'single'), tolerance = 5e-5; end
        % Check the output class above; compare values using a matching tolerance type.
        verifyEqual(t, double(actual), double(expected), 'AbsTol', tolerance);
    end
end
end

function testConstantResponseRetainsHistoricalKernelSum(t)
% The sampled second-derivative kernel does not sum to exactly zero.
for dimensions = [2 3]
    sz = [9 10 11]; sz = sz(1:dimensions);
    data = 200 * ones(sz);
    gaussian = farmGaussD(1, 0);
    secondDerivative = farmGaussD(1, 2);
    expected = 200 * dimensions * sum(secondDerivative) * sum(gaussian)^(dimensions - 1);
    actual = farmLOG(data, 1);
    verifyEqual(t, actual, expected * ones(sz), 'AbsTol', 1e-10);
end
end

function testComplexInput(t)
data = reshape(mod(1:504, 37), [7 8 9]);
data = complex(data, flip(data, 2));
verifyEqual(t, farmLOG(data, 1), localHistoricalLOG(data, 1), 'AbsTol', 1e-10);
end

function testHistoricalPaddingLimit(t)
% imfilter itself allows more padding, but farmLOG retains its prior limit.
verifyEqual(t, farmLOG(ones(3, 4), 1), localHistoricalLOG(ones(3, 4), 1), 'AbsTol', 1e-12);
exception = [];
try
    farmLOG(ones(2, 8), 1);
catch caught
    exception = caught;
end
verifyNotEmpty(t, exception);
verifyEqual(t, exception.message, 'the kernel is larger than the stack!');
end

function result = localHistoricalLOG(data, sigma)
% Original ImSAnE axis-by-axis calculation; attribution/license is in farmLOG.
% Keep this reference independent of the optimized grouping and imfilter.
dimensions = ndims(data);
terms = cell(1, dimensions);
for derivativeAxis = 1:dimensions
    term = data;
    for filterAxis = 1:dimensions
        order = 2 * (derivativeAxis == filterAxis);
        term = farmMyconvn(term, farmGaussD(sigma, order, filterAxis));
    end
    terms{derivativeAxis} = term;
end
result = terms{1} + terms{2};
if dimensions == 3, result = result + terms{3}; end
end
