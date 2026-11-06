clc; clear; close all;

%% =========================================================
%  Additional Validation Plots - F-18 SRA Hinge Moment
%  STANDALONE VERSION - runs independently from main script.
%
%  NOTE ON COMPLEX VALUES:
%    The Roskam Prandtl-Glauert correction uses sqrt(1-M^2),
%    which is imaginary for M > 1.  Wherever this occurs the
%    real part is plotted and the affected data is highlighted:
%      Fig 4  -> cross markers on complex points
%      Fig 5  -> cross markers on complex points
%      Fig 7  -> grey NaN cells + magenta patch overlay
%
%  REQUIRES (same folder or on path):
%    ../Summary_LOOP.mat
%    Nasa_Chak/caseA_Deflection.csv     caseA_Moment_Sim.csv  caseA_Moment_Flight.csv
%    Nasa_Chak/caseB_Deflection.csv     caseB_Moment_Sim.csv  caseB_Moment_Flight.csv
%    Nasa_Chak/caseC_Deflection.csv                           caseC_Moment_Flight.csv
%    Nasa_Chak/caseD_Deflection.csv                           caseD_Moment_Flight.csv
%
%  PRODUCES (5 figures):
%    Fig.3  - Residual time history        (Flight - Method)          2x2, all cases
%    Fig.4  - Ch vs deflection             (non-dimensional, static)  2x2, all cases
%    Fig.5  - Mach sensitivity of Ch       (compressibility effect)   single plot
%    Fig.6  - Scatter correlation          (Method vs Flight, R2)     1x2, all cases
%    Fig.7  - Lookup table heatmap         (Ch over delta x Mach)     2x2, per altitude
%% =========================================================

addpath("Nasa_Chak\")

%% =========================================================
%  SECTION 0 - SHARED CONSTANTS AND GEOMETRY
%% =========================================================

% -- Plot style -------------------------------------------
cFlt     = [0.10 0.20 0.85];
cSim     = [0.50 0.50 0.50];   %#ok<NASGU>
cTornado = [0.85 0.20 0.10];
cRoskam  = [0.10 0.65 0.10];
cCx      = [0.85 0.00 0.85];   % magenta - flags complex (PG breakdown)
LW       = 2.0;
FS_title = 11;
FS_axis  = 10;
FS_lgd   = 9;

% Per-case accent colours for scatter (Fig 6)
cCase = { [0.10 0.20 0.85], [0.85 0.55 0.00], ...
          [0.55 0.10 0.78], [0.10 0.65 0.10] };

% -- F/A-18 SRA geometry ----------------------------------
Sf      = 1.135;              % aileron area        [m2]
cf_c    = 0.288;              % aileron chord ratio [-]
cr      = 4.04;               % root chord          [m]
ct      = 1.68;               % tip chord           [m]
cf_bar  = cf_c * (cr + ct)/2; % mean flap chord     [m]

% -- Condition definitions (mirror Validation_Script_2) ---
MACH_TOL = 0.01;
ALT_TOL  = 50;                    % [m]

LBF_FT_X1000_TO_NM = 112.985;    % unit conversion for cases C and D

MACH_A = 0.72;  ALT_A = 7620;    % 25 kft
MACH_B = 0.84;  ALT_B = 7620;    % 25 kft
MACH_C = 1.58;  ALT_C = 10363.2; % 34 kft
MACH_D = 1.60;  ALT_D = 10363.2; % 34 kft

caseMachs  = [MACH_A MACH_B MACH_C MACH_D];
caseAlts   = [ALT_A  ALT_B  ALT_C  ALT_D];
caseLabels = {'(a)','(b)','(c)','(d)'};
caseDescs  = {'roll doublet', 'aileron reversal', ...
              'reversal (half stick)', 'reversal (full, R)'};
caseKft    = [25 25 34 34];

% -- ISA dynamic pressure per validated case --------------
q_case = zeros(1,4);
for kc = 1:4
    [~, ~, rho_k, ~] = isa_atmosphere(caseAlts(kc));
    a_k        = sqrt(1.4 * 287 * isa_temperature(caseAlts(kc)));
    q_case(kc) = 0.5 * rho_k * (caseMachs(kc) * a_k)^2;
end

%% =========================================================
%  SECTION 1 - LOAD DATA
%% =========================================================

fprintf('Loading Summary_LOOP.mat...\n');
load('../RESULTS_CASES/Summary_LOOP_1000.mat', 'Summary'); %adjust name!!

loadCSV = @(f) sortrows(readmatrix(f), 1);

Def{1} = loadCSV('caseA_Deflection.csv');
Def{2} = loadCSV('caseB_Deflection.csv');
Def{3} = loadCSV('caseC_Deflection.csv');
Def{4} = loadCSV('caseD_Deflection.csv');

Sim{1} = loadCSV('caseA_Moment_Sim.csv');
Sim{2} = loadCSV('caseB_Moment_Sim.csv');

Flt{1} = loadCSV('caseA_Moment_Flight.csv');
Flt{2} = loadCSV('caseB_Moment_Flight.csv');
Flt{3} = loadCSV('caseC_Moment_Flight.csv');  Flt{3}(:,2) = Flt{3}(:,2) * LBF_FT_X1000_TO_NM;
Flt{4} = loadCSV('caseD_Moment_Flight.csv');  Flt{4}(:,2) = Flt{4}(:,2) * LBF_FT_X1000_TO_NM;

%% =========================================================
%  SECTION 2 - FILTER SUMMARY BY MACH + ALTITUDE
%% =========================================================

filterSummary = @(M, h) Summary( ...
    abs(Summary.Mach     - M) < MACH_TOL & ...
    abs(Summary.Altitude - h) < ALT_TOL  , :);

Sub = cell(1,4);
for kc = 1:4
    Sub{kc} = filterSummary(caseMachs(kc), caseAlts(kc));
    if isempty(Sub{kc})
        error('No entries for case %s (M=%.2f, h=%.0f m).', ...
              caseLabels{kc}, caseMachs(kc), caseAlts(kc));
    end
    fprintf('Case %s (M=%.2f, h=%.0f m): %d rows\n', ...
        caseLabels{kc}, caseMachs(kc), caseAlts(kc), height(Sub{kc}));
end

%% =========================================================
%  SECTION 3 - COMMON TIME GRIDS
%% =========================================================

t_common   = cell(1,4);
Flt_grid   = cell(1,4);
deg_common = cell(1,4);
d_t        = cell(1,4);
d_deg      = cell(1,4);

for kc = 1:4
    d_t{kc}   = Def{kc}(:,1);
    d_deg{kc} = Def{kc}(:,2);
    [t_common{kc}, Flt_grid{kc}, deg_common{kc}] = ...
        build_common_grid(d_t{kc}, d_deg{kc}, Flt{kc});
end

%% =========================================================
%  SECTION 4 - BEST ALPHA (min RMS vs NASA flight)
%% =========================================================

alphas     = cell(1,4);
alpha_best = zeros(1,4);
rms_min_v  = zeros(1,4);
rms_diff   = cell(1,4);
mean_diff  = cell(1,4);

for kc = 1:4
    alphas{kc} = unique(Sub{kc}.alpha);
    [rms_diff{kc}, mean_diff{kc}, alpha_best(kc), rms_min_v(kc)] = ...
        sweep_alpha(Sub{kc}, alphas{kc}, deg_common{kc}, Flt_grid{kc});
end

fprintf('\nBest alpha summary:\n');
for kc = 1:4
    fprintf('  Case %s (M=%.2f, h=%d kft): alpha = %.1f deg  RMS = %.2f Nm\n', ...
        caseLabels{kc}, caseMachs(kc), caseKft(kc), alpha_best(kc), rms_min_v(kc));
end
fprintf('\n');

%% =========================================================
%  SECTION 5 - DYNAMIC PREDICTIONS AT BEST ALPHA
%% =========================================================

MT_dyn  = cell(1,4);
MR_dyn  = cell(1,4);
res_Tor = cell(1,4);
res_Ros = cell(1,4);

for kc = 1:4
    [MT_dyn{kc}, MR_dyn{kc}] = interp_moment(Sub{kc}, alpha_best(kc), d_deg{kc});
    MT_g = interp1(d_t{kc}, real(MT_dyn{kc}), t_common{kc}, 'linear');
    MR_g = interp1(d_t{kc}, real(MR_dyn{kc}), t_common{kc}, 'linear');
    res_Tor{kc} = Flt_grid{kc} - MT_g;
    res_Ros{kc} = Flt_grid{kc} - MR_g;
end

%% =========================================================
%  FIG 3 - RESIDUAL TIME HISTORY (2x2, all cases)
%  Purpose: shows WHERE in the manoeuvre the error is
%  concentrated. Peaks near large deflections -> nonlinear
%  regime. Uniform distribution -> systematic bias.
%% =========================================================

figure('Color','w','Position',[100 100 1400 760],'Name','Fig3 - Residuals');
tl3 = tiledlayout(2,2,'TileSpacing','loose','Padding','loose');

axR = gobjects(4,1);
for kc = 1:4
    axR(kc) = nexttile(kc);
    hold on; grid on; box on;
    yline(0,'--','Color',[0.45 0.45 0.45],'LineWidth',1.4,'HandleVisibility','off');
    plot(t_common{kc}, res_Tor{kc}, 'Color', cTornado, 'LineWidth', LW, ...
         'DisplayName','Flight - Tornado');
    plot(t_common{kc}, res_Ros{kc}, 'Color', cRoskam,  'LineWidth', LW, ...
         'DisplayName','Flight - Roskam');
    xlabel('Time (s)','FontSize',FS_axis);
    ylabel('\Delta M_{hinge}  (Nm)','FontSize',FS_axis,'Interpreter','tex');
    title({sprintf('%s  Residual - %s', caseLabels{kc}, caseDescs{kc}), ...
           sprintf('M = %.2f,  h = %d kft,  \\alpha = %.1f deg', ...
                   caseMachs(kc), caseKft(kc), alpha_best(kc))}, ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
    legend('Location','best','FontSize',FS_lgd,'Box','off');
end

set(axR,'FontSize',FS_axis,'LineWidth',0.9);
title(tl3,'Residual Error: NASA Flight minus Estimated Hinge Moment', ...
    'FontSize',14,'FontWeight','bold');

%% =========================================================
%  FIG 4 - Ch vs DEFLECTION (2x2, all cases)
%  Complex Ch values (Roskam PG breakdown for M>1) are
%  plotted as Re(Ch) with cross markers.
%% =========================================================

figure('Color','w','Position',[120 80 1400 760],'Name','Fig4 - Ch vs delta');
tl4 = tiledlayout(2,2,'TileSpacing','loose','Padding','loose');

axCh = gobjects(4,1);
for kc = 1:4
    mask_a = abs(Sub{kc}.alpha - alpha_best(kc)) < 0.1;
    rows_k = Sub{kc}(mask_a, :);
    [d_s, is] = sort(rows_k.delta);

    ChT_raw = rows_k.M_Tornado(is) / (q_case(kc) * Sf * cf_bar);
    ChR_raw = rows_k.Ma_Roskam(is) / (q_case(kc) * Sf * cf_bar);

    cx_mask_T = imag(ChT_raw) ~= 0;
    cx_mask_R = imag(ChR_raw) ~= 0;
    ChT_k     = real(ChT_raw);
    ChR_k     = real(ChR_raw);

    axCh(kc) = nexttile(kc);
    hold on; grid on; box on;
    yline(0,'--','Color',[0.75 0.75 0.75],'LineWidth',1.2,'HandleVisibility','off');
    plot(d_s, ChT_k, '-o', 'Color', cTornado, 'LineWidth', LW, ...
         'MarkerFaceColor', cTornado, 'MarkerSize', 6, 'DisplayName','Tornado');
    plot(d_s, ChR_k, '-s', 'Color', cRoskam, 'LineWidth', LW, ...
         'MarkerFaceColor', cRoskam, 'MarkerSize', 6, 'DisplayName','Roskam');

    % Highlight complex points (PG breakdown)
    cx_leg = false;
    for cx_src = {struct('mask',cx_mask_T,'y',ChT_k), ...
                  struct('mask',cx_mask_R,'y',ChR_k)}
        s = cx_src{1};
        if any(s.mask)
            if ~cx_leg
                plot(d_s(s.mask), s.y(s.mask), 'x', 'Color', cCx, ...
                     'MarkerSize',12,'LineWidth',2.5, ...
                     'DisplayName','Complex Re[C_h] (PG breakdown)');
                cx_leg = true;
            else
                plot(d_s(s.mask), s.y(s.mask), 'x', 'Color', cCx, ...
                     'MarkerSize',12,'LineWidth',2.5,'HandleVisibility','off');
            end
        end
    end

    xlabel('Aileron deflection  \delta  (deg)','FontSize',FS_axis,'Interpreter','tex');
    ylabel('C_h  (-)','FontSize',FS_axis,'Interpreter','tex');
    title({sprintf('%s  C_h vs \\delta  -  M = %.2f', caseLabels{kc}, caseMachs(kc)), ...
           sprintf('\\alpha = %.1f deg,  h = %d kft', alpha_best(kc), caseKft(kc))}, ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
    legend('Location','best','FontSize',FS_lgd,'Box','off');
end

set(axCh,'FontSize',FS_axis,'LineWidth',0.9);
title(tl4,'Non-Dimensional Hinge Moment Coefficient vs Aileron Deflection', ...
    'FontSize',14,'FontWeight','bold');

%% =========================================================
%  FIG 5 - MACH SENSITIVITY OF Ch (single plot)
%
%  BUG FIX: alpha_vec = -5:2:5 = {-5,-3,-1,1,3,5} so 0 is
%  never in the table.  alpha_fixed is now snapped to the
%  nearest alpha that actually exists in Summary so the mask
%  always finds rows and ChT/ChR_mach are never all-NaN.
%
%  The main script runs all Mach x all Altitude combinations,
%  so both altitudes are available for all 4 Mach numbers.
%  Two series (solid = 25 kft, dashed = 34 kft) show the
%  density effect on Ch independent of compressibility.
%  Complex Re[Ch] points (Roskam, M>1) are flagged with x.
%% =========================================================

% Snap fixed conditions to values that exist in Summary
all_alphas_S  = unique(Summary.alpha);
all_deltas_S  = unique(Summary.delta);
alpha_tgt     = 0;    delta_tgt = 10;
[~,ia_fix]    = min(abs(all_alphas_S - alpha_tgt));
[~,id_fix]    = min(abs(all_deltas_S - delta_tgt));
alpha_fixed   = all_alphas_S(ia_fix);
delta_fixed   = all_deltas_S(id_fix);

fprintf('Fig 5 fixed conditions: alpha = %.1f deg,  delta = %.1f deg\n', ...
        alpha_fixed, delta_fixed);

% Build unique (Mach, Altitude) pairs present in Summary
condMat  = unique([Summary.Mach, Summary.Altitude], 'rows');
n_cond   = size(condMat, 1);
ChT_mach = NaN(n_cond, 1);
ChR_mach = NaN(n_cond, 1);

for ic = 1:n_cond
    M_ic = condMat(ic,1);   h_ic = condMat(ic,2);
    [~, ~, rho_ic, ~] = isa_atmosphere(h_ic);
    a_ic = sqrt(1.4 * 287 * isa_temperature(h_ic));
    q_ic = 0.5 * rho_ic * (M_ic * a_ic)^2;

    mask_ic = abs(Summary.Mach     - M_ic)        < MACH_TOL & ...
              abs(Summary.Altitude - h_ic)         < ALT_TOL  & ...
              abs(Summary.alpha    - alpha_fixed)  < 0.1      & ...
              abs(Summary.delta    - delta_fixed)  < 0.5;
    if any(mask_ic)
        ChT_mach(ic) = mean(Summary.M_Tornado(mask_ic)) / (q_ic * Sf * cf_bar);
        ChR_mach(ic) = mean(Summary.Ma_Roskam(mask_ic)) / (q_ic * Sf * cf_bar);
    end
end

% Complex masks and real extraction
cxT5     = imag(ChT_mach) ~= 0;
cxR5     = imag(ChR_mach) ~= 0;
ChT_plot = real(ChT_mach);
ChR_plot = real(ChR_mach);

% Altitude masks for separate series
altLevels   = [ALT_A ALT_C];
altKft      = [25 34];
lineStyles  = {'-o', '--^'};          % 25 kft solid, 34 kft dashed
scaleT      = [1.0, 0.65];            % colour brightness per altitude
scaleR      = [1.0, 0.65];

figure('Color','w','Position',[140 80 860 520],'Name','Fig5 - Mach sensitivity');
hold on; grid on; box on;

for iAlt = 1:2
    mask_alt = abs(condMat(:,2) - altLevels(iAlt)) < ALT_TOL;
    if ~any(mask_alt), continue; end

    cT = cTornado * scaleT(iAlt);
    cR = cRoskam  * scaleR(iAlt);
    ls = lineStyles{iAlt};

    plot(condMat(mask_alt,1), ChT_plot(mask_alt), ls, ...
         'Color', cT, 'LineWidth', LW, 'MarkerFaceColor', cT, 'MarkerSize', 7, ...
         'DisplayName', sprintf('Tornado - h = %d kft', altKft(iAlt)));
    plot(condMat(mask_alt,1), ChR_plot(mask_alt), strrep(ls,'o','s'), ...
         'Color', cR, 'LineWidth', LW, 'MarkerFaceColor', cR, 'MarkerSize', 7, ...
         'DisplayName', sprintf('Roskam - h = %d kft', altKft(iAlt)));
end

% Cross markers on complex points (only Roskam expected)
cx_leg5 = false;
for ic = 1:n_cond
    if cxT5(ic) || cxR5(ic)
        if ~cx_leg5
            plot(condMat(ic,1), ChT_plot(ic), 'x', 'Color', cCx, ...
                 'MarkerSize',14,'LineWidth',2.5, ...
                 'DisplayName','Complex Re[C_h] (PG breakdown, M > 1)');
            cx_leg5 = true;
        else
            plot(condMat(ic,1), ChT_plot(ic), 'x', 'Color', cCx, ...
                 'MarkerSize',14,'LineWidth',2.5,'HandleVisibility','off');
        end
        if cxR5(ic)
            plot(condMat(ic,1), ChR_plot(ic), 'x', 'Color', cCx, ...
                 'MarkerSize',14,'LineWidth',2.5,'HandleVisibility','off');
        end
    end
end

% Vertical lines marking the 4 validated Mach numbers
caseXsty = {'--', '-.', ':', '-'};
for kc = 1:4
    xline(caseMachs(kc), caseXsty{kc}, 'LineWidth', 1.8, 'Color', cCase{kc}, ...
          'DisplayName', sprintf('Case %s  M = %.2f', caseLabels{kc}, caseMachs(kc)));
end

xlabel('Mach number  M','FontSize',FS_axis);
ylabel('Hinge moment coefficient  C_h  (-)','FontSize',FS_axis);
title({'Mach Sensitivity of  C_h', ...
       sprintf('\\alpha = %.1f deg,  \\delta = %.0f deg  (snapped to table values)', ...
               alpha_fixed, delta_fixed)}, ...
    'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
legend('Location','best','FontSize',FS_lgd,'Box','off');
set(gca,'FontSize',FS_axis,'LineWidth',0.9);

%% =========================================================
%  FIG 6 - SCATTER CORRELATION (1x2)
%  Points: all 4 cases colour-coded (flight-level clustering visible).
%  Fit (R2 + slope): SUBSONIC cases only, since the supersonic cases
%  collapse near zero and distort the regression.
%% =========================================================
sub_idx = find(caseMachs < 1);   % subsonic cases used for the regression fit

flt_by_case = cell(1,4);
tor_by_case = cell(1,4);
ros_by_case = cell(1,4);
for kc = 1:4
    MT_g = interp1(d_t{kc}, real(MT_dyn{kc}), t_common{kc}, 'linear');
    MR_g = interp1(d_t{kc}, real(MR_dyn{kc}), t_common{kc}, 'linear');
    flt_by_case{kc} = Flt_grid{kc};
    tor_by_case{kc} = MT_g;
    ros_by_case{kc} = MR_g;
end

% --- Aggregate SUBSONIC cases only for the fit ---
flt_sub = [];   tor_sub = [];   ros_sub = [];
for kc = sub_idx
    flt_sub = [flt_sub; flt_by_case{kc}(:)];   %#ok<AGROW>
    tor_sub = [tor_sub; tor_by_case{kc}(:)];   %#ok<AGROW>
    ros_sub = [ros_sub; ros_by_case{kc}(:)];   %#ok<AGROW>
end
ok    = ~isnan(flt_sub) & ~isnan(tor_sub) & ~isnan(ros_sub);
flt_v = flt_sub(ok);   tor_v = tor_sub(ok);   ros_v = ros_sub(ok);

Rsq  = @(yhat,y) 1 - sum((y-yhat).^2) / sum((y-mean(y)).^2);
R2_T = Rsq(tor_v, flt_v);   pT = polyfit(flt_v, tor_v, 1);
R2_R = Rsq(ros_v, flt_v);   pR = polyfit(flt_v, ros_v, 1);

% Fit line drawn over the subsonic data range (no visual extrapolation)
x_fit = linspace(min(flt_v)*1.05, max(flt_v)*1.05, 300);

figure('Color','w','Position',[160 80 1200 520],'Name','Fig6 - Scatter');
tl6 = tiledlayout(1,2,'TileSpacing','loose','Padding','loose');

ax_sT = nexttile(1);
hold on; grid on; box on; axis equal;
for kc = 1:4
    ok_k = ~isnan(flt_by_case{kc}) & ~isnan(tor_by_case{kc});
    scatter(flt_by_case{kc}(ok_k), tor_by_case{kc}(ok_k), 14, ...
            cCase{kc}, 'filled', 'MarkerFaceAlpha', 0.35, ...
            'DisplayName', sprintf('Case %s  M=%.2f  h=%d kft', ...
                                   caseLabels{kc}, caseMachs(kc), caseKft(kc)));
end
plot(x_fit, polyval(pT,x_fit), '-', 'Color', cTornado*0.65, 'LineWidth', 2.0, ...
     'DisplayName', sprintf('Subsonic fit  (a=%.3f, b=%.1f)', pT(1), pT(2)));
plot(x_fit, x_fit, 'k--', 'LineWidth', 1.4, 'DisplayName', 'Ideal  (1:1)');
xlabel('NASA Flight  M_{hinge}  (Nm)','FontSize',FS_axis,'Interpreter','tex');
ylabel('Tornado  M_{hinge}  (Nm)','FontSize',FS_axis,'Interpreter','tex');
title({'(a)  Tornado vs Flight', ...
       sprintf('R^2 = %.4f  |  slope = %.3f  (subsonic fit)', R2_T, pT(1))}, ...
      'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
legend('Location','best','FontSize',FS_lgd,'Box','off');

ax_sR = nexttile(2);
hold on; grid on; box on; axis equal;
for kc = 1:4
    ok_k = ~isnan(flt_by_case{kc}) & ~isnan(ros_by_case{kc});
    scatter(flt_by_case{kc}(ok_k), ros_by_case{kc}(ok_k), 14, ...
            cCase{kc}, 'filled', 'MarkerFaceAlpha', 0.35, ...
            'DisplayName', sprintf('Case %s  M=%.2f  h=%d kft', ...
                                   caseLabels{kc}, caseMachs(kc), caseKft(kc)));
end
plot(x_fit, polyval(pR,x_fit), '-', 'Color', cRoskam*0.65, 'LineWidth', 2.0, ...
     'DisplayName', sprintf('Subsonic fit  (a=%.3f, b=%.1f)', pR(1), pR(2)));
plot(x_fit, x_fit, 'k--', 'LineWidth', 1.4, 'DisplayName', 'Ideal  (1:1)');
xlabel('NASA Flight  M_{hinge}  (Nm)','FontSize',FS_axis,'Interpreter','tex');
ylabel('Roskam  M_{hinge}  (Nm)','FontSize',FS_axis,'Interpreter','tex');
title({'(b)  Roskam vs Flight', ...
       sprintf('R^2 = %.4f  |  slope = %.3f  (subsonic fit)', R2_R, pR(1))}, ...
      'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
legend('Location','best','FontSize',FS_lgd,'Box','off');

xl = [min([xlim(ax_sT) xlim(ax_sR)]) max([xlim(ax_sT) xlim(ax_sR)])];
yl = [min([ylim(ax_sT) ylim(ax_sR)]) max([ylim(ax_sT) ylim(ax_sR)])];
xlim(ax_sT,xl); xlim(ax_sR,xl); ylim(ax_sT,yl); ylim(ax_sR,yl);
set([ax_sT ax_sR],'FontSize',FS_axis,'LineWidth',0.9);

title(tl6,'Correlation: Estimated vs Measured Hinge Moment (points: all 4 cases, fit: subsonic only)', ...
      'FontSize',13,'FontWeight','bold');

fprintf('Scatter (fit on subsonic cases only):\n');
fprintf('  Tornado  R2 = %.4f   slope = %.4f\n', R2_T, pT(1));
fprintf('  Roskam   R2 = %.4f   slope = %.4f\n\n', R2_R, pR(1));

%% =========================================================
%  FIG 7 - LOOKUP TABLE HEATMAP  (2x2)  -- REVISED
%
%  Gap fix: a NaN column is inserted at M = 1.21 (midpoint
%  between subsonic and supersonic groups) so imagesc does
%  NOT linearly blend across a region with no data.
%  A grey patch + "No data computed" label make the gap
%  explicit.  The two validated Mach pairs are also labelled
%  directly on the axis as tick marks.
%% =========================================================

altLevels25_34 = [ALT_A  ALT_C];
altLabels25_34 = {'h = 25 kft', 'h = 34 kft'};
alpha_map_per_alt = [alpha_best(1), alpha_best(3)];

% Mach gap sentinel value placed mid-way between groups
M_GAP = 1.21;   % purely a display spacer – no physics data here

figure('Color','w','Position',[50 40 1400 840], ...
       'Name','Fig7 - Heatmap (Tornado & Roskam, 25 & 34 kft)');
tl7 = tiledlayout(2,2,'TileSpacing','compact','Padding','loose');

tagLet = {'a','b','c','d'};
mthLbl = {'Tornado', 'Roskam'};

for iAlt = 1:2
    h_alt     = altLevels25_34(iAlt);
    alpha_map = alpha_map_per_alt(iAlt);
    SubAlt    = Summary(abs(Summary.Altitude - h_alt) < ALT_TOL, :);

    mach_grid  = unique(SubAlt.Mach);    % e.g. [0.72 0.84 1.58 1.60]
    delta_grid = unique(SubAlt.delta);
    n_mg = numel(mach_grid);
    n_dg = numel(delta_grid);

    % Build raw maps
    ChT_raw = NaN(n_dg, n_mg);
    ChR_raw = NaN(n_dg, n_mg);

    for im = 1:n_mg
        M_im = mach_grid(im);
        [~, ~, rho_im, ~] = isa_atmosphere(h_alt);
        a_im = sqrt(1.4 * 287 * isa_temperature(h_alt));
        q_im = 0.5 * rho_im * (M_im * a_im)^2;

        for id = 1:n_dg
            mask_hm = abs(SubAlt.Mach  - M_im)          < MACH_TOL & ...
                      abs(SubAlt.delta - delta_grid(id)) < 0.5      & ...
                      abs(SubAlt.alpha - alpha_map)       < 0.1;
            if any(mask_hm)
                ChT_raw(id,im) = mean(SubAlt.M_Tornado(mask_hm)) / (q_im*Sf*cf_bar);
                ChR_raw(id,im) = mean(SubAlt.Ma_Roskam(mask_hm)) / (q_im*Sf*cf_bar);
            end
        end
    end

    % ---- Insert NaN gap column between subsonic/supersonic groups --------
    % Detect the split: find largest gap between consecutive Mach values
    [~, gap_idx] = max(diff(mach_grid));       % index before the gap
    mach_plot  = [mach_grid(1:gap_idx);   M_GAP;   mach_grid(gap_idx+1:end)];
    ChT_plot   = [ChT_raw(:,1:gap_idx),   NaN(n_dg,1),   ChT_raw(:,gap_idx+1:end)];
    ChR_plot   = [ChR_raw(:,1:gap_idx),   NaN(n_dg,1),   ChR_raw(:,gap_idx+1:end)];

    maps_plot  = {ChT_plot, ChR_plot};

    % Gap x-limits (used for the grey patch)
    M_gap_lo = mach_grid(gap_idx)   + 0.005;
    M_gap_hi = mach_grid(gap_idx+1) - 0.005;
    % Column half-widths for imagesc cell edges
    dM_sub  = mean(diff(mach_grid(1:gap_idx)));
    dM_sup  = mean(diff(mach_grid(gap_idx+1:end)));
    if isnan(dM_sub) || dM_sub == 0,  dM_sub = 0.06; end
    if isnan(dM_sup) || dM_sup == 0,  dM_sup = 0.01; end

    for iM = 1:2
        ax_hm = nexttile((iAlt-1)*2 + iM);

        raw    = maps_plot{iM};
        is_cx  = imag(raw) ~= 0;
        disp_m = real(raw);
        disp_m(is_cx) = NaN;

        % Colour limits from real, non-gap data only
        valid_v = disp_m(~isnan(disp_m));
        if isempty(valid_v), cl = [0 1];
        else
            cl = [min(valid_v) max(valid_v)];
            if diff(cl) == 0, cl = cl + [-0.01 0.01]; end
        end

        % --- Draw heatmap with explicit cell-edge x-coordinates ----------
        %  imagesc(X, Y, C) with X as a 2-element vector sets the x-extent
        %  of the image.  Instead, use pcolor for precise column placement.
        %
        %  Build cell-edge vectors so each real column sits over its Mach
        %  tick and the gap column is rendered narrow/grey (NaN -> grey).
        n_col = numel(mach_plot);
        % Cell edges: midpoints between columns, clamped at the ends
        edges_x = zeros(1, n_col+1);
        for ic2 = 1:n_col
            if ic2 == 1
                edges_x(ic2) = mach_plot(1) - dM_sub/2;
            elseif mach_plot(ic2) == M_GAP
                edges_x(ic2) = M_gap_lo;
            elseif mach_plot(ic2-1) == M_GAP
                edges_x(ic2) = M_gap_hi;
            else
                edges_x(ic2) = (mach_plot(ic2-1) + mach_plot(ic2))/2;
            end
        end
        edges_x(end) = mach_plot(end) + dM_sup/2;

        % pcolor requires (nRow+1) x (nCol+1) edge matrices
        dD = mean(diff(delta_grid));
        if isnan(dD)||dD==0, dD = 2; end
        edges_y = [delta_grid(1)-dD/2; delta_grid+dD/2];  % (n_dg+1) x 1

        % Tile edge vectors into 2-D matrices
        EX = repmat(edges_x,  numel(edges_y), 1);
        EY = repmat(edges_y,  1, numel(edges_x));

        % pcolor uses (nRow x nCol) data on (nRow+1 x nCol+1) edges
        pc = pcolor(ax_hm, EX, EY, [disp_m, NaN(n_dg,1); NaN(1,n_col+1)]);
        pc.EdgeColor = 'none';

        set(ax_hm, 'Color',[0.82 0.82 0.82]);   % grey = NaN / gap cells
        colormap(ax_hm, 'turbo');
        clim(ax_hm, cl);
        cb = colorbar(ax_hm);
        cb.Label.String   = 'C_h  (-)';
        cb.Label.FontSize = FS_axis;

        hold(ax_hm, 'on');

        % ---- Grey "no data" patch over the gap region -------------------
        y_lo = delta_grid(1)   - dD/2;
        y_hi = delta_grid(end) + dD/2;
        patch(ax_hm, ...
              [M_gap_lo M_gap_hi M_gap_hi M_gap_lo], ...
              [y_lo     y_lo     y_hi     y_hi    ], ...
              [0.55 0.55 0.55], ...
              'FaceAlpha', 1.0, 'EdgeColor', 'none', ...
              'HandleVisibility','off');

        % Hatching lines over the gap to make it unmistakable
        n_hatch = 8;
        hatch_x = linspace(M_gap_lo, M_gap_hi, n_hatch);
        for ih = 1:n_hatch
            plot(ax_hm, [hatch_x(ih) hatch_x(ih)], [y_lo y_hi], ...
                 '-', 'Color',[0.35 0.35 0.35], 'LineWidth',0.8, ...
                 'HandleVisibility','off');
        end

        % "No data computed" text centred in the gap
        text(ax_hm, M_GAP, mean([y_lo y_hi]), ...
             sprintf('No data\ncomputed'), ...
             'HorizontalAlignment','center', ...
             'VerticalAlignment','middle', ...
             'FontSize', 7.5, 'Color','w', 'FontWeight','bold', ...
             'Rotation', 90);

        % ---- Magenta patch for complex (PG breakdown) columns -----------
        has_cx_patch = false;
        if any(is_cx(:))
            for ic2 = find(any(is_cx,1))
                if mach_plot(ic2) == M_GAP, continue; end   % skip gap column
                patch(ax_hm, ...
                      [edges_x(ic2) edges_x(ic2+1) edges_x(ic2+1) edges_x(ic2)], ...
                      [y_lo         y_lo            y_hi            y_hi         ], ...
                      cCx, 'FaceAlpha',0.35, 'EdgeColor',cCx, ...
                      'LineWidth',1.2, 'HandleVisibility','off');
            end
            has_cx_patch = true;
        end

        % ---- White dashed lines at validated Mach numbers ---------------
        for kc = 1:4
            if abs(caseAlts(kc) - h_alt) < ALT_TOL
                xline(ax_hm, caseMachs(kc), 'w--', 'LineWidth', 2.2, ...
                      'HandleVisibility','off');
            end
        end

        % ---- Axis cosmetics ---------------------------------------------
        % Show only the real Mach values as ticks (skip M_GAP sentinel)
        ax_hm.XTick = mach_grid;
        ax_hm.XTickLabel = arrayfun(@(m) sprintf('%.2f',m), mach_grid, ...
                                    'UniformOutput',false);
        ax_hm.XLim  = [edges_x(1) edges_x(end)];
        ax_hm.YLim  = [y_lo y_hi];

        xlabel(ax_hm, 'Mach number', 'FontSize', FS_axis);
        ylabel(ax_hm, '\delta  (deg)', 'FontSize', FS_axis, 'Interpreter','tex');
        tag = sprintf('(%s)', tagLet{(iAlt-1)*2 + iM});
        title(ax_hm, ...
            {sprintf('%s  %s  –  %s', tag, mthLbl{iM}, altLabels25_34{iAlt}), ...
             sprintf('\\alpha = %.1f deg  |  white dashed = validated M', alpha_map)}, ...
            'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
        set(ax_hm,'FontSize',FS_axis,'LineWidth',0.9);

        % Legend below panel
        if has_cx_patch
            patch(ax_hm, NaN, NaN, cCx, 'FaceAlpha',0.35, 'EdgeColor',cCx, ...
                  'LineWidth',1.2, 'DisplayName','Complex Re[C_h] (PG, M > 1)');
            legend(ax_hm, 'Location','southoutside', ...
                   'FontSize',FS_lgd,'Box','off','Orientation','horizontal');
        end
    end
end

title(tl7, ...
    {'C_h Lookup Table  –  Tornado (left)  and  Roskam (right)  |  25 kft (top)  and  34 kft (bottom)', ...
     'Hatched region: Mach range not simulated (no data computed)'}, ...
    'FontSize',12,'FontWeight','bold');
%% =========================================================
%  CONSOLE SUMMARY TABLE (all 4 cases)
%% =========================================================

sep = repmat('=',1,72);
fprintf('\n%s\n', sep);
fprintf('QUANTITATIVE ERROR SUMMARY  [Nm]\n');
fprintf('%-24s  %8s %8s %8s\n','','RMS','MAE','Max');
fprintf('%s\n', repmat('-',1,72));
for kc = 1:4
    ok_k  = ~isnan(res_Tor{kc}) & ~isnan(res_Ros{kc});
    rms_T = sqrt(mean(res_Tor{kc}(ok_k).^2));
    mae_T = mean(abs(res_Tor{kc}(ok_k)));
    max_T = max( abs(res_Tor{kc}(ok_k)));
    rms_R = sqrt(mean(res_Ros{kc}(ok_k).^2));
    mae_R = mean(abs(res_Ros{kc}(ok_k)));
    max_R = max( abs(res_Ros{kc}(ok_k)));
    fprintf('Case %s Tornado (M=%.2f, %d kft)  %8.2f %8.2f %8.2f\n', ...
            caseLabels{kc}, caseMachs(kc), caseKft(kc), rms_T, mae_T, max_T);
    fprintf('Case %s Roskam  (M=%.2f, %d kft)  %8.2f %8.2f %8.2f\n', ...
            caseLabels{kc}, caseMachs(kc), caseKft(kc), rms_R, mae_R, max_R);
    if kc < 4, fprintf('%s\n', repmat('-',1,72)); end
end
fprintf('%s\n', sep);
fprintf('Scatter (all 4 cases combined):\n');
fprintf('  Tornado  R2 = %.4f   slope = %.4f\n', R2_T, pT(1));
fprintf('  Roskam   R2 = %.4f   slope = %.4f\n\n', R2_R, pR(1));
fprintf('All additional validation figures generated.\n');

%% =========================================================
%  LOCAL FUNCTIONS
%% =========================================================

function [t_common, Flt_on_grid, deg_common] = ...
        build_common_grid(def_t, def_deg, fltData)
% BUILD_COMMON_GRID  Shared time grid; handles duplicate timestamps.
    [flt_t_u, iu] = unique(fltData(:,1), 'last');
    flt_y_u       = fltData(iu, 2);
    t_lo          = max(def_t(1),   flt_t_u(1));
    t_hi          = min(def_t(end), flt_t_u(end));
    t_common      = def_t(def_t >= t_lo & def_t <= t_hi);
    Flt_on_grid   = interp1(flt_t_u, flt_y_u, t_common, 'linear');
    deg_common    = interp1(def_t,   def_deg,  t_common, 'linear');
end

function [MT_dyn, MR_dyn] = interp_moment(SubX, alpha_query, deg_vec)
% INTERP_MOMENT  Hinge moment time series by table lookup at fixed alpha.
%   Returns raw values (possibly complex). Caller applies real() for plots.
    [~, idx_a] = min(abs(SubX.alpha - alpha_query));
    best_alpha = SubX.alpha(idx_a);
    rows       = SubX(SubX.alpha == best_alpha, :);
    [delta_s, is] = sort(rows.delta);
    MT_s = rows.M_Tornado(is);
    MR_s = rows.Ma_Roskam(is);
    deg_c  = max(min(deg_vec, max(delta_s)), min(delta_s));
    MT_dyn = interp1(delta_s, MT_s, deg_c, 'linear');
    MR_dyn = interp1(delta_s, MR_s, deg_c, 'linear');
end

function [rms_v, mean_v, best_alpha, rms_min] = ...
        sweep_alpha(Sub, alphas, deg_common, Flt_on_grid)
% SWEEP_ALPHA  Find alpha minimising RMS of Tornado vs flight.
%   Uses real() to avoid complex propagation into RMS.
    n = numel(alphas);
    rms_v  = zeros(n,1);
    mean_v = zeros(n,1);
    for ia = 1:n
        [MT_tmp, ~] = interp_moment(Sub, alphas(ia), deg_common);
        diff_tmp    = Flt_on_grid - real(MT_tmp);
        ok          = ~isnan(diff_tmp);
        rms_v(ia)   = sqrt(mean(diff_tmp(ok).^2));
        mean_v(ia)  = mean(diff_tmp(ok));
    end
    [rms_min, idx_best] = min(rms_v);
    best_alpha = alphas(idx_best);
end

function T = isa_temperature(alt_m)
    T0 = 288.15;   L = 0.0065;   H_trop = 11000;
    if alt_m <= H_trop,  T = T0 - L * alt_m;
    else,                T = 216.65;
    end
end

function [p, T, rho, a] = isa_atmosphere(alt_m)
    T      = isa_temperature(alt_m);
    p0     = 101325;   T0 = 288.15;   L  = 0.0065;
    R      = 287.058;  g0 = 9.80665;  H_trop = 11000;
    if alt_m <= H_trop
        p = p0 * (T/T0)^(g0/(L*R));
    else
        p_trop = p0 * (216.65/T0)^(g0/(L*R));
        p = p_trop * exp(-g0*(alt_m - H_trop)/(R*216.65));
    end
    rho = p / (R * T);
    a   = sqrt(1.4 * R * T);
end