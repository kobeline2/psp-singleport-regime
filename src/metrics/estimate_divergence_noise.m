function sigma = estimate_divergence_noise(D, keep, useFrame)
%ESTIMATE_DIVERGENCE_NOISE Single-frame noise of the divergence field D [1/s].
%
% Usage:
%   sigma = estimate_divergence_noise(D, keep, useFrame)
%
% Inputs:
%   D         [Ny x Nx x nFrames] divergence field (compute_divergence_field).
%   keep      [Ny x Nx] logical, cells used.
%   useFrame  [nFrames x 1] logical, frames used (a steady, deep stretch where
%             the signal is smooth from frame to frame).
%
% The structure function g(k) = 0.5*mean((D(t+k) - D(t))^2) of every cell is
% extrapolated linearly to lag 0:  sigma^2 = 2 g(1) - g(2); the median over
% cells is returned. Assumptions: the noise is white between frames and the
% signal is smooth over two frame intervals. If neighbouring frames share
% images the noise is under-estimated. At most 4000 frames (from the middle
% of the selected ones) are used to bound memory.

    idx = find(useFrame(:));
    assert(numel(idx) >= 100, 'estimate_divergence_noise:NoiseFrames', ...
        'Too few frames selected to measure the noise.');
    if numel(idx) > 4000
        mid = round(numel(idx) / 2);
        idx = idx(mid - 1999:mid + 2000);
    end
    [Ny, Nx, ~] = size(D);
    X = reshape(D(:, :, idx), Ny * Nx, []);
    X = X(keep(:), :);
    g1 = 0.5 * mean((X(:, 2:end) - X(:, 1:end - 1)) .^ 2, 2, 'omitnan');
    g2 = 0.5 * mean((X(:, 3:end) - X(:, 1:end - 2)) .^ 2, 2, 'omitnan');
    sigma = sqrt(median(max(2 * g1 - g2, 0), 'omitnan'));
end
