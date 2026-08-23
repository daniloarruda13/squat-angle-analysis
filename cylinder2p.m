function [X, Y, Z] = cylinder2p(R, N, r1, r2)
%CYLINDER2P Create a deterministic cylinder surface between two 3-D points.
%   [X,Y,Z] = CYLINDER2P(R,N,R1,R2) uses the radii in R along the axis from
%   R1 to R2 and N samples around each circumference.

    validateattributes(R, {'numeric'}, ...
        {'vector', 'real', 'finite', 'nonnegative'}, mfilename, 'R');
    validateattributes(N, {'numeric'}, ...
        {'scalar', 'integer', '>=', 3}, mfilename, 'N');
    validateattributes(r1, {'numeric'}, ...
        {'vector', 'numel', 3, 'real', 'finite'}, mfilename, 'r1');
    validateattributes(r2, {'numeric'}, ...
        {'vector', 'numel', 3, 'real', 'finite'}, mfilename, 'r2');

    R = double(R(:));
    r1 = double(r1(:).');
    r2 = double(r2(:).');
    if isscalar(R)
        R = [R; R];
    end

    axisVector = r2 - r1;
    axisLength = norm(axisVector);
    if axisLength == 0
        error('cylinder2p:CoincidentPoints', ...
            'Cylinder endpoints must be distinct.');
    end
    axisUnit = axisVector / axisLength;

    % Choose the coordinate axis least aligned with the cylinder. This
    % yields a stable orthonormal basis without the old random orientation.
    [~, referenceIndex] = min(abs(axisUnit));
    reference = zeros(1, 3);
    reference(referenceIndex) = 1;
    basis1 = cross(axisUnit, reference);
    basis1 = basis1 / norm(basis1);
    basis2 = cross(axisUnit, basis1);

    theta = linspace(0, 2*pi, N);
    position = linspace(0, 1, numel(R));
    X = zeros(numel(R), N);
    Y = zeros(numel(R), N);
    Z = zeros(numel(R), N);

    circle = cos(theta(:)) * basis1 + sin(theta(:)) * basis2;
    for row = 1:numel(R)
        center = r1 + position(row) * axisVector;
        points = center + R(row) * circle;
        X(row, :) = points(:, 1).';
        Y(row, :) = points(:, 2).';
        Z(row, :) = points(:, 3).';
    end
end
