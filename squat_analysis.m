function squat_analysis(doAnimation)
%SQUAT_ANALYSIS Compare parallel and deep squat motion-capture trials.
%   SQUAT_ANALYSIS runs the plots without animation. SQUAT_ANALYSIS(TRUE)
%   also renders the first and last 10-second stick-figure comparisons.

    arguments
        doAnimation (1, 1) logical = false
    end

%% Settings
sampleRate = 200;             % Hz
windowDuration = 10;          % seconds
windowSamples = sampleRate * windowDuration;
lowpassCutoff = 15;           % Hz
filterOrder = 2;
animationFrameStep = 12;      % Larger values render fewer frames.
baseDir = fileparts(mfilename('fullpath'));

%% Read named sections from the multi-section Vicon CSV exports
[regModel, regModelMetadata] = readViconSection( ...
    fullfile(baseDir, 'reg_squat.csv'), 'Model Outputs');
[depModel, depModelMetadata] = readViconSection( ...
    fullfile(baseDir, 'dep_squat.csv'), 'Model Outputs');
[regTrajectories, regTrajectoryMetadata] = readViconSection( ...
    fullfile(baseDir, 'reg_squat.csv'), 'Trajectories');
[depTrajectories, depTrajectoryMetadata] = readViconSection( ...
    fullfile(baseDir, 'dep_squat.csv'), 'Trajectories');

sampleRates = [regModelMetadata.sampleRate, depModelMetadata.sampleRate, ...
    regTrajectoryMetadata.sampleRate, depTrajectoryMetadata.sampleRate];
if any(sampleRates ~= sampleRate)
    error('squat_analysis:SampleRateMismatch', ...
        'Expected all sections to use %g Hz; found %s.', ...
        sampleRate, mat2str(sampleRates));
end
if size(regTrajectories, 2) < 50 || size(depTrajectories, 2) < 50
    error('squat_analysis:MissingMarkers', ...
        'Trajectory sections require frame columns plus 48 marker columns.');
end

%% Prepare angle and marker windows
regAngles = extractJointAngleWindows(regModel, windowSamples);
depAngles = extractJointAngleWindows(depModel, windowSamples);

regCoordinates = regTrajectories(:, 3:50);
depCoordinates = depTrajectories(:, 3:50);
regCoordinates = filterdata( ...
    regCoordinates, sampleRate, 0, lowpassCutoff, filterOrder, false);
depCoordinates = filterdata( ...
    depCoordinates, sampleRate, 0, lowpassCutoff, filterOrder, false);
Reg = extractLowerBodyMarkers(regCoordinates);
Dep = extractLowerBodyMarkers(depCoordinates);

time = (0:windowSamples-1) / sampleRate;
colors = lines(3);
yLimits = struct('ankle', [-60, 180], 'knee', [-100, 180], ...
    'hip', [-100, 180], 'pelvis', [-100, 180]);

plotJointGrid(time, regAngles.ankle, depAngles.ankle, ...
    'Ankle Angles', yLimits.ankle, colors);
plotJointGrid(time, regAngles.knee, depAngles.knee, ...
    'Knee Angles', yLimits.knee, colors);
plotJointGrid(time, regAngles.hip, depAngles.hip, ...
    'Hip Angles', yLimits.hip, colors);
plotJointGrid(time, regAngles.pelvis, depAngles.pelvis, ...
    'Pelvis Angles', yLimits.pelvis, colors);

%% Optional stick-figure animations
if doAnimation
    linkPairs = [1, 2; 2, 4; 1, 3; 3, 4; 5, 1; 5, 3; ...
        5, 7; 2, 9; 4, 9; 9, 11; 11, 12; 7, 8];
    axisLimits = [-400, 300, 1500, 2200, 0, 1700];
    viewDirection = [3, 10, 2];

    regFirst = buildStickFigureData(Reg, 1, windowSamples);
    depFirst = buildStickFigureData(Dep, 1, windowSamples);
    regLastStart = size(Reg.LASIS, 1) - windowSamples + 1;
    depLastStart = size(Dep.LASIS, 1) - windowSamples + 1;
    regLast = buildStickFigureData(Reg, regLastStart, windowSamples);
    depLast = buildStickFigureData(Dep, depLastStart, windowSamples);

    animateComparison(regFirst, depFirst, 'First 10 s', linkPairs, ...
        viewDirection, axisLimits, animationFrameStep);
    animateComparison(regLast, depLast, 'Last 10 s', linkPairs, ...
        viewDirection, axisLimits, animationFrameStep);
end

%% Example marker-derived right-knee angles
regRightThigh = Reg.R_pelvis - Reg.RKNEE;
regRightShank = Reg.RKNEE - Reg.RANK;
depRightThigh = Dep.R_pelvis - Dep.RKNEE;
depRightShank = Dep.RKNEE - Dep.RANK;
Reg_R_KNEE_ANG = TwoDangleNew(regRightThigh, regRightShank);
Dep_R_KNEE_ANG = TwoDangleNew(depRightThigh, depRightShank);
fprintf(['Prepared %d regular and %d deep frames; angle windows contain ' ...
    '%d samples each.\n'], size(regCoordinates, 1), ...
    size(depCoordinates, 1), windowSamples);
fprintf('Marker-derived right-knee ranges: parallel %.1f-%.1f, deep %.1f-%.1f degrees.\n', ...
    min(Reg_R_KNEE_ANG), max(Reg_R_KNEE_ANG), ...
    min(Dep_R_KNEE_ANG), max(Dep_R_KNEE_ANG));
end

function plotJointGrid(time, regular, deep, figureTitle, limits, colors)
    figure('Name', figureTitle);
    layout = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(layout, figureTitle);
    panels = {
        regular(:, :, 1), 'First 10 s Parallel Squat';
        regular(:, :, 2), 'Last 10 s Parallel Squat';
        deep(:, :, 1), 'First 10 s Deep Squat';
        deep(:, :, 2), 'Last 10 s Deep Squat'
    };

    for panel = 1:size(panels, 1)
        axesHandle = nexttile(layout);
        values = panels{panel, 1};
        hold(axesHandle, 'on');
        for channel = 1:size(values, 2)
            plot(axesHandle, time, values(:, channel), ...
                'LineWidth', 1.8, 'Color', colors(channel, :));
        end
        ylim(axesHandle, limits);
        xlabel(axesHandle, 'Time (s)');
        ylabel(axesHandle, 'Angle (degrees)');
        title(axesHandle, panels{panel, 2});
        grid(axesHandle, 'on');
        box(axesHandle, 'on');
        if panel == size(panels, 1)
            legend(axesHandle, {'Flex/Ext', 'Rotation', 'Ab/Ad'}, ...
                'Orientation', 'horizontal', 'Location', 'southoutside');
        end
    end
end

function animateComparison(regular, deep, windowLabel, links, viewDirection, ...
        axisLimits, frameStep)
    figureHandle = figure('Name', ['Squat Comparison - ', windowLabel]);
    layout = tiledlayout(figureHandle, 1, 2, ...
        'TileSpacing', 'compact', 'Padding', 'compact');
    regularAxes = nexttile(layout);
    title(regularAxes, ['Parallel (', windowLabel, ')']);
    deepAxes = nexttile(layout);
    title(deepAxes, ['Deep (', windowLabel, ')']);
    StickFigure1(regular, links, [], [], viewDirection, ...
        axisLimits, frameStep, regularAxes);
    StickFigure1(deep, links, [], [], viewDirection, ...
        axisLimits, frameStep, deepAxes);
end
