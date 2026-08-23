function y = unitvec(x)
%UNITVEC Normalize each three-dimensional row vector.
%   Y = UNITVEC(X) returns an N-by-3 matrix whose rows have unit magnitude.

    validateattributes(x, {'numeric'}, ...
        {'2d', 'ncols', 3, 'real', 'finite'}, mfilename, 'x');

    x = double(x);
    magnitudes = vecnorm(x, 2, 2);
    if any(magnitudes == 0)
        error('unitvec:ZeroVector', 'Cannot normalize a zero-length vector.');
    end
    y = x ./ magnitudes;
end
