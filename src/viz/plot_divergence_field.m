function fig = plot_divergence_field(D, X, Y, varargin)
%PLOT_DIVERGENCE_FIELD Map of surface horizontal divergence D = du/dx + dv/dy.
%
% Diverging, zero-centered colormap:
%   warm (red)  = D > 0 = divergence = upwelling   (湧き上がり)
%   cold (blue) = D < 0 = convergence = downwelling (沈み込み)
%   white       = D ~ 0
%
% Usage:
%   fig = plot_divergence_field(div.D_mean, div.x, div.y, 'title_str', "R0009 mean")
%
% Inputs:
%   D   [Ny x Nx]  divergence field (e.g. div.D_mean) [1/s]
%   X   [Ny x Nx]  x grid [m]
%   Y   [Ny x Nx]  y grid [m]
%
% Parameters:
%   title_str        Figure title. Default = "".
%   clim_percentile  Symmetric color limit set at this percentile of |D|,
%                    to keep a few outliers from washing out the map.
%                    Default = 98. Set [] to use max(|D|).
%   clim             Explicit [-L L] color limits; overrides clim_percentile.
%   figure_position  [left bottom width height]. Default = [100 100 760 520].

    p = inputParser;
    p.addRequired('D', @(x) isnumeric(x) && ismatrix(x));
    p.addRequired('X', @(x) isnumeric(x));
    p.addRequired('Y', @(x) isnumeric(x));
    p.addParameter('title_str', "", @(x) ischar(x) || isstring(x));
    p.addParameter('clim_percentile', 98, ...
        @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0 && x <= 100));
    p.addParameter('clim', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));
    p.addParameter('figure_position', [100 100 760 520], ...
        @(x) isnumeric(x) && numel(x) == 4);
    p.parse(D, X, Y, varargin{:});
    prm = p.Results;

    L = iResolveSymmetricLimit(D, prm.clim, prm.clim_percentile);

    fig = figure('Color', 'w', 'Position', prm.figure_position);
    ax = axes(fig);

    pcolor(ax, X, Y, D);
    shading(ax, 'interp');
    axis(ax, 'equal');
    axis(ax, 'tight');
    colormap(ax, iDivergingColormap(256));
    clim(ax, [-L L]);

    cb = colorbar(ax);
    cb.Label.String = 'Divergence D = \partial u/\partial x + \partial v/\partial y  [1/s]';

    xlabel(ax, 'x [m]');
    ylabel(ax, 'y [m]');
    if strlength(string(prm.title_str)) > 0
        title(ax, string(prm.title_str), 'Interpreter', 'none');
    end

    % Annotate the physical reading of the colors.
    subtitle(ax, 'warm: divergence / upwelling      cold: convergence / downwelling');

    box(ax, 'on');
end

function L = iResolveSymmetricLimit(D, climExplicit, pct)
    if ~isempty(climExplicit)
        L = max(abs(climExplicit));
        return;
    end
    vals = abs(D(isfinite(D)));
    if isempty(vals)
        L = 1;
        return;
    end
    if isempty(pct)
        L = max(vals);
    else
        L = prctile(vals, pct);
    end
    if ~(L > 0)
        L = max(vals);
    end
    if ~(L > 0)
        L = 1;   % fully zero field fallback
    end
end

function cmap = iDivergingColormap(n)
% Blue -> white -> red diverging colormap (no toolbox dependency).
    if nargin < 1, n = 256; end
    half = floor(n / 2);
    blue = [0.230 0.299 0.754];
    white = [0.95 0.95 0.95];
    red = [0.706 0.016 0.150];

    lower = iLerp(blue, white, half);
    upper = iLerp(white, red, n - half);
    cmap = [lower; upper];
end

function seg = iLerp(c1, c2, m)
    t = linspace(0, 1, m).';
    seg = (1 - t) * c1 + t * c2;
end
