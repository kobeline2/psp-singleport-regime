function wl = read_waterlevel(csvPath, varargin)
%READ_WATERLEVEL Read a water-level logger CSV into a clean table.
%
% wl = read_waterlevel(csvPath)
% wl = read_waterlevel(csvPath, 'depth_column', 4)
%
% The logger exports a UTF-16LE, tab-separated file with a one-line header
% and occasionally mixed CR / CRLF / LF line endings. Column 4 holds the
% current water level in mm. This reader normalizes the line endings,
% skips the header, and extracts the numeric depth column.
%
% Output table columns:
%   sample_idx : 1..N running index of valid samples
%   depth_m    : water depth in meters (logger mm value / 1000)
%
% Notes:
%   - Rows whose depth cell is empty or non-numeric are skipped.
%   - The logger time column is intentionally NOT parsed here: its
%     mm:ss.s format wraps hourly and sampling is regular, so downstream
%     code aligns the series to the PIV frame grid by normalized time
%     (co-extensive recording) rather than by absolute logger time.

    p = inputParser;
    p.addParameter('depth_column', 4, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.parse(varargin{:});
    prm = p.Results;

    if ~isfile(csvPath)
        error('read_waterlevel:FileNotFound', ...
            'Water-level CSV not found: %s', char(csvPath));
    end

    % Decode UTF-16 at the byte level. fileread's 'Encoding' does not accept
    % a UTF-16 name in this MATLAB, so read raw bytes, drop the byte-order
    % mark, and typecast. The logger writes little-endian (BOM FF FE).
    fid = fopen(csvPath, 'r');
    if fid < 0
        error('read_waterlevel:OpenFailed', 'Could not open %s', char(csvPath));
    end
    bytes = fread(fid, Inf, '*uint8');
    fclose(fid);

    isBE = numel(bytes) >= 2 && bytes(1) == 254 && bytes(2) == 255;   % FE FF
    isLE = numel(bytes) >= 2 && bytes(1) == 255 && bytes(2) == 254;   % FF FE
    if isBE || isLE
        bytes = bytes(3:end);   % strip BOM
    end
    if mod(numel(bytes), 2) == 1
        bytes(end+1) = 0;       % pad to a whole number of UTF-16 units
    end
    if isBE
        bytes = reshape(bytes, 2, []);
        bytes = flipud(bytes);  % swap to little-endian for typecast
        bytes = bytes(:);
    end
    raw = char(typecast(bytes(:), 'uint16').');

    % Normalize CRLF / CR / LF to a single LF so line splitting is robust
    % across the logger's inconsistent line terminators.
    raw = regexprep(raw, '\r\n|\r|\n', newline);
    lines = strsplit(raw, newline, 'CollapseDelimiters', false);

    depth_mm = nan(numel(lines), 1);
    cnt = 0;
    tab = sprintf('\t');
    for i = 2:numel(lines)   % line 1 is the header
        ln = lines{i};
        if isempty(strtrim(ln))
            continue;
        end
        parts = strsplit(ln, tab, 'CollapseDelimiters', false);
        if numel(parts) < prm.depth_column
            continue;
        end
        val = str2double(strtrim(parts{prm.depth_column}));
        if isfinite(val)
            cnt = cnt + 1;
            depth_mm(cnt) = val;
        end
    end

    if cnt == 0
        error('read_waterlevel:NoData', ...
            'No numeric depth values parsed from %s (depth_column = %d).', ...
            char(csvPath), prm.depth_column);
    end

    depth_m = depth_mm(1:cnt) / 1000;
    sample_idx = (1:cnt).';
    wl = table(sample_idx, depth_m);
end
