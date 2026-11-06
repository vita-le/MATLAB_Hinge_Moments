function Flight = Flight_Function(FlightInput, Geometry)
% =========================================================================
% Flight_Function
% Builds flight condition structure and computes derived quantities
%
% INPUT:
%   FlightInput struct containing:
%       .Mach
%       .Altitude
%       .alpha   [deg]
%       .delta   [deg]
%
%   Geometry struct from Geometry_Function
%
% OUTPUT:
%   Flight struct with atmospheric and aerodynamic properties
% =========================================================================

%% ================== INPUT VALIDATION ==================

requiredFields = ["Mach","Altitude","alpha","delta"];

for k = 1:length(requiredFields)
    if ~isfield(FlightInput, requiredFields(k))
        error("Missing field in FlightInput: %s", requiredFields(k))
    end
end

%% ================== INITIALIZATION ==================

Flight = FlightInput;

%% ================== ATMOSPHERE ==================

[~, ~, rho, a, mu] = ISAfunction(Flight.Altitude);

Flight.rho = rho;
Flight.a   = a;
Flight.mu  = mu;

%% ================== KINEMATICS ==================

Flight.V = Flight.Mach * Flight.a;
Flight.q = 0.5 * Flight.rho * Flight.V^2;

%% ================== REYNOLDS NUMBER ==================

Flight.Re = Flight.rho * Flight.V * Geometry.MAC / Flight.mu;

%% ================== ANGLE CONVERSIONS ==================

Flight.alpha_rad = deg2rad(Flight.alpha);
Flight.delta_rad = deg2rad(Flight.delta);

end