clc; clear; close all;

%% =========================================================
%  Validation Script - F-18 SRA Hinge Moment
%  Loads lightweight Summary; always validates on
%  Mach = 0.72 (case a) and Mach = 0.85 (case b)
%  regardless of the parametric range used in the main loop.
%  Main comparison plot uses the alpha with minimum RMS
%  error against NASA flight data.
%% =========================================================

addpath("Nasa_Chak\")

%% =========================================================
%  1. Load Summary (fast) - scalar data only
%% =========================================================
fprintf('Loading Summary_LOOP.mat...\n');
load('../Summary_LOOP.mat', 'Summary')

%% =========================================================
%  2. Filter by Mach condition with tolerance
%% =========================================================
MACH_TOL = 0.01;
MACH_A   = 0.72;
MACH_B   = 0.84;

maskA = abs(Summary.Mach - MACH_A) < MACH_TOL;
maskB = abs(Summary.Mach - MACH_B) < MACH_TOL;

if ~any(maskA)
    error('No cases found for Mach = %.2f ± %.3f.', MACH_A, MACH_TOL);
end
if ~any(maskB)
    error('No cases found for Mach = %.2f ± %.3f.', MACH_B, MACH_TOL);
end

SubA = Summary(maskA, :);
SubB = Summary(maskB, :);

fprintf('Case A (Mach=%.2f): %d cases found\n', MACH_A, height(SubA));
fprintf('Case B (Mach=%.2f): %d cases found\n', MACH_B, height(SubB));

alphas_A = unique(SubA.alpha);
alphas_B = unique(SubB.alpha);

%% =========================================================
%  3. Load digital flight / simulation data (CSV)
%% =========================================================
loadCSV = @(f) sortrows(readmatrix(f), 1);

dataA_Def = loadCSV('caseA_Deflection.csv');
dataA_Sim = loadCSV('caseA_Moment_Sim.csv');
dataA_Flt = loadCSV('caseA_Moment_Flight.csv');

dataB_Def = loadCSV('caseB_Deflection.csv');
dataB_Sim = loadCSV('caseB_Moment_Sim.csv');
dataB_Flt = loadCSV('caseB_Moment_Flight.csv');

%% =========================================================
%  4. Interpolation helper
%% =========================================================
function [MT_dyn, MR_dyn] = interp_moment(SubX, alpha_query, ~, deg_vec)
    [~, idx_a]  = min(abs(SubX.alpha - alpha_query));
    best_alpha  = SubX.alpha(idx_a);
    rows        = SubX(SubX.alpha == best_alpha, :);

    [delta_s, is] = sort(rows.delta);
    MT_s = rows.M_Tornado(is);
    MR_s = rows.Ma_Roskam(is);

    deg_clamped = max(min(deg_vec, max(delta_s)), min(delta_s));

    MT_dyn = interp1(delta_s, MT_s, deg_clamped, 'linear');
    MR_dyn = interp1(delta_s, MR_s, deg_clamped, 'linear');
end

%% =========================================================
%  5. Build common time grids and resample flight data
%     (must come BEFORE the alpha loops so the best-alpha
%      selection can drive the main comparison plot)
%% =========================================================
dA_t   = dataA_Def(:,1);
dA_deg = dataA_Def(:,2);
dB_t   = dataB_Def(:,1);
dB_deg = dataB_Def(:,2);

% --- Case A common grid --------------------------------------------------
t_A_lo  = max(dA_t(1),   dataA_Flt(1,1));
t_A_hi  = min(dA_t(end), dataA_Flt(end,1));
t_A_common    = dA_t(dA_t >= t_A_lo & dA_t <= t_A_hi);
FltA_on_grid  = interp1(dataA_Flt(:,1), dataA_Flt(:,2), t_A_common, 'linear');
dA_deg_common = interp1(dA_t, dA_deg, t_A_common, 'linear');

% --- Case B common grid --------------------------------------------------
t_B_lo  = max(dB_t(1),   dataB_Flt(1,1));
t_B_hi  = min(dB_t(end), dataB_Flt(end,1));
t_B_common    = dB_t(dB_t >= t_B_lo & dB_t <= t_B_hi);
FltB_on_grid  = interp1(dataB_Flt(:,1), dataB_Flt(:,2), t_B_common, 'linear');
dB_deg_common = interp1(dB_t, dB_deg, t_B_common, 'linear');

%% =========================================================
%  6. Loop over all alphas → compute RMS and mean error
%     BEFORE drawing anything, so best alpha is known.
%% =========================================================

% --- Case A --------------------------------------------------------------
n_aA        = numel(alphas_A);
rms_diff_A  = zeros(n_aA, 1);
mean_diff_A = zeros(n_aA, 1);

for ia = 1:n_aA
    [MT_tmp, ~]     = interp_moment(SubA, alphas_A(ia), t_A_common, dA_deg_common);
    diff_tmp        = FltA_on_grid - MT_tmp;
    rms_diff_A(ia)  = rms(diff_tmp);
    mean_diff_A(ia) = mean(diff_tmp);
end

% Alpha with minimum RMS → used for the main comparison plot
[rms_min_A, idx_best_A] = min(rms_diff_A);
alpha_best_A = alphas_A(idx_best_A);

fprintf('\nCase A best alpha: %.1f deg  (RMS error = %.2f Nm)\n', ...
        alpha_best_A, rms_min_A);

% --- Case B --------------------------------------------------------------
n_aB        = numel(alphas_B);
rms_diff_B  = zeros(n_aB, 1);
mean_diff_B = zeros(n_aB, 1);

for ib = 1:n_aB
    [MT_tmp, ~]     = interp_moment(SubB, alphas_B(ib), t_B_common, dB_deg_common);
    diff_tmp        = FltB_on_grid - MT_tmp;
    rms_diff_B(ib)  = rms(diff_tmp);
    mean_diff_B(ib) = mean(diff_tmp);
end

[rms_min_B, idx_best_B] = min(rms_diff_B);
alpha_best_B = alphas_B(idx_best_B);

fprintf('Case B best alpha: %.1f deg  (RMS error = %.2f Nm)\n\n', ...
        alpha_best_B, rms_min_B);

%% =========================================================
%  7. Interpolate moments at the best alpha for Figure 1
%% =========================================================
[MT_a_dyn, MR_a_dyn] = interp_moment(SubA, alpha_best_A, dA_t, dA_deg);
[MT_b_dyn, MR_b_dyn] = interp_moment(SubB, alpha_best_B, dB_t, dB_deg);

%% =========================================================
%  8. Figure 1 - TILED LAYOUT (4-panel comparison)
%     Title shows which alpha was automatically selected.
%% =========================================================
figure('Color','w','Position',[80 80 1250 820], ...
       'Name','Hinge Moment - Static Overlay on Dynamic');

tiledlayout(2,2,'TileSpacing','loose','Padding','loose');

cFlt     = [0.10 0.20 0.85];
cSim     = [0.50 0.50 0.50];
cTornado = [0.85 0.20 0.10];
cRoskam  = [0.10 0.65 0.10];

LW_flt = 2.6;  LW_sim = 2.2;  LW_mod = 2.2;
FS_title = 11; FS_axis = 10;  FS_lgd = 9;

% (a) Deflection
ax1 = nexttile(1);
plot(dA_t, dA_deg, 'Color', cFlt, 'LineWidth', LW_flt);
grid on; box on;
ylabel('Aileron Deflection (deg)'); xlabel('Time (s)');
xlim([dA_t(1) dA_t(end)]);
title(ax1, {'(a) Deflection - abrupt roll doublet', ...
            sprintf('M = %.2f,  h = 25 kft  [best \\alpha = %.1f deg,  RMS = %.1f Nm]', ...
                    MACH_A, alpha_best_A, rms_min_A)}, ...
    'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');

% (b) Deflection
ax2 = nexttile(2);
plot(dB_t, dB_deg, 'Color', cFlt, 'LineWidth', LW_flt);
grid on; box on;
ylabel('Aileron Deflection (deg)'); xlabel('Time (s)');
xlim([dB_t(1) dB_t(end)]);
title(ax2, {'(b) Deflection - abrupt aileron reversal', ...
            sprintf('M = %.2f,  h = 25 kft  [best \\alpha = %.1f deg,  RMS = %.1f Nm]', ...
                    MACH_B, alpha_best_B, rms_min_B)}, ...
    'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');

% (c) Moment A
ax3 = nexttile(3);
hold on; grid on; box on;
hSim = plot(dataA_Sim(:,1), dataA_Sim(:,2), '-', 'Color', cSim,    'LineWidth', LW_sim);
hFlt = plot(dataA_Flt(:,1), dataA_Flt(:,2), '-', 'Color', cFlt,    'LineWidth', LW_flt);
hTor = plot(dA_t, MT_a_dyn,                 '-', 'Color', cTornado, 'LineWidth', LW_mod);
hRos = plot(dA_t, MR_a_dyn,                 '-', 'Color', cRoskam,  'LineWidth', LW_mod);
ylabel('Hinge Moment (Nm)'); xlabel('Time (s)');
xlim([dA_t(1) dA_t(end)]);
title(ax3, {'(c) Hinge moment - roll doublet', ...
            'Flight and simulation compared with static methods'}, ...
    'FontSize',FS_title,'FontWeight','bold','Interpreter','none');

% (d) Moment B
ax4 = nexttile(4);
hold on; grid on; box on;
plot(dataB_Sim(:,1), dataB_Sim(:,2), '-', 'Color', cSim,    'LineWidth', LW_sim);
plot(dataB_Flt(:,1), dataB_Flt(:,2), '-', 'Color', cFlt,    'LineWidth', LW_flt);
plot(dB_t, MT_b_dyn,                 '-', 'Color', cTornado, 'LineWidth', LW_mod);
plot(dB_t, MR_b_dyn,                 '-', 'Color', cRoskam,  'LineWidth', LW_mod);
ylabel('Hinge Moment (Nm)'); xlabel('Time (s)');
xlim([dB_t(1) dB_t(end)]);
title(ax4, {'(d) Hinge moment - aileron reversal', ...
            'Flight and simulation compared with static methods'}, ...
    'FontSize',FS_title,'FontWeight','bold','Interpreter','none');

% Sync moment Y-axes
y_mom = [min([ylim(ax3) ylim(ax4)]), max([ylim(ax3) ylim(ax4)])];
ylim(ax3, y_mom); ylim(ax4, y_mom);

set([ax1 ax2 ax3 ax4], 'FontSize',FS_axis,'LineWidth',0.9, ...
    'TitleFontSizeMultiplier',1.0,'LabelFontSizeMultiplier',1.0);

lgd = legend(ax3, [hSim hFlt hTor hRos], ...
    {'Chakraborty Sim','NASA Flight','Tornado','Roskam'}, ...
    'FontSize',FS_lgd,'Orientation','horizontal','NumColumns',4,'Box','off');
lgd.Layout.Tile = 'south';

sgtitle('F-18 SRA Hinge Moment Estimation Methods', ...
    'FontSize',18,'FontWeight','bold');

%% =========================================================
%  9. Figure 2 - Tornado vs Flight difference vs ALPHA
%% =========================================================
figure('Color','w','Position',[100 100 1100 520], ...
       'Name','Tornado vs Flight: Difference vs Alpha');

tiledlayout(1,2,'TileSpacing','loose','Padding','loose');

cA = [0.85 0.20 0.10];
cB = [0.10 0.45 0.85];
MS = 9;

% --- Panel (a): Case A ---------------------------------------------------
ax_dA = nexttile(1);
hold on; grid on; box on;

yline(0, '--', 'LineWidth', 1.5, 'Color', [0.4 0.4 0.4], ...
      'DisplayName', 'Ideal (Zero Difference)');

plot(alphas_A, mean_diff_A, '-o', ...
    'Color', cA, 'LineWidth', 2.2, 'MarkerSize', MS, ...
    'MarkerFaceColor', cA, 'DisplayName', 'Mean (Flight - Tornado)');

plot(alphas_A, rms_diff_A, '-s', ...
    'Color', cA*0.7, 'LineWidth', 1.8, 'MarkerSize', MS-1, ...
    'MarkerFaceColor', cA*0.7, 'DisplayName', 'RMS (Flight - Tornado)');

% Mark the best alpha with a vertical line
xline(alpha_best_A, ':', 'Color', cA, 'LineWidth', 2.0, ...
      'DisplayName', sprintf('Best \\alpha = %.1f°', alpha_best_A));

xlabel('\alpha  (deg)','FontSize',FS_axis);
ylabel('\Delta M_{hinge}  (Nm)','FontSize',FS_axis);
title(ax_dA, {'(a) Flight \minus Tornado difference vs \alpha', ...
              sprintf('M = %.2f,  h = 25 kft  (roll doublet)', MACH_A)}, ...
    'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
legend('Location','best','FontSize',FS_lgd,'Box','off');

if n_aA <= 12
    for ia = 1:n_aA
        text(alphas_A(ia), mean_diff_A(ia), sprintf('  %.1f°', alphas_A(ia)), ...
            'FontSize',8,'Color',cA,'VerticalAlignment','bottom');
    end
end

% --- Panel (b): Case B ---------------------------------------------------
ax_dB = nexttile(2);
hold on; grid on; box on;

yline(0, '--', 'LineWidth', 1.5, 'Color', [0.4 0.4 0.4], ...
      'DisplayName', 'Ideal (Zero Difference)');

plot(alphas_B, mean_diff_B, '-o', ...
    'Color', cB, 'LineWidth', 2.2, 'MarkerSize', MS, ...
    'MarkerFaceColor', cB, 'DisplayName', 'Mean (Flight - Tornado)');

plot(alphas_B, rms_diff_B, '-s', ...
    'Color', cB*0.7, 'LineWidth', 1.8, 'MarkerSize', MS-1, ...
    'MarkerFaceColor', cB*0.7, 'DisplayName', 'RMS (Flight - Tornado)');

xline(alpha_best_B, ':', 'Color', cB, 'LineWidth', 2.0, ...
      'DisplayName', sprintf('Best \\alpha = %.1f°', alpha_best_B));

xlabel('\alpha  (deg)','FontSize',FS_axis);
ylabel('\Delta M_{hinge}  (Nm)','FontSize',FS_axis);
title(ax_dB, {'(b) Flight \minus Tornado difference vs \alpha', ...
              sprintf('M = %.2f,  h = 25 kft  (aileron reversal)', MACH_B)}, ...
    'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
legend('Location','best','FontSize',FS_lgd,'Box','off');

if n_aB <= 12
    for ib = 1:n_aB
        text(alphas_B(ib), mean_diff_B(ib), sprintf('  %.1f°', alphas_B(ib)), ...
            'FontSize',8,'Color',cB,'VerticalAlignment','bottom');
    end
end

% Sync Y axes
y_diff = [min([ylim(ax_dA) ylim(ax_dB)]), max([ylim(ax_dA) ylim(ax_dB)])];
ylim(ax_dA, y_diff); ylim(ax_dB, y_diff);

set([ax_dA ax_dB], 'FontSize',FS_axis,'LineWidth',0.9, ...
    'TitleFontSizeMultiplier',1.0,'LabelFontSizeMultiplier',1.0);

sgtitle('Tornado Method Accuracy vs Angle of Attack', ...
    'FontSize',18,'FontWeight','bold');

fprintf('Validation plots complete.\n');
fprintf('  Figure 1: Hinge moment time-series  (alpha auto-selected by min RMS)\n');
fprintf('  Figure 2: Tornado vs Flight difference vs alpha\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% =========================================================
%  10. Calcolo Errori per Tabella LaTeX (Versione Corretta)
%% =========================================================

% Funzione anonima per RMS e MAE
calc_err = @(ref, est) deal(rms(ref - est), mean(abs(ref - est)));

% CASE A (Mach 0.72)
SimA_on_grid = interp1(dataA_Sim(:,1), dataA_Sim(:,2), t_A_common, 'linear');
[MT_a_grid, MR_a_grid] = interp_moment(SubA, alpha_best_A, t_A_common, dA_deg_common);
[rms_T_A, mae_T_A] = calc_err(FltA_on_grid, MT_a_grid);
[rms_R_A, mae_R_A] = calc_err(FltA_on_grid, MR_a_grid);
[rms_S_A, mae_S_A] = calc_err(FltA_on_grid, SimA_on_grid);

% CASE B (Mach 0.85)
SimB_on_grid = interp1(dataB_Sim(:,1), dataB_Sim(:,2), t_B_common, 'linear');
[MT_b_grid, MR_b_grid] = interp_moment(SubB, alpha_best_B, t_B_common, dB_deg_common);
[rms_T_B, mae_T_B] = calc_err(FltB_on_grid, MT_b_grid);
[rms_R_B, mae_R_B] = calc_err(FltB_on_grid, MR_b_grid);
[rms_S_B, mae_S_B] = calc_err(FltB_on_grid, SimB_on_grid);

% --- Stampa sicura (senza concatenazione con +) ---
separatore = repmat('=', 1, 50);
fprintf('\n%s\n', separatore);
fprintf('VALORI PER TABELLA LATEX:\n');
fprintf('%s\n', separatore);
fprintf('Tornado (best alpha)      & %.2f & %.2f & %.2f & %.2f \\\\\n', rms_T_A, mae_T_A, rms_T_B, mae_T_B);
fprintf('Roskam  (best alpha)      & %.2f & %.2f & %.2f & %.2f \\\\\n', rms_R_A, mae_R_A, rms_R_B, mae_R_B);
fprintf('Chakraborty Sim           & %.2f & %.2f & %.2f & %.2f \\\\\n', rms_S_A, mae_S_A, rms_S_B, mae_S_B);
fprintf('%s\n', separatore);