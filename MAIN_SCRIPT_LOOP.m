%% ========================================================================
%                           MAIN SCRIPT
%             Aircraft Hinge Moment Analysis + Tornado
%
%                 Andrea Vitale 2026 Master´s Thesis
%  ========================================================================

clear; close all; clc;

addpath('Functions')
addpath('Inputs')
addpath('Roskam_Models')
addpath('TORNADO\aircraft\airfoil\')
warning('off', 'backtrace')
addpath('CPACS_in\')


% -------------------- LOAD CONFIGURATION INPUTS -------------------------

GEO_ID = 18.1;
FLY_ID = 1;

Airfoil = Airfoil_config(GEO_ID);
Geo     = readGeoFromCPACS_2("F18SRA_cpacs.xml");

%% ----------- Read airfoil .dat file --------------------------------------

filepath = fullfile('TORNADO', 'aircraft', 'airfoil', Airfoil.filename);
data = readmatrix(filepath);
data = data(~any(isnan(data),2), :);
data = data(data(:,1) >= 0 & data(:,1) <= 1, :);

Airfoil.x = data(:,1);
Airfoil.y = data(:,2);
Airfoil   = Airfoil_Function(Airfoil);

% ---------------------- BUILD FIXED STRUCTURES ---------------------------

FlightInput_base = FlyInput(FLY_ID);
Geo_full         = Geometry_Function(Geo);

% ---------------------- PARAMETRIC LOOP SETUP ----------------------------

% % Full 1000 cases
% Mach_vec     = [ 0.72, 0.84, 1.58, 1.6];
% Altitude_vec = [7620, 10363.2];
% alpha_vec    = -5:2:5;
% delta_vec    = -20:2:20;

% % transonic
% Mach_vec     = [0.90, 1.00, 1.10, 1.20, 1.40];
% Altitude_vec = [7620, 10363.2];
% alpha_vec    = -5:5:5;    
% delta_vec    = -20:5:20;    

% Subsonic
Mach_vec     = [0.50, 0.60, 0.65, 0.70, 0.72, 0.76, 0.80, 0.84, 0.88];
Altitude_vec = [7620, 10363.2];
alpha_vec    = -5:5:5;      % [-5, 0, +5]
delta_vec    = -20:5:20;    % 9 values

% % Trans-Supersonic
% Mach_vec     = [0.90, 0.95, 1.00, 1.05, 1.10, 1.20, 1.30, 1.40, 1.50, 1.58, 1.60];
% Altitude_vec = [7620, 10363.2];
% alpha_vec    = [-5, 0, 5];
% delta_vec    = -15:5:15;    % 7 values


nCases = numel(Mach_vec) * numel(Altitude_vec) * numel(alpha_vec) * numel(delta_vec);

% Pre-allocate Results as struct array for speed
Results = struct( ...
    'CaseID',[], 'JID',[], 'Inputs',[], ...
    'Roskam_Coeff',[], 'Roskam_Hinge',[], 'Tornado',[]);
Results(nCases).CaseID = [];

k = 0;

% ---------------------- LOOP OVER FLIGHT CONDITIONS ----------------------

for iM = 1:numel(Mach_vec)
    for iH = 1:numel(Altitude_vec)
        for iA = 1:numel(alpha_vec)
            for iD = 1:numel(delta_vec)

                k = k + 1;

                FlightInput          = FlightInput_base;
                FlightInput.Mach     = Mach_vec(iM);
                FlightInput.Altitude = Altitude_vec(iH);
                FlightInput.alpha    = alpha_vec(iA);
                FlightInput.delta    = delta_vec(iD);

                Flight = Flight_Function(FlightInput, Geo_full);

                % ---------- Roskam ------------------------------------------
                [Cha, Chd, HingeResults] = Hinge_Coeff(Geo_full, Airfoil, Flight);
                [Ch, Ma]                 = HingeMoment(Cha, Chd, Flight, Geo_full, GEO_ID);

                HingeResults.Cha = Cha;
                HingeResults.Chd = Chd;
                HingeResults.Ch  = Ch;
                HingeResults.Ma  = Ma;

                % ---------- Tornado -----------------------------------------
                JID = sprintf('CASE_%03d', k);

                fprintf('Running case %d / %d  |  Mach=%.2f  Alt=%.0f  alpha=%.1f  delta=%.1f\n', ...
                    k, nCases, FlightInput.Mach, FlightInput.Altitude, ...
                    FlightInput.alpha, FlightInput.delta);

                oldFolder = pwd;
                cd('TORNADO\');
                out = Main_Tornado_LOOP(Geo, Flight, JID);
                cd(oldFolder);

                % ---------- Strip non-serialisable data (figure handles) -----
                %  Figure handles become invalid between sessions and inflate
                %  the .mat file. We save the numeric hinge moment instead.
                if isfield(out, 'Hinge') && isfield(out.Hinge, 'fig_handle')
                    out.Hinge = rmfield(out.Hinge, 'fig_handle');
                end

                % ---------- Store Results ------------------------------------
                Results(k).CaseID = k;
                Results(k).JID    = JID;

                Results(k).Inputs.Mach     = FlightInput.Mach;
                Results(k).Inputs.Altitude = FlightInput.Altitude;
                Results(k).Inputs.alpha    = FlightInput.alpha;
                Results(k).Inputs.delta    = FlightInput.delta;
                Results(k).Inputs.beta     = FlightInput.beta;
                Results(k).Inputs.P        = FlightInput.P;
                Results(k).Inputs.Q        = FlightInput.Q;
                Results(k).Inputs.R        = FlightInput.R;

                Results(k).Roskam_Coeff = HingeResults;

                Results(k).Roskam_Hinge.Cha = Cha;
                Results(k).Roskam_Hinge.Chd = Chd;
                Results(k).Roskam_Hinge.Ch  = Ch;
                Results(k).Roskam_Hinge.Ma  = Ma;

                Results(k).Tornado = out;

            end
        end
    end
end

% ---------------------- BUILD LIGHTWEIGHT SUMMARY ------------------------
%  Summary contains only scalar quantities needed for validation and
%  post-processing. Loading Summary_LOOP.mat is orders of magnitude faster
%  than the full Results file.

fprintf('\nBuilding lightweight Summary table...\n');

n = numel(Results);

% Pre-allocate vectors for speed
CaseID_v   = zeros(n,1);
Mach_v     = zeros(n,1);
Altitude_v = zeros(n,1);
alpha_v    = zeros(n,1);
delta_v    = zeros(n,1);
ChR_v       = zeros(n,1);
Ma_Roskam_v= zeros(n,1);
ChT_v       = zeros(n,1);
Ma_Tornado_v= zeros(n,1);

for k = 1:n
    CaseID_v(k)    = Results(k).CaseID;
    Mach_v(k)      = Results(k).Inputs.Mach;
    Altitude_v(k)  = Results(k).Inputs.Altitude;
    alpha_v(k)     = Results(k).Inputs.alpha;
    delta_v(k)     = Results(k).Inputs.delta;
    ChR_v(k)        = Results(k).Roskam_Hinge.Ch;
    Ma_Roskam_v(k) = Results(k).Roskam_Hinge.Ma;
    ChT_v(k)       = Results(k).Tornado.Hinge.coeff(1);
    Ma_Tornado_v(k) = Results(k).Tornado.Hinge.M(1);
end

Summary = table(CaseID_v, Mach_v, Altitude_v, alpha_v, delta_v, ...
                ChR_v, Ma_Roskam_v,  ChT_v, Ma_Tornado_v, ...
    'VariableNames', {'CaseID','Mach','Altitude','alpha','delta', ...
                      'Ch_Roskam','Ma_Roskam', 'Ch_Tornado','M_Tornado'});

% ---------------------- SAVE ---------------------------------------------
%  Summary_LOOP.mat  →  lightweight table  (~KB),  fast to load
%  Results_LOOP.mat  →  full structs       (MB),   needed for geometry/debug
fprintf('Saving Summary_LOOP.mat  (lightweight)...\n');
save('Summary_LOOP.mat', 'Summary');

fprintf('Saving Results_LOOP.mat  (full, compressed)...\n');
save('Results_LOOP.mat', 'Results', '-v7.3');    % -v7.3 enables HDF5 compression

fprintf('\nAll cases completed. %d cases saved.\n', n);
fprintf('  Summary_LOOP.mat  →  fast validation loading\n');
fprintf('  Results_LOOP.mat  →  full debug / geometry inspection\n');


% ---------------------- PLOT MENU ----------------------------------------
disp(' ')
disp('--------------------------------------------------')
disp('Visual inspection (requires full Results_LOOP.mat)')
plot_decision = input('Show plots for a specific case? (1 = Yes, 0 = No): ');

if plot_decision == 1
    case_idx = input(['Enter case number to inspect (1 to ', num2str(numel(Results)), '): ']);

    if case_idx > 0 && case_idx <= numel(Results)

        fprintf('Generating Geometry plot for JID: %s...\n', Results(case_idx).JID);
        oldFolder = pwd;
        cd('TORNADO\');

        figure('Name', sprintf('Tornado Geometry - Case %d', case_idx), 'NumberTitle', 'off');
        geometryplot(Results(case_idx).Tornado.lattice, ...
                     Results(case_idx).Tornado.geo, ...
                     Results(case_idx).Tornado.ref);
        cd(oldFolder);

        disp('Geometry plot displayed.')
        disp('Note: hinge debug figures are no longer stored between sessions.')
        disp('Re-run the specific case to regenerate them if needed.')
    else
        disp('Invalid case number.')
    end
else
    disp('Plotting skipped.')
end


