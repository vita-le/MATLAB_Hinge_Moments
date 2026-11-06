clc; clear; close all;

%% =========================================================
%  1. Load Static Data & Filter by Alpha
%% =========================================================
addpath("Nasa_Chak\")

% ---------------------------------------------------------
% LOAD OTTIMIZZATO
% ---------------------------------------------------------
tic

% Carica SOLO la variabile necessaria
S = load('../Results_LOOP.mat', 'Results');
Results = S.Results;
clear S

fprintf('File .mat loaded in %.2f s\n', toc);

% ---------------------------------------------------------
% PREALLOCATION (molto più veloce)
% ---------------------------------------------------------
N = numel(Results);

Machs            = zeros(1,N);
Alts             = zeros(1,N);
Alphas           = zeros(1,N);
Deflections      = zeros(1,N);
Moments_Tornado  = zeros(1,N);
Moments_Roskam   = zeros(1,N);

% ---------------------------------------------------------
% LOOP VELOCE
% Evita arrayfun e concatenazioni strutture lente
% ---------------------------------------------------------
tic

for i = 1:N

    r = Results(i);

    inp = r.Inputs;

    Machs(i)       = inp.Mach;
    Alts(i)        = inp.Altitude;
    Alphas(i)      = inp.alpha;
    Deflections(i) = inp.delta;

    Moments_Tornado(i) = r.Tornado.Hinge.M(1);
    Moments_Roskam(i)  = r.Roskam_Hinge.Ma;

end

fprintf('Data extraction completed in %.2f s\n', toc);

% Libera memoria
clear Results r inp

% ---------------------------------------------------------
% SELEZIONE UTENTE
% ---------------------------------------------------------
target_alpha = input('Alpha to inspect the two conditions: ');

if ischar(target_alpha) || isstring(target_alpha)
    target_alpha = str2double(target_alpha);
end

% ---------------------------------------------------------
% CASE DEFINITIONS
% ---------------------------------------------------------
m_A = 0.72;
h_A = 7620;

m_B = 0.85;
h_B = 7620;

% ---------------------------------------------------------
% LOGICAL MASKS
% ---------------------------------------------------------
mask_alpha = abs(Alphas - target_alpha) < 0.1;

mask_A = mask_alpha & ...
         abs(Machs - m_A) < 0.01 & ...
         abs(Alts  - h_A) < 1;

mask_B = mask_alpha & ...
         abs(Machs - m_B) < 0.01 & ...
         abs(Alts  - h_B) < 1;

% ---------------------------------------------------------
% CASE A
% ---------------------------------------------------------
delta_a = Deflections(mask_A);
MT_a    = Moments_Tornado(mask_A);
MR_a    = Moments_Roskam(mask_A);

% ---------------------------------------------------------
% CASE B
% ---------------------------------------------------------
delta_b = Deflections(mask_B);
MT_b    = Moments_Tornado(mask_B);
MR_b    = Moments_Roskam(mask_B);

% ---------------------------------------------------------
% CHECK
% ---------------------------------------------------------
if isempty(delta_a) || isempty(delta_b)

    error(['No data found for Alpha = %.1f\n' ...
           'Check Mach/Altitude/Alpha values in LOOP.'], ...
           target_alpha);

end

% ---------------------------------------------------------
% SORT FOR INTERPOLATION
% ---------------------------------------------------------
[delta_a_s, ia] = sort(delta_a);
MT_a_s = MT_a(ia);
MR_a_s = MR_a(ia);

[delta_b_s, ib] = sort(delta_b);
MT_b_s = MT_b(ib);
MR_b_s = MR_b(ib);

%% =========================================================
%  2. Load Digital Data (CSV)
%% =========================================================

tic

loadData = @(f) sortrows(readmatrix(f), 1);

dataA_Def = loadData('caseA_Deflection.csv');
dataA_Sim = loadData('caseA_Moment_Sim.csv');
dataA_Flt = loadData('caseA_Moment_Flight.csv');

dataB_Def = loadData('caseB_Deflection.csv');
dataB_Sim = loadData('caseB_Moment_Sim.csv');
dataB_Flt = loadData('caseB_Moment_Flight.csv');

fprintf('CSV data loaded in %.2f s\n', toc);

%% =========================================================
%  3. Interpolation
%% =========================================================

% ---------------------------------------------------------
% CASE A
% ---------------------------------------------------------
dA_t   = dataA_Def(:,1);
dA_deg = dataA_Def(:,2);

% Saturation
dA_deg_sat = min(max(dA_deg, delta_a_s(1)), delta_a_s(end));

MT_a_dyn = interp1(delta_a_s, MT_a_s, dA_deg_sat, ...
                   'linear', 'extrap');

MR_a_dyn = interp1(delta_a_s, MR_a_s, dA_deg_sat, ...
                   'linear', 'extrap');

% ---------------------------------------------------------
% CASE B
% ---------------------------------------------------------
dB_t   = dataB_Def(:,1);
dB_deg = dataB_Def(:,2);

dB_deg_sat = min(max(dB_deg, delta_b_s(1)), delta_b_s(end));

MT_b_dyn = interp1(delta_b_s, MT_b_s, dB_deg_sat, ...
                   'linear', 'extrap');

MR_b_dyn = interp1(delta_b_s, MR_b_s, dB_deg_sat, ...
                   'linear', 'extrap');

%% =========================================================
%  4. Figure (TILED LAYOUT)
%% =========================================================

figure('Color','w', ...
       'Position',[80 80 1250 820], ...
       'Name', sprintf('Hinge Moment Validation - Alpha %.1f', target_alpha));

t = tiledlayout(2,2, ...
                'TileSpacing','loose', ...
                'Padding','loose');

% ---------------------------------------------------------
% STYLE
% ---------------------------------------------------------
cFlt      = [0.10 0.20 0.85];
cSim      = [0.50 0.50 0.50];
cTornado  = [0.85 0.20 0.10];
cRoskam   = [0.10 0.65 0.10];

LW_flt = 2.6;
LW_sim = 2.2;
LW_mod = 2.2;

FS_title = 11;
FS_axis  = 10;
FS_lgd   = 9;

%% =========================================================
%  (a) Deflection A
%% =========================================================
ax1 = nexttile(1);

plot(dA_t, dA_deg, ...
    'Color', cFlt, ...
    'LineWidth', LW_flt);

grid on

ylabel('Aileron Deflection (deg)');
xlabel('Time (s)');

title(ax1, ...
    {sprintf('(a) Case A: M = %.2f, Alpha = %.1f', ...
    m_A, target_alpha), ...
    'Abrupt roll doublet'}, ...
    'FontSize', FS_title, ...
    'FontWeight', 'bold');

%% =========================================================
%  (b) Deflection B
%% =========================================================
ax2 = nexttile(2);

plot(dB_t, dB_deg, ...
    'Color', cFlt, ...
    'LineWidth', LW_flt);

grid on

ylabel('Aileron Deflection (deg)');
xlabel('Time (s)');

title(ax2, ...
    {sprintf('(b) Case B: M = %.2f, Alpha = %.1f', ...
    m_B, target_alpha), ...
    'Abrupt aileron reversal'}, ...
    'FontSize', FS_title, ...
    'FontWeight', 'bold');

%% =========================================================
%  (c) Moment A
%% =========================================================
ax3 = nexttile(3);

hold on
grid on
box on

hSim = plot(dataA_Sim(:,1), dataA_Sim(:,2), '-', ...
    'Color', cSim, ...
    'LineWidth', LW_sim);

hFlt = plot(dataA_Flt(:,1), dataA_Flt(:,2), '-', ...
    'Color', cFlt, ...
    'LineWidth', LW_flt);

hTor = plot(dA_t, MT_a_dyn, '--', ...
    'Color', cTornado, ...
    'LineWidth', LW_mod);

hRos = plot(dA_t, MR_a_dyn, '--', ...
    'Color', cRoskam, ...
    'LineWidth', LW_mod);

ylabel('Hinge Moment (Nm)');
xlabel('Time (s)');

title(ax3, ...
    '(c) Hinge moment comparison - Case A', ...
    'FontSize', FS_title, ...
    'FontWeight', 'bold');

%% =========================================================
%  (d) Moment B
%% =========================================================
ax4 = nexttile(4);

hold on
grid on
box on

plot(dataB_Sim(:,1), dataB_Sim(:,2), '-', ...
    'Color', cSim, ...
    'LineWidth', LW_sim);

plot(dataB_Flt(:,1), dataB_Flt(:,2), '-', ...
    'Color', cFlt, ...
    'LineWidth', LW_flt);

plot(dB_t, MT_b_dyn, '--', ...
    'Color', cTornado, ...
    'LineWidth', LW_mod);

plot(dB_t, MR_b_dyn, '--', ...
    'Color', cRoskam, ...
    'LineWidth', LW_mod);

ylabel('Hinge Moment (Nm)');
xlabel('Time (s)');

title(ax4, ...
    '(d) Hinge moment comparison - Case B', ...
    'FontSize', FS_title, ...
    'FontWeight', 'bold');

%% =========================================================
%  AXIS SYNC
%% =========================================================
y_mom = [ ...
    min([ylim(ax3), ylim(ax4)]), ...
    max([ylim(ax3), ylim(ax4)]) ...
    ];

ylim(ax3, y_mom);
ylim(ax4, y_mom);

%% =========================================================
%  FINAL FORMATTING
%% =========================================================
set([ax1 ax2 ax3 ax4], 'FontSize', FS_axis);

lgd = legend(ax3, ...
    [hSim hFlt hTor hRos], ...
    {'Chakraborty Sim', ...
     'NASA Flight', ...
     'Tornado (Static)', ...
     'Roskam (Static)'}, ...
    'FontSize', FS_lgd, ...
    'Orientation', 'horizontal', ...
    'Box', 'off');

lgd.Layout.Tile = 'south';

sgtitle( ...
    sprintf(['F-18 SRA Hinge Moment: ' ...
    'Static Methods vs Flight Data ' ...
    '(Alpha = %.1f)'], target_alpha), ...
    'FontSize', 16, ...
    'FontWeight', 'bold');