clc; clear; close all;

%% =========================================================
%  Validation Script - F-18 SRA Hinge Moment
%  4 conditions:
%    (a) Abrupt roll doublet               M=0.72  h=25 kft
%    (b) Abrupt aileron reversal           M=0.84  h=25 kft
%    (c) Aileron reversal (half stick)     M=1.58  h=34 kft  [no sim]
%    (d) Abrupt aileron reversal (full,R)  M=1.60  h=34 kft  [no sim]
%
%  Summary filtered by BOTH Mach AND Altitude.
%  Cases C/D flight data in lbf*ft x10^3 → converted to Nm.
%  Y-axes are independent per panel for readability.
%% =========================================================

addpath("Nasa_Chak\")

%% =========================================================
%  1. Load Summary
%% =========================================================
fprintf('Loading Summary_LOOP.mat...\n');
load('../Summary_LOOP.mat', 'Summary')

%% =========================================================
%  2. Condition definitions
%% =========================================================
MACH_TOL = 0.01;
ALT_TOL  = 50;                   % metres

% Data in in-lbf to Nm
LBF_FT_X1000_TO_NM = 112.985;

MACH_A = 0.72;  ALT_A = 7620;
MACH_B = 0.84;  ALT_B = 7620;
MACH_C = 1.58;  ALT_C = 10363.2;
MACH_D = 1.60;  ALT_D = 10363.2;

%% =========================================================
%  3. Filter Summary by Mach + Altitude
%% =========================================================
filterSummary = @(M, h) Summary( ...
    abs(Summary.Mach     - M) < MACH_TOL & ...
    abs(Summary.Altitude - h) < ALT_TOL  , :);

SubA = filterSummary(MACH_A, ALT_A);
SubB = filterSummary(MACH_B, ALT_B);
SubC = filterSummary(MACH_C, ALT_C);
SubD = filterSummary(MACH_D, ALT_D);

caseLabels = {'A','B','C','D'};
caseMachs  = [MACH_A, MACH_B, MACH_C, MACH_D];
caseAlts   = [ALT_A,  ALT_B,  ALT_C,  ALT_D];
caseSubs   = {SubA, SubB, SubC, SubD};

for k = 1:4
    if isempty(caseSubs{k})
        error('No cases found for case %s (M=%.2f, h=%.0f m).', ...
              caseLabels{k}, caseMachs(k), caseAlts(k));
    end
    fprintf('Case %s (M=%.2f, h=%.0f m): %d rows\n', ...
        caseLabels{k}, caseMachs(k), caseAlts(k), height(caseSubs{k}));
end

alphas_A = unique(SubA.alpha);
alphas_B = unique(SubB.alpha);
alphas_C = unique(SubC.alpha);
alphas_D = unique(SubD.alpha);

%% =========================================================
%  4. Load CSV data
%% =========================================================
loadCSV = @(f) sortrows(readmatrix(f), 1);

% Deflections
dataA_Def = loadCSV('caseA_Deflection.csv');
dataB_Def = loadCSV('caseB_Deflection.csv');
dataC_Def = loadCSV('caseC_Deflection.csv');
dataD_Def = loadCSV('caseD_Deflection.csv');

% Simulation (A and B only)
dataA_Sim = loadCSV('caseA_Moment_Sim.csv');
dataB_Sim = loadCSV('caseB_Moment_Sim.csv');

% Flight data  –  A/B already in Nm; C/D in lbf*ft x10^3
dataA_Flt = loadCSV('caseA_Moment_Flight.csv');
dataB_Flt = loadCSV('caseB_Moment_Flight.csv');

dataC_Flt = loadCSV('caseC_Moment_Flight.csv');
dataC_Flt(:,2) = dataC_Flt(:,2) * LBF_FT_X1000_TO_NM;

dataD_Flt = loadCSV('caseD_Moment_Flight.csv');
dataD_Flt(:,2) = dataD_Flt(:,2) * LBF_FT_X1000_TO_NM;

%% =========================================================
%  5. Build common time grids
%% =========================================================
dA_t = dataA_Def(:,1);  dA_deg = dataA_Def(:,2);
dB_t = dataB_Def(:,1);  dB_deg = dataB_Def(:,2);
dC_t = dataC_Def(:,1);  dC_deg = dataC_Def(:,2);
dD_t = dataD_Def(:,1);  dD_deg = dataD_Def(:,2);

[t_A_common, FltA_on_grid, dA_deg_common] = build_common_grid(dA_t, dA_deg, dataA_Flt);
[t_B_common, FltB_on_grid, dB_deg_common] = build_common_grid(dB_t, dB_deg, dataB_Flt);
[t_C_common, FltC_on_grid, dC_deg_common] = build_common_grid(dC_t, dC_deg, dataC_Flt);
[t_D_common, FltD_on_grid, dD_deg_common] = build_common_grid(dD_t, dD_deg, dataD_Flt);

%% =========================================================
%  6. Alpha sweep → best alpha (min RMS vs flight)
%% =========================================================
[rms_diff_A, mean_diff_A, alpha_best_A, rms_min_A] = ...
    sweep_alpha(SubA, alphas_A, dA_deg_common, FltA_on_grid);
[rms_diff_B, mean_diff_B, alpha_best_B, rms_min_B] = ...
    sweep_alpha(SubB, alphas_B, dB_deg_common, FltB_on_grid);
[rms_diff_C, mean_diff_C, alpha_best_C, rms_min_C] = ...
    sweep_alpha(SubC, alphas_C, dC_deg_common, FltC_on_grid);
[rms_diff_D, mean_diff_D, alpha_best_D, rms_min_D] = ...
    sweep_alpha(SubD, alphas_D, dD_deg_common, FltD_on_grid);

fprintf('\nBest alpha summary:\n');
fprintf('  Case A (M=%.2f, h=25 kft): alpha=%.1f deg  RMS=%.2f Nm\n', MACH_A, alpha_best_A, rms_min_A);
fprintf('  Case B (M=%.2f, h=25 kft): alpha=%.1f deg  RMS=%.2f Nm\n', MACH_B, alpha_best_B, rms_min_B);
fprintf('  Case C (M=%.2f, h=34 kft): alpha=%.1f deg  RMS=%.2f Nm\n', MACH_C, alpha_best_C, rms_min_C);
fprintf('  Case D (M=%.2f, h=34 kft): alpha=%.1f deg  RMS=%.2f Nm\n\n', MACH_D, alpha_best_D, rms_min_D);

%% =========================================================
%  7. Interpolate moments at best alpha (full deflection vectors)
%% =========================================================
[MT_a_dyn, MR_a_dyn] = interp_moment(SubA, alpha_best_A, dA_deg);
[MT_b_dyn, MR_b_dyn] = interp_moment(SubB, alpha_best_B, dB_deg);
[MT_c_dyn, MR_c_dyn] = interp_moment(SubC, alpha_best_C, dC_deg);
[MT_d_dyn, MR_d_dyn] = interp_moment(SubD, alpha_best_D, dD_deg);

%% =========================================================
%  8. Figure 1 – 2x4 tiled layout
%     Row 1: Deflection   |   Row 2: Hinge moment
%     Y-axes are INDEPENDENT per panel
%% =========================================================
figure('Color','w','Position',[40 40 1800 860], ...
       'Name','Hinge Moment - 4 conditions');

tiledlayout(2,4,'TileSpacing','compact','Padding','loose');

cFlt     = [0.10 0.20 0.85];
cSim     = [0.50 0.50 0.50];
cTornado = [0.85 0.20 0.10];
cRoskam  = [0.10 0.65 0.10];

LW_flt = 2.4;  LW_sim = 2.0;  LW_mod = 2.0;
FS_title = 10; FS_axis = 9;   FS_lgd  = 8.5;

deflMeta = { ...
    dA_t, dA_deg, MACH_A, 25, alpha_best_A, rms_min_A, 'abrupt roll doublet',            '(a)'; ...
    dB_t, dB_deg, MACH_B, 25, alpha_best_B, rms_min_B, 'abrupt aileron reversal',         '(b)'; ...
    dC_t, dC_deg, MACH_C, 34, alpha_best_C, rms_min_C, 'aileron reversal (half stick)',   '(c)'; ...
    dD_t, dD_deg, MACH_D, 34, alpha_best_D, rms_min_D, 'abrupt ail. reversal (full, R)', '(d)'};

% --- Row 1: Deflections --------------------------------------------------
axDef = gobjects(4,1);
for k = 1:4
    t_k   = deflMeta{k,1};
    deg_k = deflMeta{k,2};
    M_k   = deflMeta{k,3};
    h_k   = deflMeta{k,4};
    ab_k  = deflMeta{k,5};
    rm_k  = deflMeta{k,6};
    desc  = deflMeta{k,7};
    lbl   = deflMeta{k,8};

    axDef(k) = nexttile(k);
    plot(t_k, deg_k, 'Color', cFlt, 'LineWidth', LW_flt);
    grid on; box on;
    ylabel('Deflection (deg)');
    xlabel('Time (s)');
    xlim([t_k(1) t_k(end)]);
    % Y-axis auto-sAllcaled independently
    title(axDef(k), ...
        {sprintf('%s Deflection – %s', lbl, desc), ...
         sprintf('M=%.2f, h=%d kft  [best \\alpha=%.1f°, RMS=%.1f Nm]', ...
                 M_k, h_k, ab_k, rm_k)}, ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
end

% --- Row 2: Hinge moments ------------------------------------------------
%  Each panel gets its own y-axis (no sync).
%  Cases A & B: Flight + Sim + Tornado + Roskam
%  Cases C & D: Flight        + Tornado + Roskam

momMeta = { ...
    dA_t, dataA_Flt, dataA_Sim, MT_a_dyn, MR_a_dyn, MACH_A, 25, '(a)', true; ...
    dB_t, dataB_Flt, dataB_Sim, MT_b_dyn, MR_b_dyn, MACH_B, 25, '(b)', true; ...
    dC_t, dataC_Flt, [],        MT_c_dyn, MR_c_dyn, MACH_C, 34, '(c)', false; ...
    dD_t, dataD_Flt, [],        MT_d_dyn, MR_d_dyn, MACH_D, 34, '(d)', false};

axMom    = gobjects(4,1);
lgd_h    = cell(4,1);   % legend handles
lgd_n    = cell(4,1);   % legend names

for k = 1:4
    t_k    = momMeta{k,1};
    fltD   = momMeta{k,2};
    simD   = momMeta{k,3};
    MT_k   = momMeta{k,4};
    MR_k   = momMeta{k,5};
    M_k    = momMeta{k,6};
    h_k    = momMeta{k,7};
    lbl    = momMeta{k,8};
    hasSim = momMeta{k,9};

    axMom(k) = nexttile(k+4);
    hold on; grid on; box on;

    hh = gobjects(0);
    hn = {};

    if hasSim
        hS = plot(simD(:,1), simD(:,2), '-', ...
                  'Color', cSim, 'LineWidth', LW_sim);
        hh(end+1) = hS;  hn{end+1} = 'Chakraborty Sim';
    end

    hF = plot(fltD(:,1), fltD(:,2), '-', ...
              'Color', cFlt, 'LineWidth', LW_flt);
    hh(end+1) = hF;  hn{end+1} = 'NASA Flight';

    hT = plot(t_k, MT_k, '-', 'Color', cTornado, 'LineWidth', LW_mod);
    hh(end+1) = hT;  hn{end+1} = 'Tornado';

    hR = plot(t_k, MR_k, '-', 'Color', cRoskam,  'LineWidth', LW_mod);
    hh(end+1) = hR;  hn{end+1} = 'Roskam';

    ylabel('Hinge Moment (Nm)');
    xlabel('Time (s)');
    xlim([t_k(1) t_k(end)]);
    % Y-axis auto-scaled independently – no ylim override

    title(axMom(k), ...
        {sprintf('%s Hinge moment  M=%.2f, h=%d kft', lbl, M_k, h_k), ...
         'Flight vs static methods'}, ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','none');

    legend(hh, hn, 'Location','best','FontSize',FS_lgd,'Box','off');

    lgd_h{k} = hh;
    lgd_n{k} = hn;
end

set([axDef; axMom], 'FontSize',FS_axis,'LineWidth',0.9, ...
    'TitleFontSizeMultiplier',1.0,'LabelFontSizeMultiplier',1.0);

sgtitle('F-18 SRA Hinge Moment Estimation – 4 Flight Conditions', ...
    'FontSize',16,'FontWeight','bold');

%% =========================================================
%  9. Figure 2 – Error vs alpha (2x2, independent Y-axes)
%% =========================================================
figure('Color','w','Position',[100 100 1200 900], ...
       'Name','Tornado vs Flight: Error vs Alpha');

tiledlayout(2,2,'TileSpacing','loose','Padding','loose');

errMeta = { ...
    alphas_A, rms_diff_A, mean_diff_A, alpha_best_A, rms_min_A, ...
        MACH_A, 25, 'roll doublet',           '(a)'; ...
    alphas_B, rms_diff_B, mean_diff_B, alpha_best_B, rms_min_B, ...
        MACH_B, 25, 'aileron reversal',        '(b)'; ...
    alphas_C, rms_diff_C, mean_diff_C, alpha_best_C, rms_min_C, ...
        MACH_C, 34, 'reversal (half stick)',   '(c)'; ...
    alphas_D, rms_diff_D, mean_diff_D, alpha_best_D, rms_min_D, ...
        MACH_D, 34, 'reversal (full, right)',  '(d)'};

cPanel = { [0.85 0.20 0.10], [0.10 0.45 0.85], ...
           [0.55 0.10 0.75], [0.10 0.65 0.10] };
MS = 9;

axErr = gobjects(4,1);
for k = 1:4
    alphas_k = errMeta{k,1};
    rms_k    = errMeta{k,2};
    mean_k   = errMeta{k,3};
    ab_k     = errMeta{k,4};
    rm_k     = errMeta{k,5};
    M_k      = errMeta{k,6};
    h_k      = errMeta{k,7};
    desc     = errMeta{k,8};
    lbl      = errMeta{k,9};
    c        = cPanel{k};

    axErr(k) = nexttile(k);
    hold on; grid on; box on;

    yline(0,'--','LineWidth',1.5,'Color',[0.4 0.4 0.4], ...
          'DisplayName','Ideal (Zero Difference)');

    plot(alphas_k, mean_k, '-o', ...
        'Color', c, 'LineWidth', 2.2, 'MarkerSize', MS, ...
        'MarkerFaceColor', c, 'DisplayName','Mean (Flight – Tornado)');

    plot(alphas_k, rms_k, '-s', ...
        'Color', c*0.7, 'LineWidth', 1.8, 'MarkerSize', MS-1, ...
        'MarkerFaceColor', c*0.7, 'DisplayName','RMS (Flight – Tornado)');

    xline(ab_k, ':', 'Color', c, 'LineWidth', 2.0, ...
          'DisplayName', sprintf('Best \\alpha = %.1f°', ab_k));

    xlabel('\alpha  (deg)','FontSize',FS_axis);
    ylabel('\Delta M_{hinge}  (Nm)','FontSize',FS_axis,'Interpreter','tex');
    title(axErr(k), ...
        {sprintf('%s Flight – Tornado  vs  \\alpha', lbl), ...
         sprintf('M=%.2f, h=%d kft  (%s)', M_k, h_k, desc)}, ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
    legend('Location','best','FontSize',FS_lgd,'Box','off','Interpreter','tex');
    % Y-axis independent per panel

    if numel(alphas_k) <= 12
        for ia = 1:numel(alphas_k)
            text(alphas_k(ia), mean_k(ia), ...
                sprintf('  %.1f°', alphas_k(ia)), ...
                'FontSize',8,'Color',c,'VerticalAlignment','bottom');
        end
    end
end

set(axErr,'FontSize',FS_axis,'LineWidth',0.9, ...
    'TitleFontSizeMultiplier',1.0,'LabelFontSizeMultiplier',1.0);

sgtitle('Tornado Method Accuracy vs Angle of Attack – 4 Conditions', ...
    'FontSize',16,'FontWeight','bold');

%% =========================================================
%  10. Error table for LaTeX
%% =========================================================
calc_err = @(ref, est) deal(rms(ref - est), mean(abs(ref - est)));

% Case A
SimA_grid         = interp1(dataA_Sim(:,1), dataA_Sim(:,2), t_A_common, 'linear');
[MT_a_g, MR_a_g]  = interp_moment(SubA, alpha_best_A, dA_deg_common);
[rms_T_A, mae_T_A] = calc_err(FltA_on_grid, MT_a_g);
[rms_R_A, mae_R_A] = calc_err(FltA_on_grid, MR_a_g);
[rms_S_A, mae_S_A] = calc_err(FltA_on_grid, SimA_grid);

% Case B
SimB_grid         = interp1(dataB_Sim(:,1), dataB_Sim(:,2), t_B_common, 'linear');
[MT_b_g, MR_b_g]  = interp_moment(SubB, alpha_best_B, dB_deg_common);
[rms_T_B, mae_T_B] = calc_err(FltB_on_grid, MT_b_g);
[rms_R_B, mae_R_B] = calc_err(FltB_on_grid, MR_b_g);
[rms_S_B, mae_S_B] = calc_err(FltB_on_grid, SimB_grid);

% Case C (no sim)
[MT_c_g, MR_c_g]  = interp_moment(SubC, alpha_best_C, dC_deg_common);
[rms_T_C, mae_T_C] = calc_err(FltC_on_grid, MT_c_g);
[rms_R_C, mae_R_C] = calc_err(FltC_on_grid, MR_c_g);

% Case D (no sim)
[MT_d_g, MR_d_g]  = interp_moment(SubD, alpha_best_D, dD_deg_common);
[rms_T_D, mae_T_D] = calc_err(FltD_on_grid, MT_d_g);
[rms_R_D, mae_R_D] = calc_err(FltD_on_grid, MR_d_g);

sep = repmat('=', 1, 80);
fprintf('\n%s\n', sep);
fprintf('VALORI PER TABELLA LATEX  [Nm]:\n');
fprintf('Colonne: A_RMS | A_MAE | B_RMS | B_MAE | C_RMS | C_MAE | D_RMS | D_MAE\n');
fprintf('%s\n', sep);
fprintf('%-26s & %6.2f & %6.2f & %6.2f & %6.2f & %6.2f & %6.2f & %6.2f & %6.2f \\\\\n', ...
    'Tornado (best $\alpha$)', ...
    rms_T_A, mae_T_A, rms_T_B, mae_T_B, rms_T_C, mae_T_C, rms_T_D, mae_T_D);
fprintf('%-26s & %6.2f & %6.2f & %6.2f & %6.2f & %6.2f & %6.2f & %6.2f & %6.2f \\\\\n', ...
    'Roskam (best $\alpha$)', ...
    rms_R_A, mae_R_A, rms_R_B, mae_R_B, rms_R_C, mae_R_C, rms_R_D, mae_R_D);
fprintf('%-26s & %6.2f & %6.2f & %6.2f & %6.2f & %6s & %6s & %6s & %6s \\\\\n', ...
    'Chakraborty Sim', ...
    rms_S_A, mae_S_A, rms_S_B, mae_S_B, 'N/A','N/A','N/A','N/A');
fprintf('%s\n\n', sep);

fprintf('Validation complete.\n');
fprintf('  Figure 1: Hinge moment time-series (4 conditions, independent y-axes)\n');
fprintf('  Figure 2: Tornado vs Flight error vs alpha (4 panels, independent y-axes)\n');

%% =========================================================
%  LOCAL FUNCTIONS
%% =========================================================

function [t_common, Flt_on_grid, deg_common] = ...
        build_common_grid(def_t, def_deg, fltData)
% Shared time grid between deflection and flight vectors.
% Handles duplicate time stamps in flight data via unique().

    % Remove duplicate time entries (keep last occurrence)
    [flt_t_u, iu]  = unique(fltData(:,1), 'last');
    flt_y_u        = fltData(iu, 2);

    t_lo        = max(def_t(1),   flt_t_u(1));
    t_hi        = min(def_t(end), flt_t_u(end));
    t_common    = def_t(def_t >= t_lo & def_t <= t_hi);
    Flt_on_grid = interp1(flt_t_u, flt_y_u, t_common, 'linear');
    deg_common  = interp1(def_t,   def_deg,  t_common, 'linear');
end

function [MT_dyn, MR_dyn] = interp_moment(SubX, alpha_query, deg_vec)
% Interpolate Tornado and Roskam moments at a given alpha and
% deflection time-series using the parametric lookup table SubX.

    [~, idx_a]    = min(abs(SubX.alpha - alpha_query));
    best_alpha    = SubX.alpha(idx_a);
    rows          = SubX(SubX.alpha == best_alpha, :);
    [delta_s, is] = sort(rows.delta);
    MT_s          = rows.M_Tornado(is);
    MR_s          = rows.Ma_Roskam(is);
    deg_clamped   = max(min(deg_vec, max(delta_s)), min(delta_s));
    MT_dyn        = interp1(delta_s, MT_s, deg_clamped, 'linear');
    MR_dyn        = interp1(delta_s, MR_s, deg_clamped, 'linear');
end

function [rms_v, mean_v, best_alpha, rms_min] = ...
        sweep_alpha(Sub, alphas, deg_common, Flt_on_grid)
% Sweep alpha values and find the one minimising RMS vs flight.

    n      = numel(alphas);
    rms_v  = zeros(n,1);
    mean_v = zeros(n,1);
    for ia = 1:n
        [MT_tmp, ~] = interp_moment(Sub, alphas(ia), deg_common);
        diff_tmp    = Flt_on_grid - MT_tmp;
        rms_v(ia)   = rms(diff_tmp);
        mean_v(ia)  = mean(diff_tmp);
    end
    [rms_min, idx_best] = min(rms_v);
    best_alpha = alphas(idx_best);
end