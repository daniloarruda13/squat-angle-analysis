function markers = extractLowerBodyMarkers(markerCoordinates)
%EXTRACTLOWERBODYMARKERS Map 16 XYZ marker triplets to named fields.

    validateattributes(markerCoordinates, {'numeric'}, ...
        {'2d', 'ncols', 48, 'real', 'finite'}, mfilename, 'markerCoordinates');
    markerCoordinates = double(markerCoordinates);
    names = {'LASIS', 'RASIS', 'LPSIS', 'RPSIS', 'LTHI', 'LKNEE', ...
        'LTIB', 'LANK', 'LHEEL', 'LTOE', 'RTHI', 'RKNEE', 'RTIB', ...
        'RANK', 'RHEEL', 'RTOE'};
    for index = 1:numel(names)
        columns = (index-1)*3 + (1:3);
        markers.(names{index}) = markerCoordinates(:, columns);
    end
    markers.R_pelvis = (markers.RASIS + markers.RPSIS) / 2;
    markers.L_pelvis = (markers.LASIS + markers.LPSIS) / 2;
end
