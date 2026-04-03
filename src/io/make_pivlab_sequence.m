function manifest = make_pivlab_sequence(srcDir, outDir, varargin)
%MAKE_PIVLAB_SEQUENCE Create a temporary sequential TIFF folder for PIVLab.
%
% Usage:
%   manifest = make_pivlab_sequence(srcDir, outDir)
%   manifest = make_pivlab_sequence(srcDir, outDir, 'frame_step', 3)
%
% Inputs
%   srcDir : source directory containing rectified TIFF sequence
%   outDir : output directory for temporary PIVLab-ready sequence
%
% Name-value pairs
%   'pattern'         : file pattern in srcDir (default = 'img_*.tif')
%   'frame_start'     : first source frame index to use, 1-based within sorted files
%   'frame_end'       : last source frame index to use, Inf = all
%   'frame_step'      : stride in source sequence (default = 1)
%   'start_index'     : first index in output filenames (default = 1000)
%   'prefix'          : output file prefix (default = 'img_')
%   'digits'          : number of digits in output numbering (default = 4)
%   'delete_existing' : delete outDir first if it exists (default = true)
%   'copy_mode'       : 'copy' or 'move' (default = 'copy')
%   'write_manifest'  : true/false (default = true)
%
% Output
%   manifest : table with mapping from source files to output files
%
% Notes
%   - Output files are renamed sequentially for PIVLab, e.g. img_1000.tif,
%     img_1001.tif, ...
%   - This folder is intended to be temporary.

    p = inputParser;
    p.addRequired('srcDir', @(x) ischar(x) || isstring(x));
    p.addRequired('outDir', @(x) ischar(x) || isstring(x));

    p.addParameter('pattern', 'img_*.tif', @(x) ischar(x) || isstring(x));
    p.addParameter('frame_start', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('frame_end', Inf, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('frame_step', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('start_index', 1000, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('prefix', 'img_', @(x) ischar(x) || isstring(x));
    p.addParameter('digits', 4, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('delete_existing', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('copy_mode', 'copy', @(x) ischar(x) || isstring(x));
    p.addParameter('write_manifest', true, @(x) islogical(x) && isscalar(x));

    p.parse(srcDir, outDir, varargin{:});
    prm = p.Results;

    srcDir = string(srcDir);
    outDir = string(outDir);
    pattern = string(prm.pattern);
    copyMode = lower(string(prm.copy_mode));

    if ~isfolder(srcDir)
        error('make_pivlab_sequence:SourceNotFound', ...
            'Source directory not found: %s', char(srcDir));
    end

    files = dir(fullfile(srcDir, char(pattern)));
    if isempty(files)
        error('make_pivlab_sequence:NoFiles', ...
            'No files found in %s matching %s', char(srcDir), char(pattern));
    end

    % Sort by filename
    [~, order] = sort({files.name});
    files = files(order);

    nFiles = numel(files);
    iStart = prm.frame_start;
    iEnd   = min(prm.frame_end, nFiles);
    iStep  = prm.frame_step;

    if iStart > iEnd
        error('make_pivlab_sequence:InvalidRange', ...
            'frame_start must be <= frame_end after truncation.');
    end

    srcIdx = iStart:iStep:iEnd;
    nOut = numel(srcIdx);

    if isfolder(outDir)
        if prm.delete_existing
            rmdir(outDir, 's');
        else
            error('make_pivlab_sequence:OutputExists', ...
                'Output directory already exists: %s', char(outDir));
        end
    end
    mkdir(outDir);

    manifest = table('Size', [nOut, 6], ...
        'VariableTypes', {'double','string','string','double','string','double'}, ...
        'VariableNames', {'source_order','source_name','output_name','output_index','output_path','frame_step'});

    fmt = sprintf('%%s%%0%dd.tif', prm.digits);

    for k = 1:nOut
        sIdx = srcIdx(k);
        srcName = string(files(sIdx).name);
        outIndex = prm.start_index + (k - 1);
        outName = string(sprintf(fmt, prm.prefix, outIndex));

        srcPath = fullfile(srcDir, srcName);
        dstPath = fullfile(outDir, outName);

        switch copyMode
            case "copy"
                copyfile(srcPath, dstPath);
            case "move"
                movefile(srcPath, dstPath);
            otherwise
                error('make_pivlab_sequence:InvalidCopyMode', ...
                    'copy_mode must be ''copy'' or ''move''.');
        end

        manifest.source_order(k) = sIdx;
        manifest.source_name(k)  = srcName;
        manifest.output_name(k)  = outName;
        manifest.output_index(k) = outIndex;
        manifest.output_path(k)  = string(dstPath);
        manifest.frame_step(k)   = iStep;
    end

    if prm.write_manifest
        writetable(manifest, fullfile(outDir, 'pivlab_sequence_manifest.csv'));
    end

    fprintf('[make_pivlab_sequence] Created %d files in %s\n', nOut, char(outDir));
end