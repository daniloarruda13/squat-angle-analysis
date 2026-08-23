function tests = TestSquatHelpers
    tests = functiontests(localfunctions);
end

function testUnitVectors(testCase)
    actual = unitvec([3, 0, 4; 0, -2, 0]);
    verifyEqual(testCase, vecnorm(actual, 2, 2), ones(2, 1), ...
        'AbsTol', 1e-12);
    verifyEqual(testCase, actual(1, :), [0.6, 0, 0.8], 'AbsTol', 1e-12);
end

function testUnitVectorRejectsZero(testCase)
    verifyError(testCase, @() unitvec([0, 0, 0]), 'unitvec:ZeroVector');
end

function testPairedAnglesWithoutToolbox(testCase)
    first = [1, 0, 0; 2, 0, 0; 1, 0, 0];
    second = [1, 0, 0; 0, 3, 0; -4, 0, 0];
    verifyEqual(testCase, TwoDangleNew(first, second), [0; 90; 180], ...
        'AbsTol', 1e-12);
end

function testCylinderIsDeterministicAndHasRequestedRadius(testCase)
    point1 = [1, 2, 3];
    point2 = [4, 6, 8];
    [X1, Y1, Z1] = cylinder2p([2, 3], 20, point1, point2);
    [X2, Y2, Z2] = cylinder2p([2, 3], 20, point1, point2);
    verifyEqual(testCase, {X1, Y1, Z1}, {X2, Y2, Z2});

    firstCircle = [X1(1, :).', Y1(1, :).', Z1(1, :).'];
    lastCircle = [X1(2, :).', Y1(2, :).', Z1(2, :).'];
    verifyEqual(testCase, vecnorm(firstCircle - point1, 2, 2), ...
        2 * ones(20, 1), 'AbsTol', 1e-12);
    verifyEqual(testCase, vecnorm(lastCircle - point2, 2, 2), ...
        3 * ones(20, 1), 'AbsTol', 1e-12);
end

function testCylinderRejectsCoincidentEndpoints(testCase)
    verifyError(testCase, @() cylinder2p(1, 10, [0, 0, 0], [0, 0, 0]), ...
        'cylinder2p:CoincidentPoints');
end

function testAngleWindowsUseExactFirstAndLastRows(testCase)
    data = reshape(1:8*70, 8, 70);
    joints = extractJointAngleWindows(data, 3);
    verifySize(testCase, joints.ankle, [3, 3, 2]);
    verifyEqual(testCase, joints.ankle(:, :, 1), data(1:3, 6:8));
    verifyEqual(testCase, joints.ankle(:, :, 2), data(6:8, 6:8));
    verifyEqual(testCase, joints.knee(:, :, 1), data(1:3, 51:53));
    verifyEqual(testCase, joints.pelvis(:, :, 2), data(6:8, 63:65));
end

function testMarkerMappingAndStickWindow(testCase)
    coordinates = reshape(1:5*48, 5, 48);
    markers = extractLowerBodyMarkers(coordinates);
    verifyEqual(testCase, markers.LASIS, coordinates(:, 1:3));
    verifyEqual(testCase, markers.RTOE, coordinates(:, 46:48));
    verifyEqual(testCase, markers.R_pelvis, ...
        (coordinates(:, 4:6) + coordinates(:, 10:12)) / 2);
    animationData = buildStickFigureData(markers, 2, 3);
    verifySize(testCase, animationData, [3, 36]);
    verifyEqual(testCase, animationData(:, 1:3), coordinates(2:4, 1:3));
end

function testViconSectionReader(testCase)
    filePath = [tempname, '.csv'];
    cleanup = onCleanup(@() deleteIfPresent(filePath));
    fileId = fopen(filePath, 'wt');
    verifyGreaterThan(testCase, fileId, 0);
    fileCleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, ['Other Section\n100\nA\nFrame,X\n,mm\n1,2\n\n' ...
        'Model Outputs\n200\n,,Joint\nFrame,Sub Frame,X,Y,Z\n' ...
        ',,deg,deg,deg\n1,0,1,2,3\n2,0,4,,6\n\n']);
    clear fileCleanup;

    [data, metadata] = readViconSection(filePath, 'Model Outputs');
    verifyEqual(testCase, metadata.sampleRate, 200);
    verifyEqual(testCase, size(data), [2, 5]);
    verifyEqual(testCase, data(1, :), [1, 0, 1, 2, 3]);
    verifyTrue(testCase, isnan(data(2, 4)));
end

function testFilterRejectsInvalidCutoffBeforeToolboxUse(testCase)
    verifyError(testCase, @() filterdata(ones(20, 1), 100, 0, 50, 2, false), ...
        'filterdata:InvalidLowpass');
end

function deleteIfPresent(filePath)
    if isfile(filePath)
        delete(filePath);
    end
end
