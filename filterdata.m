function dataFiltered = filterdata(dataRaw, sampleRate, highpassCutoff, lowpassCutoff, order, showPlots)
%FILTERDATA Apply a corrected zero-lag Butterworth filter by column.
%   Leading and trailing zeros are retained. FILTERDATA requires the Signal
%   Processing Toolbox functions BUTTER and FILTFILT.

    validateattributes(dataRaw, {'single', 'double'}, ...
        {'2d', 'real', 'finite'}, mfilename, 'dataRaw');
    validateattributes(sampleRate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, mfilename, 'sampleRate');
    validateattributes(highpassCutoff, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'}, mfilename, 'highpassCutoff');
    validateattributes(lowpassCutoff, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, mfilename, 'lowpassCutoff');
    validateattributes(order, {'numeric'}, ...
        {'scalar', 'integer', 'positive'}, mfilename, 'order');
    validateattributes(showPlots, {'numeric', 'logical'}, ...
        {'scalar'}, mfilename, 'showPlots');

    if lowpassCutoff >= sampleRate / 2
        error('filterdata:InvalidLowpass', ...
            'lowpassCutoff must be below the Nyquist frequency.');
    end
    if highpassCutoff >= lowpassCutoff
        error('filterdata:InvalidBand', ...
            'highpassCutoff must be smaller than lowpassCutoff.');
    end
    if exist('butter', 'file') ~= 2 || exist('filtfilt', 'file') ~= 2
        error('filterdata:MissingToolbox', ...
            'BUTTER and FILTFILT from Signal Processing Toolbox are required.');
    end

    correction = (sqrt(2) - 1)^(0.5 / order);
    correctedLowpass = lowpassCutoff / correction;
    if correctedLowpass >= sampleRate / 2
        error('filterdata:CorrectedCutoff', ...
            'The corrected low-pass cutoff must remain below Nyquist.');
    end
    if highpassCutoff == 0
        normalizedCutoff = 2 * correctedLowpass / sampleRate;
    else
        correctedHighpass = highpassCutoff / correction;
        normalizedCutoff = 2 * [correctedHighpass, correctedLowpass] / sampleRate;
    end
    [butterB, butterA] = butter(order, normalizedCutoff);

    dataFiltered = zeros(size(dataRaw), 'like', dataRaw);
    minimumLength = 3 * (max(numel(butterA), numel(butterB)) - 1);
    for column = 1:size(dataRaw, 2)
        firstSample = find(dataRaw(:, column) ~= 0, 1, 'first');
        lastSample = find(dataRaw(:, column) ~= 0, 1, 'last');
        if isempty(firstSample) || lastSample - firstSample + 1 <= minimumLength
            continue;
        end
        segment = dataRaw(firstSample:lastSample, column);
        dataFiltered(firstSample:lastSample, column) = filtfilt(butterB, butterA, segment);
    end

    if showPlots
        time = (0:size(dataRaw, 1)-1) / sampleRate;
        for column = 1:size(dataRaw, 2)
            figure;
            plot(time, dataRaw(:, column), '.', time, dataFiltered(:, column), 'r');
            title(sprintf('Channel %d of %d', column, size(dataRaw, 2)));
            xlabel('Time (s)');
            legend('Raw', 'Filtered');
            grid on;
        end
    end
end
