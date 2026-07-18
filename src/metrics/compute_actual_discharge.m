function q_actual_Lps = compute_actual_discharge(frameTime_s, frameDepth_m, Aplan_m2, varargin)
%COMPUTE_ACTUAL_DISCHARGE Estimate actual discharge from the depth signal.
%
% q_actual_Lps = compute_actual_discharge(frameTime_s, frameDepth_m, Aplan_m2)
% q_actual_Lps = compute_actual_discharge(..., 'smooth_window_s', 20)
%
% For a closed basin filled/drained through the port, volume conservation
% gives Q = A_plan * |dh/dt|. The logger records depth at 1 mm resolution,
% so over one PIV interval the true change is far below one quantization
% step and a raw finite difference is almost all zeros with occasional
% 1 mm jumps. The depth signal is therefore smoothed over a time window
% (default 20 s) before differentiation.
%
% Inputs:
%   frameTime_s  : [N x 1] frame times in seconds (monotonic).
%   frameDepth_m : [N x 1] water depth per frame (meters), from
%                  assign_depth_bands.
%   Aplan_m2     : basin plan area in m^2 (constants: C.basin.Aplan_m2).
%
% Name-value:
%   'smooth_window_s' : smoothing window in seconds (default 20).
%
% Output:
%   q_actual_Lps : [N x 1] actual discharge magnitude in L/s.

    p = inputParser;
    p.addParameter('smooth_window_s', 20, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.parse(varargin{:});
    prm = p.Results;

    frameTime_s = frameTime_s(:);
    frameDepth_m = frameDepth_m(:);
    N = numel(frameDepth_m);

    if N < 3 || ~any(isfinite(frameDepth_m))
        q_actual_Lps = NaN(N, 1);
        return;
    end

    % Median frame spacing -> window length in frames.
    dt = median(diff(frameTime_s), 'omitnan');
    if ~isfinite(dt) || dt <= 0
        q_actual_Lps = NaN(N, 1);
        return;
    end
    win = max(3, round(prm.smooth_window_s / dt));

    depthSmooth = movmean(frameDepth_m, win, 'omitnan', 'Endpoints', 'shrink');

    % Central-difference derivative on the (possibly non-uniform) time grid.
    dhdt = gradient(depthSmooth, frameTime_s);        % m/s
    q_actual_Lps = abs(dhdt) * Aplan_m2 * 1000;       % m^3/s -> L/s
end
