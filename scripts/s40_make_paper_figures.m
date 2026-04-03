clear; clc;
%% s40_make_paper_figures.m
% Generate paper-ready figures from derived metrics and canonical PIV data.
%
% This script is the single top-level entry point for figure production.

init

figureDir = cfg.RESULTS_FIG_DIR;
tableDir = cfg.RESULTS_TABLE_DIR;

if ~exist(figureDir, 'dir')
    mkdir(figureDir);
end
if ~exist(tableDir, 'dir')
    mkdir(tableDir);
end

fprintf('[s40_make_paper_figures] figures : %s\n', figureDir);
fprintf('[s40_make_paper_figures] tables  : %s\n', tableDir);

error(['s40_make_paper_figures is a consolidated placeholder. ' ...
       'Next step: implement figure builders in src/ that read the derived ' ...
       'CSV products and canonical PIV data, then write paper figures to ' ...
       'results/figures/.']);
