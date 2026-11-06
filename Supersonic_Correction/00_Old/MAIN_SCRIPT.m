%% ========================================================================
%                           MAIN SCRIPT
%               Roskam Aircraft Hinge Moment Analysis + Tornado
%  ========================================================================

clear; close all; clc;

addpath('Functions')                                                       % Folder with useful functions
addpath('Inputs')                                                          % Folder with inputs data
addpath('Roskam_Models')                                                   % Folder with roskam functions 
addpath('TORNADO\aircraft\airfoil\')                                       % Folder with Airfoils in Tornado folder

% -------------------- LOAD CONFIGURATION INPUTS -------------------------

GEO_ID     = 18.1;                                                         % use to select Aircraft Model  (F/A-18 HARV [18] or F-35 [35], or EXTRA 300)
FLY_ID     = 1;                                                            % select flight conditions

Geo         = GeoInput(GEO_ID);                                            % Geometry parameters (inputs)

Airfoil     = Airfoil_config(GEO_ID);                                      % Airfoil selection

% ----------- (read file .dat) --------------------------------------------

filepath = fullfile('TORNADO','aircraft','airfoil', Airfoil.filename);

data = readmatrix(filepath);
data = data(~any(isnan(data),2),:);
data = data(data(:,1) >= 0 & data(:,1) <= 1, :);

Airfoil.x = data(:,1);
Airfoil.y = data(:,2);

% -------------------------------------------------------------------------

Airfoil     = Airfoil_Function(Airfoil);                                   % Update airfoil structure

FlightInput = FlyInput(FLY_ID);                                            % Flight condition parameters

% ---------------------- BUILD STRUCTURES ---------------------------------

Geo_full = Geometry_Function(Geo);                                         % Create structure with full geo data (extra variables)

Flight = Flight_Function(FlightInput, Geo_full);                           % Create structur with full flight info

% ---------------------- COMPUTE HINGE MOMENT -----------------------------

[Cha, Chd, HingeResults] = Hinge_Coeff(Geo_full, Airfoil, Flight);         % Apply Roskam method

[Ch, Ma] = HingeMoment(Cha, Chd, Flight, Geo_full, GEO_ID);                % Use coefficient to compute method


% ---------------------- SAVE RESULTS ------------------------------------

HingeResults.Ch = Ch;
HingeResults.Ma = Ma;

%% %%%%%%%%%%%%%%%%%%%%  TORNADO    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     

% Save folder
oldFolder = pwd;

% get inside correct folder
cd('TORNADO\');

% run main
Main_Tornado(Geo,Flight);    

% back to folder
cd(oldFolder);


%% %%%%%%%%%%%%%%%%%%%%  Comparison    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ---------------------- DISPLAY Roskam RESULTS ---------------------------

fprintf('--------------------------------------------\n');
fprintf('Mach Number M = %.5f\n', Flight.Mach);
fprintf('Altitude = %.5f m\n', Flight.Altitude);
fprintf('--------------------------------------------\n');
fprintf('Aircraft Selected : %s\n', Geo.name);
fprintf('Airfoil Selected: %s\n', Airfoil.name);
fprintf('--------------------------------------------\n');
fprintf('Hinge Moment Coefficient Ch = %.5f\n', Ch);
fprintf('--------------------------------------------\n');
fprintf('Hinge Moment  Ma = %.5f Nm\n', Ma);
fprintf('--------------------------------------------\n');
