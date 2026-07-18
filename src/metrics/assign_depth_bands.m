function [depth_m, h_over_a, band_id] = assign_depth_bands(frameTime_s, waterDepth_m, a_m, bands)
%ASSIGN_DEPTH_BANDS Map PIV frame times to water depth, h/a, and a depth band.
%
% [depth_m, h_over_a, band_id] = assign_depth_bands(frameTime_s, ...
%       waterDepth_m, a_m, bands)
%
% Inputs:
%   frameTime_s  : [Nf x 1] time of each PIV frame (seconds, from
%                  frame_metrics.time_s). Used only for its relative shape.
%   waterDepth_m : [Nw x 1] water-level series (meters), one value per
%                  logger sample, ordered in acquisition order.
%   a_m          : port height in meters (relative-submergence scale).
%   bands        : table from metadata/depth_bands.csv with columns
%                  band_id, h_min_m, h_max_m (rows ordered shallow -> deep).
%
% Outputs (all [Nf x 1]):
%   depth_m   : water depth interpolated onto each PIV frame
%   h_over_a  : depth_m / a_m
%   band_id   : string band label per frame ("" if outside all bands)
%
% Alignment:
%   The logger and the video are co-extensive recordings of the same run
%   (verified: the water CSV length matches the video length), so the two
%   series are aligned by NORMALIZED time. Sample i of Nw maps to
%   (i-1)/(Nw-1) in [0,1]; frame k maps to the same normalized position
%   from frameTime_s, and depth is linearly interpolated. This sidesteps
%   the logger's wrapping mm:ss.s clock and its differing sample rate, and
%   is insensitive to the small head/tail video trim.

    frameTime_s = frameTime_s(:);
    waterDepth_m = waterDepth_m(:);

    Nf = numel(frameTime_s);
    Nw = numel(waterDepth_m);
    assert(Nw >= 2, 'assign_depth_bands:TooFewWaterSamples', ...
        'Need at least 2 water-level samples, got %d.', Nw);

    % Normalized [0,1] axes for both series.
    uWater = (0:Nw-1).' / (Nw - 1);

    if Nf >= 2 && (max(frameTime_s) > min(frameTime_s))
        uFrame = (frameTime_s - min(frameTime_s)) / (max(frameTime_s) - min(frameTime_s));
    else
        uFrame = zeros(Nf, 1);
    end
    uFrame = min(max(uFrame, 0), 1);

    depth_m = interp1(uWater, waterDepth_m, uFrame, 'linear');
    h_over_a = depth_m / a_m;

    % Assign a band per frame. Bands are contiguous and ordered; use a
    % half-open interval [h_min, h_max) except for the deepest band, which
    % includes its upper edge so the exact end depth is not dropped.
    band_id = strings(Nf, 1);
    nB = height(bands);
    for b = 1:nB
        lo = bands.h_min_m(b);
        hi = bands.h_max_m(b);
        if b == nB
            inBand = depth_m >= lo & depth_m <= hi;
        else
            inBand = depth_m >= lo & depth_m < hi;
        end
        band_id(inBand) = string(bands.band_id(b));
    end
end
