function StickFigure1(kindata, links, cop, grf, viewDirection, axisLimits, frameStep, axesHandle)
%STICKFIGURE1 Animate XYZ marker data and optional force vectors.
%   KINDATA is N-by-(3*M), LINKS contains one-based marker index pairs, and
%   FRAMESTEP controls frame decimation (12 renders every twelfth frame).

    validateattributes(kindata, {'numeric'}, {'2d', 'real'}, mfilename, 'kindata');
    if isempty(kindata) || mod(size(kindata, 2), 3) ~= 0
        error('StickFigure1:InvalidMarkerData', ...
            'kindata must be nonempty with three columns per marker.');
    end
    markerCount = size(kindata, 2) / 3;
    validateattributes(links, {'numeric'}, ...
        {'2d', 'ncols', 2, 'integer', 'positive', '<=', markerCount}, ...
        mfilename, 'links');
    validateattributes(axisLimits, {'numeric'}, ...
        {'vector', 'numel', 6, 'real', 'finite'}, mfilename, 'axisLimits');
    validateattributes(frameStep, {'numeric'}, ...
        {'scalar', 'integer', 'positive'}, mfilename, 'frameStep');

    if nargin < 8 || isempty(axesHandle)
        figureHandle = figure;
        axesHandle = axes('Parent', figureHandle);
    elseif ~isgraphics(axesHandle, 'axes')
        error('StickFigure1:InvalidAxes', 'axesHandle must be a valid axes object.');
    end

    hasForces = ~isempty(cop) || ~isempty(grf);
    if hasForces
        if isempty(cop) || isempty(grf)
            error('StickFigure1:IncompleteForces', ...
                'cop and grf must either both be supplied or both be empty.');
        end
        validateattributes(cop, {'numeric'}, ...
            {'2d', 'nrows', size(kindata, 1), 'ncols', 6, 'real', 'finite'}, ...
            mfilename, 'cop');
        validateattributes(grf, {'numeric'}, ...
            {'size', size(cop), 'real', 'finite'}, mfilename, 'grf');
    end

    frames = 1:frameStep:size(kindata, 1);
    markerData = reshape(kindata, size(kindata, 1), 3, markerCount);
    forceScale = 0.0001;

    axis(axesHandle, axisLimits);
    if ~isempty(viewDirection)
        view(axesHandle, viewDirection);
    end
    xlabel(axesHandle, 'X');
    ylabel(axesHandle, 'Y');
    zlabel(axesHandle, 'Z');
    grid(axesHandle, 'on');

    for frame = frames
        cla(axesHandle);
        hold(axesHandle, 'on');
        coordinates = squeeze(markerData(frame, :, :)).';
        plot3(axesHandle, coordinates(:, 1), coordinates(:, 2), ...
            coordinates(:, 3), 'ro', 'MarkerSize', 2, 'LineWidth', 1.5);

        if hasForces
            drawForce(axesHandle, cop(frame, 1:3), grf(frame, 1:3), ...
                forceScale, 'b');
            drawForce(axesHandle, cop(frame, 4:6), grf(frame, 4:6), ...
                forceScale, 'r');
        end

        for link = 1:size(links, 1)
            endpoints = coordinates(links(link, :), :);
            if any(~isfinite(endpoints), 'all') || ...
                    norm(endpoints(2, :) - endpoints(1, :)) == 0
                continue;
            end
            [X, Y, Z] = cylinder2p(12, 5, endpoints(1, :), endpoints(2, :));
            surf(axesHandle, X, Y, Z, 'EdgeColor', 'none', ...
                'FaceColor', [0.5, 0.5, 0.5]);
        end

        axis(axesHandle, axisLimits);
        if ~isempty(viewDirection)
            view(axesHandle, viewDirection);
        end
        drawnow limitrate;
    end
end

function drawForce(axesHandle, origin, force, scale, color)
    endpoint = origin + scale * force;
    plot3(axesHandle, [origin(1), endpoint(1)], ...
        [origin(2), endpoint(2)], [origin(3), endpoint(3)], ...
        color, 'LineWidth', 2);
end
