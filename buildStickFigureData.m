function data = buildStickFigureData(markers, startRow, frameCount)
%BUILDSTICKFIGUREDATA Concatenate ordered marker windows for StickFigure1.

    validateattributes(startRow, {'numeric'}, ...
        {'scalar', 'integer', 'positive'}, mfilename, 'startRow');
    validateattributes(frameCount, {'numeric'}, ...
        {'scalar', 'integer', 'positive'}, mfilename, 'frameCount');
    names = {'LASIS', 'RASIS', 'LPSIS', 'RPSIS', 'LKNEE', 'LANK', ...
        'LHEEL', 'LTOE', 'RKNEE', 'RANK', 'RHEEL', 'RTOE'};
    missing = names(~isfield(markers, names));
    if ~isempty(missing)
        error('buildStickFigureData:MissingMarkers', ...
            'Missing marker fields: %s.', strjoin(missing, ', '));
    end

    lastRow = startRow + frameCount - 1;
    rowCounts = cellfun(@(name) size(markers.(name), 1), names);
    if lastRow > min(rowCounts)
        error('buildStickFigureData:WindowOutOfRange', ...
            'Requested rows %d:%d exceed the available marker data.', ...
            startRow, lastRow);
    end
    pieces = cellfun(@(name) markers.(name)(startRow:lastRow, :), ...
        names, 'UniformOutput', false);
    data = [pieces{:}];
end
