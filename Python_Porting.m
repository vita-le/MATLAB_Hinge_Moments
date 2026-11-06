clear; close all; clc;

addpath('Functions')
addpath('Inputs')
addpath('Roskam_Models')
addpath('TORNADO\aircraft\airfoil\')
warning('off', 'backtrace')
addpath('CPACS_in\')



GEO_ID = 18.1;
FLY_ID = 0;

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