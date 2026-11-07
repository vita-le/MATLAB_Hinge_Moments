clc; clear; close all;

%% =========================================================
%  Extended Mach Envelope - Exploration Plots
%  Uses two separate summary files from the extended sweeps:
%    Summary_LOOP_SUB.mat  -> subsonic   M = 0.50 - 0.88
%    Summary_LOOP_SUP.mat  -> transonic  M = 0.90 - 1.60
%
%  PRODUCES:
%    Fig E1 - Heatmap subsonic    (delta x Mach, 2x2)
%    Fig E2 - Heatmap sup/trans   (delta x Mach, 2x2)
%    Fig E3 - Mach sensitivity    (full envelope, combined)
%    Fig E4 - Ch vs delta         (multi-Mach overlay, per altitude)
%    Fig E5 - Roskam-Tornado divergence (Delta Ch vs Mach)
%
%  Validated Mach anchors (marked as vertical lines / white dashes):
%    Case (a): M=0.72  h=25 kft
%    Case (b): M=0.84  h=25 kft
%    Case (c): M=1.58  h=34 kft
%    Case (d): M=1.60  h=34 kft
%% =========================================================

%% =========================================================
%  SECTION 0 - CONSTANTS, GEOMETRY, STYLE
%% =========================================================

PATH_SUB = '../RESULTS_CASES/Summary_LOOP_SUB.mat';
PATH_SUP = '../RESULTS_CASES/Summary_LOOP_SUP.mat';

% -- Plot style -------------------------------------------
cTornado = [0.85 0.20 0.10];
cRoskam  = [0.10 0.65 0.10];
cCx      = [0.85 0.00 0.85];       % magenta - PG complex breakdown
cGap     = [0.55 0.55 0.55];       % grey - no data region
LW       = 2.0;
FS_title = 11;
FS_axis  = 10;
FS_lgd   = 9;

% -- F/A-18 SRA geometry ----------------------------------
Sf      = 1.135;
cf_c    = 0.288;
cr      = 4.04;
ct      = 1.68;
cf_bar  = cf_c * (cr + ct) / 2;

% -- Tolerances -------------------------------------------
MACH_TOL = 0.015;
ALT_TOL  = 50;          % [m]

% -- Validated flight conditions --------------------------
VALID_MACH = [0.72, 0.84, 1.58, 1.60];
VALID_ALT  = [7620, 7620, 10363.2, 10363.2];   % [m]
VALID_LBL  = {'(a)','(b)','(c)','(d)'};
VALID_KFT  = [25, 25, 34, 34];
cValid     = {[0.10 0.20 0.85],[0.85 0.55 0.00], ...
              [0.55 0.10 0.78],[0.10 0.65 0.10]};

% Altitude levels
ALT_25 = 7620;
ALT_34 = 10363.2;
altLevels = [ALT_25, ALT_34];
altKft    = [25, 34];

%% =========================================================
%  SECTION 1 - LOAD AND MERGE
%% =========================================================

fprintf('Loading subsonic summary...   '); load(PATH_SUB,'Summary'); Sub = Summary; fprintf('done (%d rows)\n', height(Sub));
fprintf('Loading transonic summary...  '); load(PATH_SUP,'Summary'); Sup = Summary; fprintf('done (%d rows)\n', height(Sup));

% Combined table for full-envelope plots
All = [Sub; Sup];

% Snap fixed slice conditions to nearest values in All
all_alphas = unique(All.alpha);
all_deltas = unique(All.delta);
alpha_tgt  = 0;   delta_tgt = 10;
[~,ia] = min(abs(all_alphas - alpha_tgt));
[~,id] = min(abs(all_deltas - delta_tgt));
alpha_fixed = all_alphas(ia);
delta_fixed = all_deltas(id);
fprintf('\nFixed slice: alpha = %.1f deg,  delta = %.0f deg\n\n', alpha_fixed, delta_fixed);



%% =========================================================
%  FIG E1 - HEATMAP: SUBSONIC SWEEP
%  2 rows (altitudes) x 2 cols (methods)
%  White dashed = validated subsonic Mach: 0.72, 0.84
%% =========================================================

figure('Color','w','Position',[50 50 1300 780],'Name','Fig E1 - Heatmap Subsonic');
tl1 = tiledlayout(2,2,'TileSpacing','compact','Padding','loose');
title(tl1,'C_h Lookup Table - Subsonic Sweep  (M = 0.50 to 0.88)', ...
    'FontSize',12,'FontWeight','bold');

mthLbl = {'Tornado','Roskam'};

for iAlt = 1:2
    [ChT, ChR, mach_g, delta_g] = build_Ch_table(Sub, altLevels(iAlt), ...
        alpha_fixed, Sf, cf_bar, MACH_TOL, ALT_TOL);

    for iM = 1:2
        if iM==1, raw = ChT; else, raw = ChR; end
        is_cx  = imag(raw) ~= 0;
        disp_m = real(raw); disp_m(is_cx) = NaN;

        ax = nexttile((iAlt-1)*2 + iM);
        plot_heatmap(ax, mach_g, delta_g, disp_m, is_cx, ...
            VALID_MACH(VALID_KFT == altKft(iAlt)), ...
            cCx, mthLbl{iM}, altKft(iAlt), alpha_fixed, ...
            FS_title, FS_axis, FS_lgd, Sf, cf_bar);
    end
end

%% =========================================================
%  FIG E2 - HEATMAP: TRANSONIC/SUPERSONIC SWEEP
%  2 rows x 2 cols
%  White dashed = validated supersonic Mach: 1.58, 1.60
%  Magenta patch = PG complex region
%% =========================================================

figure('Color','w','Position',[70 30 1300 780],'Name','Fig E2 - Heatmap Trans-Sup');
tl2 = tiledlayout(2,2,'TileSpacing','compact','Padding','loose');
title(tl2,'C_h Lookup Table - Transonic/Supersonic Sweep  (M = 0.90 to 1.60)', ...
    'FontSize',12,'FontWeight','bold');

for iAlt = 1:2
    [ChT, ChR, mach_g, delta_g] = build_Ch_table(Sup, altLevels(iAlt), ...
        alpha_fixed, Sf, cf_bar, MACH_TOL, ALT_TOL);

    for iM = 1:2
        if iM==1, raw = ChT; else, raw = ChR; end
        is_cx  = imag(raw) ~= 0;
        disp_m = real(raw); disp_m(is_cx) = NaN;

        ax = nexttile((iAlt-1)*2 + iM);
        plot_heatmap(ax, mach_g, delta_g, disp_m, is_cx, ...
            VALID_MACH(VALID_KFT == altKft(iAlt)), ...
            cCx, mthLbl{iM}, altKft(iAlt), alpha_fixed, ...
            FS_title, FS_axis, FS_lgd, Sf, cf_bar);
    end
end

%% =========================================================
%  FIG E3 - MACH SENSITIVITY (full envelope, SUB + SUP merged)
%  One curve per (method, altitude). Complex flagged with x.
%% =========================================================

condAll  = unique([All.Mach, All.Altitude], 'rows');
n_cond   = size(condAll, 1);
ChT_sens = NaN(n_cond,1);
ChR_sens = NaN(n_cond,1);

for ic = 1:n_cond
    q   = compute_q(condAll(ic,1), condAll(ic,2));
    mask = abs(All.Mach     - condAll(ic,1)) < MACH_TOL & ...
           abs(All.Altitude - condAll(ic,2)) < ALT_TOL  & ...
           abs(All.alpha    - alpha_fixed)   < 0.1      & ...
           abs(All.delta    - delta_fixed)   < 0.5;
    if any(mask)
        ChT_sens(ic) = mean(All.M_Tornado(mask)) / (q*Sf*cf_bar);
        ChR_sens(ic) = mean(All.Ma_Roskam(mask)) / (q*Sf*cf_bar);
    end
end

cxT = imag(ChT_sens) ~= 0;
cxR = imag(ChR_sens) ~= 0;
ChT_p = real(ChT_sens);
ChR_p = real(ChR_sens);

figure('Color','w','Position',[100 100 900 520],'Name','Fig E3 - Mach Sensitivity');
hold on; grid on; box on;

ls_styles = {'-o','--^'};
sc_T = [1.0, 0.60];
sc_R = [1.0, 0.60];

for iAlt = 1:2
    mk  = abs(condAll(:,2) - altLevels(iAlt)) < ALT_TOL;
    if ~any(mk), continue; end
    cT = cTornado * sc_T(iAlt);
    cR = cRoskam  * sc_R(iAlt);
    ls = ls_styles{iAlt};
    plot(condAll(mk,1), ChT_p(mk), ls, 'Color',cT,'LineWidth',LW, ...
         'MarkerFaceColor',cT,'MarkerSize',6, ...
         'DisplayName',sprintf('Tornado  h = %d kft', altKft(iAlt)));
    plot(condAll(mk,1), ChR_p(mk), strrep(ls,'o','s'), ...
         'Color',cR,'LineWidth',LW,'MarkerFaceColor',cR,'MarkerSize',6, ...
         'DisplayName',sprintf('Roskam   h = %d kft', altKft(iAlt)));
end

% -- FIX B (CORRECTED): use HandleVisibility instead of DisplayName='off'
% so that only ONE legend entry appears for the complex marker symbol,
% regardless of how many complex points exist in the sweep.
cx_leg = false;
for ic = 1:n_cond
    if cxT(ic)
        if ~cx_leg
            plot(condAll(ic,1), ChT_p(ic), 'x', 'Color',cCx, 'MarkerSize',13, ...
                 'LineWidth',2.5, 'DisplayName','Complex Re[C_h] (PG, M>1)');
            cx_leg = true;
        else
            plot(condAll(ic,1), ChT_p(ic), 'x', 'Color',cCx, 'MarkerSize',13, ...
                 'LineWidth',2.5, 'HandleVisibility','off');
        end
    end
    if cxR(ic)
        if ~cx_leg
            plot(condAll(ic,1), ChR_p(ic), 'x', 'Color',cCx, 'MarkerSize',13, ...
                 'LineWidth',2.5, 'DisplayName','Complex Re[C_h] (PG, M>1)');
            cx_leg = true;
        else
            plot(condAll(ic,1), ChR_p(ic), 'x', 'Color',cCx, 'MarkerSize',13, ...
                 'LineWidth',2.5, 'HandleVisibility','off');
        end
    end
end
% -------------------------------------------------------------------------

% Boundary between sweeps
xline(0.89,'k:','LineWidth',1.4,'DisplayName','Sub / Trans boundary');
% M=1 reference
xline(1.00,'k--','LineWidth',1.2,'DisplayName','M = 1.0 (sonic)');

% Validated conditions
vstyles = {'--','-.',':', '-'};
for kv = 1:4
    xline(VALID_MACH(kv), vstyles{kv}, 'LineWidth',1.8, 'Color',cValid{kv}, ...
          'DisplayName',sprintf('Case %s  M=%.2f', VALID_LBL{kv}, VALID_MACH(kv)));
end

xlabel('Mach number  M','FontSize',FS_axis);
ylabel('C_h  (-)','FontSize',FS_axis);
title({'Mach Sensitivity of  C_h  -  Full Envelope (Subsonic + Trans/Sup sweeps)', ...
       sprintf('\\alpha = %.1f deg,  \\delta = %.0f deg', alpha_fixed, delta_fixed)}, ...
    'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
legend('Location','best','FontSize',FS_lgd,'Box','off');
set(gca,'FontSize',FS_axis,'LineWidth',0.9);

%% =========================================================
%  FIG E4 - Ch vs DELTA: multi-Mach overlay
%  Two panels (one per altitude). Each curve = one Mach value.
%  -- FIX C: legend added; colormap index normalised to actual
%     Mach value so line colours match the colorbar ticks --
%% =========================================================

% Helper: map a Mach value to the right row in turbo(256)
% MATLAB does not allow chained () indexing in one expression, so we use
% a two-step nested function via subsref.
mach2col = @(m, mlo, mhi) subsref( turbo(256), ...
    struct('type','()','subs', ...
           {{max(1, min(256, round((m-mlo)/max(mhi-mlo,eps)*255)+1)), ':'}}));

% ---- Subsonic ----
figure('Color','w','Position',[120 80 1300 500],'Name','Fig E4 - Ch vs delta (sub)');
tl4s = tiledlayout(1,2,'TileSpacing','loose','Padding','loose');
title(tl4s,'C_h vs \delta -- Subsonic Sweep (all Mach values)', ...
    'FontSize',12,'FontWeight','bold','Interpreter','tex');

for iAlt = 1:2
    [ChT, ChR, mach_g, delta_g] = build_Ch_table(Sub, altLevels(iAlt), ...
        alpha_fixed, Sf, cf_bar, MACH_TOL, ALT_TOL);
    mlo = min(mach_g);  mhi = max(mach_g);

    ax4 = nexttile(iAlt);
    hold on; grid on; box on;
    yline(0,'--','Color',[0.7 0.7 0.7],'LineWidth',1.2,'HandleVisibility','off');

    for im = 1:numel(mach_g)
        isV    = any(abs(VALID_MACH - mach_g(im)) < MACH_TOL & ...
                     abs(VALID_KFT  - altKft(iAlt)) < 1);
        lw_now = LW + 0.8*isV;
        ls_now = '-'; if isV, ls_now = '--'; end
        % Colour consistent with colorbar: normalise actual Mach value
        col = mach2col(mach_g(im), mlo, mhi);
        plot(delta_g, real(ChT(:,im)), ls_now, 'Color', col*0.85, ...
             'LineWidth',lw_now, 'HandleVisibility','off');
        plot(delta_g, real(ChR(:,im)), ':', 'Color', col*0.55, ...
             'LineWidth',lw_now, 'HandleVisibility','off');
    end

    % -- FIX C: proxy legend (style only; colour explained by colorbar) --
    h_pT = plot(NaN,NaN,'-' ,'Color',[0.25 0.25 0.25],'LineWidth',LW);
    h_pR = plot(NaN,NaN,':' ,'Color',[0.25 0.25 0.25],'LineWidth',LW);
    h_pV = plot(NaN,NaN,'--','Color',[0.25 0.25 0.25],'LineWidth',LW+0.8);
    legend(ax4, [h_pT, h_pR, h_pV], ...
           {'Tornado','Roskam','Validated M (bold dashed)'}, ...
           'Location','best','FontSize',FS_lgd,'Box','off');
    % ---------------------------------------------------------------------

    xlabel(ax4,'\delta  (deg)','FontSize',FS_axis,'Interpreter','tex');
    ylabel(ax4,'C_h  (-)','FontSize',FS_axis);
    title(ax4,sprintf('h = %d kft,  \\alpha = %.1f deg', altKft(iAlt), alpha_fixed), ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
    cb4 = colorbar(ax4); colormap(ax4,'turbo');
    clim(ax4,[mlo mhi]);
    cb4.Label.String = 'Mach number'; cb4.Label.FontSize = FS_axis;
    set(ax4,'FontSize',FS_axis,'LineWidth',0.9);
end

% ---- Transonic / Supersonic ----
figure('Color','w','Position',[140 60 1300 500],'Name','Fig E4b - Ch vs delta (sup)');
tl4p = tiledlayout(1,2,'TileSpacing','loose','Padding','loose');
title(tl4p,'C_h vs \delta - Trans/Supersonic Sweep (all Mach values)', ...
    'FontSize',12,'FontWeight','bold','Interpreter','tex');

for iAlt = 1:2
    [ChT, ChR, mach_g, delta_g] = build_Ch_table(Sup, altLevels(iAlt), ...
        alpha_fixed, Sf, cf_bar, MACH_TOL, ALT_TOL);
    mlo = min(mach_g);  mhi = max(mach_g);

    ax4b = nexttile(iAlt);
    hold on; grid on; box on;
    yline(0,'--','Color',[0.7 0.7 0.7],'LineWidth',1.2,'HandleVisibility','off');

    has_cx_curves = false;
    for im = 1:numel(mach_g)
        cx_col = any(imag(ChR(:,im)) ~= 0);
        col    = mach2col(mach_g(im), mlo, mhi);
        isV    = any(abs(VALID_MACH - mach_g(im)) < MACH_TOL & ...
                     abs(VALID_KFT  - altKft(iAlt)) < 1);
        lw_now = LW + 0.8*isV;
        plot(delta_g, real(ChT(:,im)),'-','Color',col*0.85,'LineWidth',lw_now, ...
             'HandleVisibility','off');
        if cx_col
            plot(delta_g, real(ChR(:,im)),'x:','Color',cCx,'LineWidth',lw_now, ...
                 'MarkerSize',7,'HandleVisibility','off');
            has_cx_curves = true;
        else
            plot(delta_g, real(ChR(:,im)),':','Color',col*0.55,'LineWidth',lw_now, ...
                 'HandleVisibility','off');
        end
    end

    % -- FIX C: proxy legend --
    h_pT  = plot(NaN,NaN,'-' ,'Color',[0.25 0.25 0.25],'LineWidth',LW);
    h_pR  = plot(NaN,NaN,':' ,'Color',[0.25 0.25 0.25],'LineWidth',LW);
    h_pV  = plot(NaN,NaN,'--','Color',[0.25 0.25 0.25],'LineWidth',LW+0.8);
    leg_h = [h_pT, h_pR, h_pV];
    leg_s = {'Tornado','Roskam','Validated M (bold)'};
    if has_cx_curves
        h_cx = plot(NaN,NaN,'x:','Color',cCx,'LineWidth',LW,'MarkerSize',7);
        leg_h(end+1) = h_cx;
        leg_s{end+1} = 'Roskam complex (Re only)';
    end
    legend(ax4b, leg_h, leg_s, 'Location','best','FontSize',FS_lgd,'Box','off');
    % -------------------------

    xlabel(ax4b,'\delta  (deg)','FontSize',FS_axis,'Interpreter','tex');
    ylabel(ax4b,'C_h  (-)','FontSize',FS_axis);
    title(ax4b,sprintf('h = %d kft,  \\alpha = %.1f deg', altKft(iAlt), alpha_fixed), ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
    cb4b = colorbar(ax4b); colormap(ax4b,'turbo');
    clim(ax4b,[mlo mhi]);
    cb4b.Label.String = 'Mach number'; cb4b.Label.FontSize = FS_axis;
    set(ax4b,'FontSize',FS_axis,'LineWidth',0.9);
end

%% =========================================================
%  FIG E5 - ROSKAM-TORNADO DIVERGENCE
%  Delta_Ch = Ch_Roskam - Ch_Tornado vs Mach
%  One panel per altitude; curves = fixed delta values
%  -- FIX D: capture delta_g_sub from build_Ch_table (was discarded
%     with ~) to guarantee consistent row indexing into ChT_s/ChR_s --
%  -- FIX E: M>=1 shaded patch drawn AFTER data and sized to actual
%     y-axis limits (was hardcoded before data, often clipped) --
%% =========================================================

delta_plot_vals = [-15, -10, -5, 0, 5, 10, 15];

figure('Color','w','Position',[160 50 1200 480],'Name','Fig E5 - Divergence');
tl5 = tiledlayout(1,2,'TileSpacing','loose','Padding','loose');
title(tl5,'\DeltaC_h = C_{h,Roskam} - C_{h,Tornado} vs Mach  (full envelope)', ...
    'FontSize',12,'FontWeight','bold','Interpreter','tex');

for iAlt = 1:2
    % -- FIX D: capture delta grid for Sub (was ~) --------------------
    [ChT_s, ChR_s, mach_sub, delta_g_sub] = build_Ch_table(Sub, altLevels(iAlt), ...
        alpha_fixed, Sf, cf_bar, MACH_TOL, ALT_TOL);
    [ChT_p2, ChR_p2, mach_sup, delta_g2] = build_Ch_table(Sup, altLevels(iAlt), ...
        alpha_fixed, Sf, cf_bar, MACH_TOL, ALT_TOL);
    % -----------------------------------------------------------------

    % Common delta subset using the grids already returned
    delta_common = intersect(delta_g_sub, delta_g2);
    delta_show   = intersect(delta_common, delta_plot_vals);
    if isempty(delta_show)          % fallback: use whatever is common
        delta_show = delta_common;
    end

    mach_full = [mach_sub; mach_sup];

    ax5 = nexttile(iAlt);
    hold on; grid on; box on;
    yline(0,'--','Color',[0.6 0.6 0.6],'LineWidth',1.2,'HandleVisibility','off');

    cmap5 = parula(numel(delta_show));
    for id3 = 1:numel(delta_show)
        dv = delta_show(id3);

        % Sub contribution — index into delta_g_sub (FIX D)
        id_sub = find(abs(delta_g_sub - dv) < 0.5, 1);
        if ~isempty(id_sub)
            dCh_sub = real(ChR_s(id_sub,:)) - real(ChT_s(id_sub,:));
            plot(ax5, mach_sub, dCh_sub, '-o', 'Color', cmap5(id3,:), ...
                 'LineWidth',LW-0.3,'MarkerSize',5,'MarkerFaceColor',cmap5(id3,:), ...
                 'DisplayName', sprintf('\\delta = %+.0f deg', dv));
        end

        % Sup contribution — index into delta_g2
        id_sup = find(abs(delta_g2 - dv) < 0.5, 1);
        if ~isempty(id_sup)
            dCh_sup = real(ChR_p2(id_sup,:)) - real(ChT_p2(id_sup,:));
            plot(ax5, mach_sup, dCh_sup, '--^', 'Color', cmap5(id3,:), ...
                 'LineWidth',LW-0.3,'MarkerSize',5,'MarkerFaceColor',cmap5(id3,:), ...
                 'HandleVisibility','off');
        end
    end

    xline(ax5,0.89,'k:','LineWidth',1.2,'HandleVisibility','off');
    xline(ax5,1.00,'k--','LineWidth',1.2,'DisplayName','M = 1.0 (sonic)');
    for kv = 1:4
        if abs(VALID_KFT(kv) - altKft(iAlt)) < 1
            xline(ax5, VALID_MACH(kv), 'LineWidth',1.6,'Color',cValid{kv}, ...
                  'DisplayName',sprintf('Case %s', VALID_LBL{kv}));
        end
    end

    % -- FIX E: draw M>=1 patch AFTER data so y-limits are real -------
    yl_act = ylim(ax5);
    xl_act = xlim(ax5);
    x_patch_lo = max(1.0, xl_act(1));
    x_patch_hi = max(mach_full);
    if x_patch_hi > x_patch_lo
        hp = patch(ax5, ...
                   [x_patch_lo x_patch_hi x_patch_hi x_patch_lo], ...
                   [yl_act(1)  yl_act(1)  yl_act(2)  yl_act(2)], ...
                   cCx, 'FaceAlpha',0.10,'EdgeColor','none', ...
                   'HandleVisibility','off');
        uistack(hp,'bottom');   % keep patch behind curves
    end
    ylim(ax5, yl_act);          % restore limits after patch
    % -----------------------------------------------------------------

    xlabel(ax5,'Mach number  M','FontSize',FS_axis);
    ylabel(ax5,'\DeltaC_h  = C_{h,Ros} - C_{h,Tor}  (-)','FontSize',FS_axis,'Interpreter','tex');
    title(ax5, sprintf('h = %d kft,  \\alpha = %.1f deg', altKft(iAlt), alpha_fixed), ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');

    % Add style proxy for sub vs sup marker style
    h_sub = plot(ax5,NaN,NaN,'-o','Color',[0.4 0.4 0.4],'LineWidth',LW-0.3,'MarkerSize',5,'MarkerFaceColor',[0.4 0.4 0.4]);
    h_sup = plot(ax5,NaN,NaN,'--^','Color',[0.4 0.4 0.4],'LineWidth',LW-0.3,'MarkerSize',5,'MarkerFaceColor',[0.4 0.4 0.4]);

    leg5 = legend(ax5,'Location','best','FontSize',FS_lgd,'Box','off');
    % Replace last two auto-generated entries with clean labels
    leg5.String{end-1} = 'Subsonic range';
    leg5.String{end}   = 'Trans/Sup range';

    set(ax5,'FontSize',FS_axis,'LineWidth',0.9);
end

fprintf('\nAll extended exploration figures generated.\n');

%% =========================================================
%  LOCAL FUNCTIONS
%% =========================================================

function q = compute_q(M, h_m)
    [~, T, rho, ~] = isa_atm(h_m);
    a = sqrt(1.4 * 287 * T);
    q = 0.5 * rho * (M * a)^2;
end

function [ChT, ChR, mach_g, delta_g] = build_Ch_table(S, h_alt, alpha_s, ...
                                          Sf, cf_bar, MACH_TOL, ALT_TOL)
    SubH    = S(abs(S.Altitude - h_alt) < ALT_TOL, :);
    mach_g  = unique(SubH.Mach);
    delta_g = unique(SubH.delta);
    n_m     = numel(mach_g);
    n_d     = numel(delta_g);
    ChT     = NaN(n_d, n_m);
    ChR     = NaN(n_d, n_m);
    for im = 1:n_m
        q = compute_q(mach_g(im), h_alt);
        for id2 = 1:n_d
            mask = abs(SubH.Mach  - mach_g(im))  < MACH_TOL & ...
                   abs(SubH.delta - delta_g(id2)) < 0.5      & ...
                   abs(SubH.alpha - alpha_s)       < 0.1;
            if any(mask)
                ChT(id2,im) = mean(SubH.M_Tornado(mask)) / (q*Sf*cf_bar);
                ChR(id2,im) = mean(SubH.Ma_Roskam(mask)) / (q*Sf*cf_bar);
            end
        end
    end
end

function plot_heatmap(ax, mach_g, delta_g, disp_m, is_cx, valid_machs, ...
                      cCx, mth_label, alt_kft, alpha_s, ...
                      FS_title, FS_axis, FS_lgd, Sf, cf_bar) %#ok<INUSD>
    valid_machs  = valid_machs(:);
    MACH_TOL_L   = 0.015;
    MAX_HALF_GAP = 0.065;
    N_FINE_M     = 300;   % Mach resolution of interpolated display grid

    % ---- 1. Smooth interpolation in Mach direction ----------------------
    if numel(mach_g) > 2
        mach_fine = linspace(min(mach_g), max(mach_g), N_FINE_M)';
        [Mg, Dg]  = meshgrid(mach_g,    delta_g);
        [Mf, ~]   = meshgrid(mach_fine, delta_g);
        disp_fine = interp2(Mg, Dg, double(disp_m), Mf, ...
                            meshgrid(delta_g, mach_fine)', 'linear');
        far_mask = min(abs(mach_fine(:)' - mach_g(:)), [], 1) > MAX_HALF_GAP;
        disp_fine(:, far_mask) = NaN;
    else
        mach_fine = mach_g;
        disp_fine = disp_m;
    end

    % ---- 2. Color limits (real, valid values only) ----------------------
    valid_v = disp_fine(~isnan(disp_fine));
    if isempty(valid_v), cl = [-0.01 0.01];
    else
        cl = [min(valid_v) max(valid_v)];
        if diff(cl) == 0, cl = cl + [-0.01 0.01]; end
    end

    imagesc(ax, mach_fine, delta_g, disp_fine);
    set(ax,'YDir','normal','Color',[0.82 0.82 0.82]);
    colormap(ax,'turbo'); clim(ax, cl);
    cb = colorbar(ax); cb.Label.String = 'C_h  (-)'; cb.Label.FontSize = FS_axis;
    hold(ax,'on');

    % ---- 3. Magenta overlay: one patch per CONTIGUOUS complex block -----
    has_cx  = false;
    cx_cols = any(is_cx, 1);
    cx_idx  = find(cx_cols);

    if ~isempty(cx_idx)
        has_cx = true;

        if numel(delta_g) > 1
            dd = mean(diff(delta_g)) / 2;
        else
            dd = 1;
        end
        y_lo = delta_g(1) - dd;   y_hi = delta_g(end) + dd;

        d_idx           = diff(cx_idx);
        brk             = find(d_idx > 1);
        block_start_idx = cx_idx([1,  brk+1]);
        block_end_idx   = cx_idx([brk, end]);

        for ib = 1:numel(block_start_idx)
            iL = block_start_idx(ib);
            iR = block_end_idx(ib);

            if iL > 1
                m_lo_p = (mach_g(iL-1) + mach_g(iL)) / 2;
            elseif numel(mach_g) > 1
                m_lo_p = mach_g(iL) - mean(diff(mach_g)) / 2;
            else
                m_lo_p = mach_g(iL) - 0.02;
            end

            if iR < numel(mach_g)
                m_hi_p = (mach_g(iR) + mach_g(iR+1)) / 2;
            elseif numel(mach_g) > 1
                m_hi_p = mach_g(iR) + mean(diff(mach_g)) / 2;
            else
                m_hi_p = mach_g(iR) + 0.02;
            end

            patch(ax, [m_lo_p m_hi_p m_hi_p m_lo_p], ...
                      [y_lo   y_lo   y_hi   y_hi  ], ...
                  cCx, 'FaceAlpha',0.35, 'EdgeColor',cCx, ...
                  'LineWidth',1.2, 'HandleVisibility','off');
        end
    end

    % ---- 4. White dashed lines for validated conditions -----------------
    val_in_range = valid_machs( ...
        arrayfun(@(vm) any(abs(mach_g - vm) < MACH_TOL_L), valid_machs) );
    for kv = 1:numel(val_in_range)
        xline(ax, val_in_range(kv), 'w--', 'LineWidth',2.2, 'HandleVisibility','off');
    end

    xlabel(ax,'Mach number','FontSize',FS_axis);
    ylabel(ax,'\delta  (deg)','FontSize',FS_axis,'Interpreter','tex');
    title(ax, {sprintf('%s  --  h = %d kft', mth_label, alt_kft), ...
               sprintf('\\alpha = %.1f deg  |  white dashed = validated M', alpha_s)}, ...
        'FontSize',FS_title,'FontWeight','bold','Interpreter','tex');
    set(ax,'FontSize',FS_axis,'LineWidth',0.9);

    % ---- 5. Legend (always shown) ---------------------------------------
    leg_h = [];  leg_s = {};

    if ~isempty(val_in_range)
        leg_h(end+1) = plot(ax, NaN, NaN, 'w--', 'LineWidth', 2.2);
        leg_s{end+1} = sprintf('Validated M (%s)', ...
            strjoin(arrayfun(@(v) sprintf('%.2f',v), val_in_range(:)', ...
                             'UniformOutput',false), ', '));
    end

    if has_cx
        leg_h(end+1) = patch(ax, NaN, NaN, cCx, 'FaceAlpha',0.35, ...
                             'EdgeColor',cCx, 'LineWidth',1.2);
        leg_s{end+1} = 'Complex Re[C_h] (PG breakdown, M>1)';
    end

    if ~isempty(leg_h)
        legend(ax, leg_h, leg_s, 'Location','southoutside', ...
               'FontSize',FS_lgd, 'Box','off', 'Orientation','horizontal');
    end
end

function T = isa_temp(alt_m)
    T0=288.15; L=0.0065; H=11000;
    if alt_m<=H, T=T0-L*alt_m; else, T=216.65; end
end

function [p,T,rho,a] = isa_atm(alt_m)
    T=isa_temp(alt_m); p0=101325; T0=288.15; L=0.0065;
    R=287.058; g0=9.80665; H=11000;
    if alt_m<=H, p=p0*(T/T0)^(g0/(L*R));
    else, p=p0*(216.65/T0)^(g0/(L*R))*exp(-g0*(alt_m-H)/(R*216.65)); end
    rho=p/(R*T); a=sqrt(1.4*R*T);
end