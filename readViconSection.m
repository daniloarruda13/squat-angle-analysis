function [data, metadata] = readViconSection(filePath, sectionName)
%READVICONSECTION Read one named numeric section from a Vicon CSV export.
%   [DATA,METADATA] = READVICONSECTION(FILE, SECTION) locates a section such
%   as "Model Outputs" or "Trajectories" instead of relying on raw file-row
%   numbers. Empty numeric fields are represented by NaN.

    validateattributes(filePath, {'char', 'string'}, {'scalartext'}, mfilename, 'filePath');
    validateattributes(sectionName, {'char', 'string'}, {'scalartext'}, mfilename, 'sectionName');
    filePath = char(filePath);
    sectionName = char(sectionName);

    fileId = fopen(filePath, 'rt');
    if fileId < 0
        error('readViconSection:OpenFailed', 'Could not open %s.', filePath);
    end
    cleanup = onCleanup(@() fclose(fileId));

    found = false;
    while ~feof(fileId)
        line = fgetl(fileId);
        if ischar(line) && strcmp(strtrim(line), sectionName)
            found = true;
            break;
        end
    end
    if ~found
        error('readViconSection:MissingSection', ...
            'Section "%s" was not found in %s.', sectionName, filePath);
    end

    sampleRateLine = fgetl(fileId);
    namesLine = fgetl(fileId);
    columnsLine = fgetl(fileId);
    unitsLine = fgetl(fileId);
    if any(cellfun(@(value) ~ischar(value), ...
            {sampleRateLine, namesLine, columnsLine, unitsLine}))
        error('readViconSection:IncompleteHeader', ...
            'Section "%s" has an incomplete header.', sectionName);
    end

    metadata = struct();
    metadata.section = sectionName;
    metadata.sampleRate = str2double(strtrim(sampleRateLine));
    metadata.names = splitLine(namesLine);
    metadata.columns = splitLine(columnsLine);
    metadata.units = splitLine(unitsLine);
    if ~isfinite(metadata.sampleRate) || metadata.sampleRate <= 0
        error('readViconSection:InvalidSampleRate', ...
            'Section "%s" has an invalid sample rate.', sectionName);
    end

    columnCount = numel(metadata.columns);
    capacity = 10000;
    data = nan(capacity, columnCount);
    rowCount = 0;
    while ~feof(fileId)
        line = fgetl(fileId);
        if ~ischar(line) || isempty(strtrim(line))
            break;
        end
        tokens = splitLine(line);
        if numel(tokens) ~= columnCount
            error('readViconSection:ColumnCount', ...
                'Data row %d has %d columns; expected %d.', ...
                rowCount + 1, numel(tokens), columnCount);
        end
        rowCount = rowCount + 1;
        if rowCount > size(data, 1)
            data = [data; nan(capacity, columnCount)]; %#ok<AGROW>
        end
        data(rowCount, :) = str2double(tokens);
    end
    data = data(1:rowCount, :);
    if isempty(data)
        error('readViconSection:NoData', ...
            'Section "%s" contains no data rows.', sectionName);
    end
end

function fields = splitLine(line)
    fields = strsplit(line, ',', 'CollapseDelimiters', false);
end
