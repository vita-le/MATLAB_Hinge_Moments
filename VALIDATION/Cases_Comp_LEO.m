clc; clear; close all;

%% =========================================================
%  SUPERSONIC VALIDATION - F/A-18 SRA AILERON HINGE MOMENT
%
%  Cases:
%    C: M = 1.58, h = 34 kft, aileron reversal (half stick)
%    D: M = 1.60, h = 34 kft, abrupt reversal (full right stick)
%
%  Models:
%    SUP_CONE_MASK
%    SUP_MIRANDA_KJ

%% ---------------- USER SETTINGS ----------------
SUMMARY_FILE = '..\Summary_LEO.mat';
DATA_FOLDER  = 'Nasa_Chak';

MODEL_CONE    = "SUP_CONE_MASK";
MODEL_MIRANDA = "SUP_MIRANDA_KJ";

MACH_C = 1.58;
MACH_D = 1.60;
ALT_34KFT_M = 10363.2;

MACH_TOL  = 0.01;
ALT_TOL   = 50;
ALPHA_TOL = 1e-8;

% ---------------------------------------------------------
% ANGLE-OF-ATTACK HANDLING
%
% "FIT_SEPARATELY"
%   Each aerodynamic model is allowed to choose the constant alpha that
%   minimises its own RMS error against the flight hinge-moment history.
%
% "FIT_COMMON_PER_CASE"
%   One common constant alpha is selected for both models in each case.
%
% "FIXED_PER_CASE"
%   Both models use the same user-specified alpha for a given flight case.
ALPHA_MODE = "FIXED_PER_CASE";

% Used only when ALPHA_MODE = "FIXED_PER_CASE"
ALPHA_FIXED_C = 4.0;   % deg
ALPHA_FIXED_D = -2.0;   % deg

% Correct for 10^3 in*lbf -> N*m. Verify the reference-figure units.
REF_MOMENT_TO_NM = 112.985;

%% ---------------- LOAD SUMMARY ----------------
fprintf('Loading %s...\n', SUMMARY_FILE);
S = load(SUMMARY_FILE, 'Summary');
if ~isfield(S,'Summary')
    error('The MAT file does not contain a variable named Summary.');
end
Summary = S.Summary;

requiredVars = ["CompModel","Mach","Altitude","alpha","delta","M_Tornado"];
missingVars = requiredVars(~ismember(requiredVars,string(Summary.Properties.VariableNames)));
if ~isempty(missingVars)
    error('Summary is missing required columns: %s', strjoin(missingVars, ', '));
end
Summary.CompModel = string(Summary.CompModel);

%% ---------------- FILTER CASES AND MODELS ----------------
SubC_Cone = filter_summary(Summary,MACH_C,ALT_34KFT_M,MODEL_CONE,MACH_TOL,ALT_TOL);
SubC_Mir  = filter_summary(Summary,MACH_C,ALT_34KFT_M,MODEL_MIRANDA,MACH_TOL,ALT_TOL);
SubD_Cone = filter_summary(Summary,MACH_D,ALT_34KFT_M,MODEL_CONE,MACH_TOL,ALT_TOL);
SubD_Mir  = filter_summary(Summary,MACH_D,ALT_34KFT_M,MODEL_MIRANDA,MACH_TOL,ALT_TOL);

fprintf('Case C cone-mask rows: %d\n',height(SubC_Cone));
fprintf('Case C Miranda rows:   %d\n',height(SubC_Mir));
fprintf('Case D cone-mask rows: %d\n',height(SubD_Cone));
fprintf('Case D Miranda rows:   %d\n',height(SubD_Mir));

assert_nonempty(SubC_Cone,'Case C / SUP_CONE_MASK');
assert_nonempty(SubC_Mir, 'Case C / SUP_MIRANDA_KJ');
assert_nonempty(SubD_Cone,'Case D / SUP_CONE_MASK');
assert_nonempty(SubD_Mir, 'Case D / SUP_MIRANDA_KJ');

%% ---------------- LOAD REFERENCE DATA ----------------
loadCSV = @(name) sortrows(readmatrix(fullfile(DATA_FOLDER,name)),1);

DefC = loadCSV('caseC_Deflection.csv');
DefD = loadCSV('caseD_Deflection.csv');
FltC = loadCSV('caseC_Moment_Flight.csv');
FltD = loadCSV('caseD_Moment_Flight.csv');

check_two_columns(DefC,'caseC_Deflection.csv');
check_two_columns(DefD,'caseD_Deflection.csv');
check_two_columns(FltC,'caseC_Moment_Flight.csv');
check_two_columns(FltD,'caseD_Moment_Flight.csv');

FltC(:,2) = FltC(:,2)*REF_MOMENT_TO_NM;
FltD(:,2) = FltD(:,2)*REF_MOMENT_TO_NM;

tC = DefC(:,1); deltaC = DefC(:,2);
tD = DefD(:,1); deltaD = DefD(:,2);

fprintf('\nMeasured deflection ranges:\n');
fprintf('  Case C: %.2f to %.2f deg\n',min(deltaC),max(deltaC));
fprintf('  Case D: %.2f to %.2f deg\n\n',min(deltaD),max(deltaD));

%% ---------------- COMMON TIME GRIDS ----------------
[tC_common,FltC_common,deltaC_common] = build_common_grid(tC,deltaC,FltC);
[tD_common,FltD_common,deltaD_common] = build_common_grid(tD,deltaD,FltD);

%% ---------------- ANGLE-OF-ATTACK DIAGNOSTICS ----------------
alphas_C_Cone = unique(SubC_Cone.alpha);
alphas_C_Mir  = unique(SubC_Mir.alpha);
alphas_D_Cone = unique(SubD_Cone.alpha);
alphas_D_Mir  = unique(SubD_Mir.alpha);

[rms_C_Cone,~,alphaFit_C_Cone,rmsFit_C_Cone] = ...
    sweep_alpha(SubC_Cone,alphas_C_Cone,deltaC_common,FltC_common,ALPHA_TOL);
[rms_C_Mir,~,alphaFit_C_Mir,rmsFit_C_Mir] = ...
    sweep_alpha(SubC_Mir,alphas_C_Mir,deltaC_common,FltC_common,ALPHA_TOL);
[rms_D_Cone,~,alphaFit_D_Cone,rmsFit_D_Cone] = ...
    sweep_alpha(SubD_Cone,alphas_D_Cone,deltaD_common,FltD_common,ALPHA_TOL);
[rms_D_Mir,~,alphaFit_D_Mir,rmsFit_D_Mir] = ...
    sweep_alpha(SubD_Mir,alphas_D_Mir,deltaD_common,FltD_common,ALPHA_TOL);

fprintf('Independent diagnostic fits:\n');
fprintf('  Case C / Cone:    alpha = %+.2f deg, RMS = %.2f Nm\n',alphaFit_C_Cone,rmsFit_C_Cone);
fprintf('  Case C / Miranda: alpha = %+.2f deg, RMS = %.2f Nm\n',alphaFit_C_Mir,rmsFit_C_Mir);
fprintf('  Case D / Cone:    alpha = %+.2f deg, RMS = %.2f Nm\n',alphaFit_D_Cone,rmsFit_D_Cone);
fprintf('  Case D / Miranda: alpha = %+.2f deg, RMS = %.2f Nm\n\n',alphaFit_D_Mir,rmsFit_D_Mir);

%% ---------------- SELECT ALPHA VALUES USED IN THE PLOTS ----------------
switch upper(string(ALPHA_MODE))

    case "FIT_SEPARATELY"
        % Diagnostic only: each model is tuned independently.
        alpha_C_Cone = alphaFit_C_Cone;
        alpha_C_Mir  = alphaFit_C_Mir;
        alpha_D_Cone = alphaFit_D_Cone;
        alpha_D_Mir  = alphaFit_D_Mir;

    case "FIT_COMMON_PER_CASE"
        % One fitted alpha per flight case, shared by both methods.
        [alphaCommon_C,combinedRms_C] = fit_common_alpha( ...
            SubC_Cone,SubC_Mir,deltaC_common,FltC_common,ALPHA_TOL);

        [alphaCommon_D,combinedRms_D] = fit_common_alpha( ...
            SubD_Cone,SubD_Mir,deltaD_common,FltD_common,ALPHA_TOL);

        alpha_C_Cone = alphaCommon_C;
        alpha_C_Mir  = alphaCommon_C;
        alpha_D_Cone = alphaCommon_D;
        alpha_D_Mir  = alphaCommon_D;

        fprintf('Common-alpha fit:\n');
        fprintf('  Case C: alpha = %+.2f deg, combined RMS = %.2f Nm\n', ...
                alphaCommon_C,combinedRms_C);
        fprintf('  Case D: alpha = %+.2f deg, combined RMS = %.2f Nm\n\n', ...
                alphaCommon_D,combinedRms_D);

    case "FIXED_PER_CASE"
        % Preferred when alpha comes from an independent flight-test source.
        alpha_C_Cone = ALPHA_FIXED_C;
        alpha_C_Mir  = ALPHA_FIXED_C;
        alpha_D_Cone = ALPHA_FIXED_D;
        alpha_D_Mir  = ALPHA_FIXED_D;

    otherwise
        error('Unknown ALPHA_MODE: %s',ALPHA_MODE);
end

fprintf('Alpha values actually used in predictions [%s]:\n',ALPHA_MODE);
fprintf('  Case C: Cone = %+.2f deg, Miranda = %+.2f deg\n', ...
        alpha_C_Cone,alpha_C_Mir);
fprintf('  Case D: Cone = %+.2f deg, Miranda = %+.2f deg\n\n', ...
        alpha_D_Cone,alpha_D_Mir);

%% ---------------- PREDICTED TIME HISTORIES ----------------
MC_Cone = interpolate_moment(SubC_Cone,alpha_C_Cone,deltaC,ALPHA_TOL);
MC_Mir  = interpolate_moment(SubC_Mir, alpha_C_Mir, deltaC,ALPHA_TOL);
MD_Cone = interpolate_moment(SubD_Cone,alpha_D_Cone,deltaD,ALPHA_TOL);
MD_Mir  = interpolate_moment(SubD_Mir, alpha_D_Mir, deltaD,ALPHA_TOL);

MC_Cone_common = interpolate_moment(SubC_Cone,alpha_C_Cone,deltaC_common,ALPHA_TOL);
MC_Mir_common  = interpolate_moment(SubC_Mir, alpha_C_Mir, deltaC_common,ALPHA_TOL);
MD_Cone_common = interpolate_moment(SubD_Cone,alpha_D_Cone,deltaD_common,ALPHA_TOL);
MD_Mir_common  = interpolate_moment(SubD_Mir, alpha_D_Mir, deltaD_common,ALPHA_TOL);

met_C_Cone = error_metrics(FltC_common,MC_Cone_common);
met_C_Mir  = error_metrics(FltC_common,MC_Mir_common);
met_D_Cone = error_metrics(FltD_common,MD_Cone_common);
met_D_Mir  = error_metrics(FltD_common,MD_Mir_common);

%% ---------------- FIGURE 1: TIME HISTORIES ----------------
figure('Color','w','Position',[80 60 1450 800], ...
       'Name','Supersonic F-18 hinge-moment validation');
tl = tiledlayout(2,2,'TileSpacing','compact','Padding','loose');

nexttile(1);
plot(tC,deltaC,'LineWidth',2.0); grid on; box on;
xlabel('Time (s)'); ylabel('Aileron deflection (deg)');
title({'(c) Aileron reversal - half stick',sprintf('M = %.2f, h = 34 kft',MACH_C)});
xlim([tC(1) tC(end)]);

nexttile(2);
plot(tD,deltaD,'LineWidth',2.0); grid on; box on;
xlabel('Time (s)'); ylabel('Aileron deflection (deg)');
title({'(d) Abrupt reversal - full right stick',sprintf('M = %.2f, h = 34 kft',MACH_D)});
xlim([tD(1) tD(end)]);

nexttile(3);
hold on; grid on; box on;
plot(FltC(:,1),FltC(:,2),'LineWidth',2.5,'DisplayName','NASA flight');
plot(tC,real(MC_Cone),'LineWidth',2.0, ...
    'DisplayName',sprintf('SUP CONE MASK, alpha=%+.1f deg',alpha_C_Cone));
plot(tC,real(MC_Mir),'LineWidth',2.0, ...
    'DisplayName',sprintf('SUP MIRANDA KJ, alpha=%+.1f deg',alpha_C_Mir));
xlabel('Time (s)'); ylabel('Hinge moment (N m)');
title(sprintf('(c) Measured vs predicted, M = %.2f',MACH_C));
legend('Location','best','Box','off'); xlim([tC(1) tC(end)]);

nexttile(4);
hold on; grid on; box on;
plot(FltD(:,1),FltD(:,2),'LineWidth',2.5,'DisplayName','NASA flight');
plot(tD,real(MD_Cone),'LineWidth',2.0, ...
    'DisplayName',sprintf('SUP CONE MASK, alpha=%+.1f deg',alpha_D_Cone));
plot(tD,real(MD_Mir),'LineWidth',2.0, ...
    'DisplayName',sprintf('SUP MIRANDA KJ, alpha=%+.1f deg',alpha_D_Mir));
xlabel('Time (s)'); ylabel('Hinge moment (N m)');
title(sprintf('(d) Measured vs predicted, M = %.2f',MACH_D));
legend('Location','best','Box','off'); xlim([tD(1) tD(end)]);

title(tl,'F/A-18 SRA supersonic aileron hinge-moment validation', ...
      'FontSize',15,'FontWeight','bold');

%% ---------------- FIGURE 2: RMS VS ALPHA ----------------
% figure('Color','w','Position',[120 100 1250 500], ...
%        'Name','Supersonic alpha sensitivity');
% tl2 = tiledlayout(1,2,'TileSpacing','loose','Padding','loose');
% 
% nexttile(1);
% hold on; grid on; box on;
% plot(alphas_C_Cone,rms_C_Cone,'-o','LineWidth',2.0,'DisplayName','SUP CONE MASK');
% plot(alphas_C_Mir,rms_C_Mir,'-s','LineWidth',2.0,'DisplayName','SUP MIRANDA KJ');
% xlabel('alpha (deg)'); ylabel('RMS error (N m)');
% title(sprintf('(c) M = %.2f, h = 34 kft',MACH_C));
% legend('Location','best','Box','off');
% 
% nexttile(2);
% hold on; grid on; box on;
% plot(alphas_D_Cone,rms_D_Cone,'-o','LineWidth',2.0,'DisplayName','SUP CONE MASK');
% plot(alphas_D_Mir,rms_D_Mir,'-s','LineWidth',2.0,'DisplayName','SUP MIRANDA KJ');
% xlabel('alpha (deg)'); ylabel('RMS error (N m)');
% title(sprintf('(d) M = %.2f, h = 34 kft',MACH_D));
% legend('Location','best','Box','off');
% 
% title(tl2,'Sensitivity to the assumed constant angle of attack', ...
%       'FontSize',14,'FontWeight','bold');


%% ---------------- FIGURE 3: RESIDUAL TIME HISTORIES ----------------
% Residual convention:
%       residual = NASA flight - predicted model
%
% The residual is signed. For example, when both moments are negative,
% a model with a smaller absolute magnitude can still produce a negative
% residual. Always interpret the residual together with the original
% hinge-moment plot.

% resC_Cone = FltC_common - real(MC_Cone_common);
% resC_Mir  = FltC_common - real(MC_Mir_common);
% resD_Cone = FltD_common - real(MD_Cone_common);
% resD_Mir  = FltD_common - real(MD_Mir_common);
% 
% figure('Color','w','Position',[140 100 1250 500], ...
%        'Name','Supersonic residual time histories');
% tl3 = tiledlayout(1,2,'TileSpacing','loose','Padding','loose');
% 
% nexttile(1);
% hold on; grid on; box on;
% yline(0,'k--','LineWidth',1.3,'HandleVisibility','off');
% plot(tC_common,resC_Cone,'LineWidth',2.0, ...
%     'DisplayName','Flight - SUP CONE MASK');
% plot(tC_common,resC_Mir,'LineWidth',2.0, ...
%     'DisplayName','Flight - SUP MIRANDA KJ');
% xlabel('Time (s)');
% ylabel('Residual hinge moment (N m)');
% title({sprintf('(c) Residuals, M = %.2f',MACH_C), ...
%        sprintf('Cone RMS = %.0f N m, Miranda RMS = %.0f N m', ...
%                met_C_Cone.RMS,met_C_Mir.RMS)});
% legend('Location','best','Box','off');
% xlim([tC_common(1) tC_common(end)]);
% 
% nexttile(2);
% hold on; grid on; box on;
% yline(0,'k--','LineWidth',1.3,'HandleVisibility','off');
% plot(tD_common,resD_Cone,'LineWidth',2.0, ...
%     'DisplayName','Flight - SUP CONE MASK');
% plot(tD_common,resD_Mir,'LineWidth',2.0, ...
%     'DisplayName','Flight - SUP MIRANDA KJ');
% xlabel('Time (s)');
% ylabel('Residual hinge moment (N m)');
% title({sprintf('(d) Residuals, M = %.2f',MACH_D), ...
%        sprintf('Cone RMS = %.0f N m, Miranda RMS = %.0f N m', ...
%                met_D_Cone.RMS,met_D_Mir.RMS)});
% legend('Location','best','Box','off');
% xlim([tD_common(1) tD_common(end)]);
% 
% title(tl3,'NASA flight minus predicted hinge moment', ...
%       'FontSize',14,'FontWeight','bold');

%% ---------------- CONSOLE SUMMARY ----------------
fprintf('\n==============================================================\n');
fprintf('SUPERSONIC VALIDATION ERROR SUMMARY [N m]\n');
fprintf('==============================================================\n');
fprintf('%-24s %10s %10s %10s\n','Case / model','RMS','MAE','Max abs');
fprintf('--------------------------------------------------------------\n');
print_metrics('C / SUP_CONE_MASK',met_C_Cone);
print_metrics('C / SUP_MIRANDA_KJ',met_C_Mir);
print_metrics('D / SUP_CONE_MASK',met_D_Cone);
print_metrics('D / SUP_MIRANDA_KJ',met_D_Mir);
fprintf('==============================================================\n');

%% =========================================================
%  LOCAL FUNCTIONS
%% =========================================================
function Sub = filter_summary(Summary,Mach,Altitude,ModelName,MachTol,AltTol)
    Sub = Summary(abs(Summary.Mach-Mach)<MachTol & ...
                  abs(Summary.Altitude-Altitude)<AltTol & ...
                  string(Summary.CompModel)==string(ModelName),:);
end

function assert_nonempty(T,label)
    if isempty(T), error('No rows found for %s.',label); end
end

function check_two_columns(A,filename)
    if size(A,2)<2
        error('%s must contain at least two columns: time and value.',filename);
    end
end

function [t_common,flight_common,delta_common] = build_common_grid(def_t,def_delta,flight_data)
    [flight_t,idxF] = unique(flight_data(:,1),'last');
    flight_y = flight_data(idxF,2);
    [def_t_u,idxD] = unique(def_t,'last');
    def_delta_u = def_delta(idxD);

    t_lo = max(min(def_t_u),min(flight_t));
    t_hi = min(max(def_t_u),max(flight_t));
    t_common = def_t_u(def_t_u>=t_lo & def_t_u<=t_hi);

    flight_common = interp1(flight_t,flight_y,t_common,'linear');
    delta_common  = interp1(def_t_u,def_delta_u,t_common,'linear');
end

function M_dyn = interpolate_moment(Sub,alpha_query,delta_query,alpha_tol)
    alpha_values = unique(Sub.alpha);
    [~,iA] = min(abs(alpha_values-alpha_query));
    alpha_used = alpha_values(iA);
    rows = Sub(abs(Sub.alpha-alpha_used)<alpha_tol,:);
    if isempty(rows), error('No rows found at alpha = %.6g deg.',alpha_used); end

    [delta_sorted,idx] = sort(rows.delta);
    moment_sorted = rows.M_Tornado(idx);
    [delta_unique,~,grp] = unique(delta_sorted);
    moment_unique = accumarray(grp,moment_sorted,[],@mean);

    dmin = min(delta_unique); dmax = max(delta_unique);
    if min(delta_query)<dmin || max(delta_query)>dmax
        warning('Measured deflection exceeds lookup range. Clamping to [%.2f, %.2f] deg.',dmin,dmax);
    end
    delta_clamped = min(max(delta_query,dmin),dmax);
    M_dyn = interp1(delta_unique,moment_unique,delta_clamped,'linear');
end

function [rms_values,mean_values,best_alpha,minimum_rms] = ...
        sweep_alpha(Sub,alpha_values,delta_common,flight_common,alpha_tol)
    n = numel(alpha_values);
    rms_values = NaN(n,1); mean_values = NaN(n,1);
    for i=1:n
        pred = interpolate_moment(Sub,alpha_values(i),delta_common,alpha_tol);
        residual = flight_common-real(pred);
        valid = isfinite(residual);
        if any(valid)
            rms_values(i) = sqrt(mean(residual(valid).^2));
            mean_values(i) = mean(residual(valid));
        end
    end
    [minimum_rms,idx] = min(rms_values);
    best_alpha = alpha_values(idx);
end


function [best_alpha,best_score] = ...
        fit_common_alpha(Sub1,Sub2,delta_common,flight_common,alpha_tol)
% FIT_COMMON_ALPHA
% Select one constant alpha shared by two aerodynamic models.
%
% The score is the root-mean-square of the two model RMS errors:
%   score = sqrt((RMS_1^2 + RMS_2^2)/2)

    candidate_alphas = intersect(unique(Sub1.alpha),unique(Sub2.alpha));

    if isempty(candidate_alphas)
        error('The two model tables do not share any alpha values.');
    end

    scores = NaN(numel(candidate_alphas),1);

    for i = 1:numel(candidate_alphas)
        alpha_i = candidate_alphas(i);

        pred1 = interpolate_moment(Sub1,alpha_i,delta_common,alpha_tol);
        pred2 = interpolate_moment(Sub2,alpha_i,delta_common,alpha_tol);

        r1 = flight_common-real(pred1);
        r2 = flight_common-real(pred2);

        valid1 = isfinite(r1);
        valid2 = isfinite(r2);

        rms1 = sqrt(mean(r1(valid1).^2));
        rms2 = sqrt(mean(r2(valid2).^2));

        scores(i) = sqrt(0.5*(rms1^2+rms2^2));
    end

    [best_score,idx] = min(scores);
    best_alpha = candidate_alphas(idx);
end

function out = error_metrics(reference,estimate)
    residual = reference-real(estimate);
    residual = residual(isfinite(residual));
    out.RMS = sqrt(mean(residual.^2));
    out.MAE = mean(abs(residual));
    out.MaxAbs = max(abs(residual));
end

function print_metrics(label,m)
    fprintf('%-24s %10.2f %10.2f %10.2f\n',label,m.RMS,m.MAE,m.MaxAbs);
end
