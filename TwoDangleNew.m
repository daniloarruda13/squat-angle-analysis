function angles = TwoDangleNew(a, b)
%TWODANGLENEW Return the unsigned angle between paired 3-D row vectors.
%   ANGLES = TWODANGLENEW(A, B) returns one angle in degrees per row. The
%   atan2 formulation is stable near 0 and 180 degrees and requires no
%   specialized toolbox.

    validateattributes(a, {'numeric'}, ...
        {'2d', 'ncols', 3, 'real', 'finite'}, mfilename, 'a');
    validateattributes(b, {'numeric'}, ...
        {'size', size(a), 'real', 'finite'}, mfilename, 'b');

    a = unitvec(a);
    b = unitvec(b);
    crossMagnitude = vecnorm(cross(a, b, 2), 2, 2);
    dotProduct = sum(a .* b, 2);
    angles = atan2d(crossMagnitude, dotProduct);
end
