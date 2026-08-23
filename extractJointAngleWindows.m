function joints = extractJointAngleWindows(modelOutputs, windowSamples)
%EXTRACTJOINTANGLEWINDOWS Extract first/last windows for four joint angles.

    validateattributes(modelOutputs, {'numeric'}, {'2d'}, mfilename, 'modelOutputs');
    validateattributes(windowSamples, {'numeric'}, ...
        {'scalar', 'integer', 'positive'}, mfilename, 'windowSamples');
    if size(modelOutputs, 1) < windowSamples
        error('extractJointAngleWindows:TooFewRows', ...
            'Model outputs contain %d rows; %d are required.', ...
            size(modelOutputs, 1), windowSamples);
    end

    jointColumns = struct('ankle', 6:8, 'knee', 51:53, ...
        'hip', 39:41, 'pelvis', 63:65);
    requiredColumns = max(jointColumns.pelvis);
    if size(modelOutputs, 2) < requiredColumns
        error('extractJointAngleWindows:TooFewColumns', ...
            'Model outputs require at least %d columns.', requiredColumns);
    end

    firstRows = 1:windowSamples;
    lastRows = size(modelOutputs, 1)-windowSamples+1:size(modelOutputs, 1);
    names = fieldnames(jointColumns);
    for index = 1:numel(names)
        name = names{index};
        columns = jointColumns.(name);
        values = cat(3, modelOutputs(firstRows, columns), ...
            modelOutputs(lastRows, columns));
        if any(~isfinite(values), 'all')
            error('extractJointAngleWindows:NonfiniteAngles', ...
                'The %s angle window contains missing or nonfinite values.', name);
        end
        joints.(name) = values;
    end
end
