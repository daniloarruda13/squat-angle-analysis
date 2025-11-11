function StickFigure1(kindata, links, cop, grf, vu, axLimits, speed, axHandle)
% StickFigure1(kindata, links, cop, grf, vu, axLimits, speed, axHandle)
% Draws a stick figure animation of marker data.
%
% kindata:   [nFrames x (3*nMarkers)] matrix of XYZ data
% links:     [nLinks x 2] marker index pairs
% cop, grf:  (optional) Center-of-pressure and ground reaction vectors
% vu:        [az el] view vector, e.g. [3 10 2]
% axLimits:  [xmin xmax ymin ymax zmin zmax]
% speed:     interpolation factor (>1 = slower)
% axHandle:  (optional) target axes (if omitted, creates figure(1))

    if nargin < 8 || isempty(axHandle)
        fig = figure(1); clf(fig);
        axHandle = axes('Parent', fig);
    end

    % Resample data if speed ~= 1
    if speed ~= 1
        oldtime = 1:size(kindata,1);
        newtime = 1:(1*speed):size(kindata,1);
        kindata = interp1(oldtime, kindata, newtime);
    end

    scale = 0.0001;
    nFrames = size(kindata,1);
    nMarkers = size(kindata,2)/3;
    data = reshape(kindata, nFrames, 3, nMarkers);

    % Prepare axis
    axes(axHandle);
    hold(axHandle, 'on');
    axis(axHandle, axLimits);
    if ~isempty(vu)
        view(axHandle, vu);
    end
    xlabel(axHandle,'X'); ylabel(axHandle,'Y'); zlabel(axHandle,'Z');
    grid(axHandle,'on');

    % Animation loop
    for i = 1:nFrames
        cla(axHandle);

        % Marker positions
        x = squeeze(data(i,1,:));
        y = squeeze(data(i,2,:));
        z = squeeze(data(i,3,:));
        plot3(axHandle, x, y, z, 'ro', 'MarkerSize', 2, 'LineWidth', 1.5);

        % GRF vectors (optional)
        if ~isempty(cop)
            x1 = [cop(i,1), cop(i,1)+scale*grf(i,1)];
            y1 = [cop(i,2), cop(i,2)+scale*grf(i,2)];
            z1 = [cop(i,3), cop(i,3)+scale*grf(i,3)];
            plot3(axHandle, x1, y1, z1, 'b', 'LineWidth', 2);

            x2 = [cop(i,4), cop(i,4)+scale*grf(i,4)];
            y2 = [cop(i,5), cop(i,5)+scale*grf(i,5)];
            z2 = [cop(i,6), cop(i,6)+scale*grf(i,6)];
            plot3(axHandle, x2, y2, z2, 'r', 'LineWidth', 2);
        end

        % Link segments
for j = 1:size(links,1)
    data2 = data(:,:,links(j,:));
    x = squeeze(data2(i,1,:));
    y = squeeze(data2(i,2,:));
    z = squeeze(data2(i,3,:));

    if numel(x) < 2 || any(isnan([x;y;z]), 'all')
        continue; % Skip incomplete links
    end

    p1 = [x(1) y(1) z(1)];
    p2 = [x(2) y(2) z(2)];

    % Ensure they’re row vectors
    p1 = p1(:)'; 
    p2 = p2(:)';

    try
        [X,Y,Z] = cylinder2p(12,5,p1,p2);
        surf(axHandle, X, Y, Z, 'EdgeColor','none','FaceColor',[0.5 0.5 0.5]);

    catch ME
        warning('Link %d skipped: %s', j, ME.message);
    end
end


        drawnow limitrate nocallbacks
    end
end
