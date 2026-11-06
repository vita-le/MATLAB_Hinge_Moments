function [Ch, Ma] = HingeMoment(Cha, Chd, Flight, Geometry, ID)
% =========================================================================
% HingeMoment
% Computes total hinge moment coefficient and Moment
%
% INPUT:
%   Cha      - dCh/dalpha  [1/rad]
%   Chd      - dCh/ddelta  [1/rad]
%   Flight   - struct from Flight_Function
%   Geometry - struct from Geometry_Function
%
% OUTPUT:
%   Ch      - hinge moment coefficient
%   Ma      - hinge moment [Nm]
% =========================================================================

%% ================== INPUT CHECK =========================================

if ~isfield(Flight,"alpha_rad") || ~isfield(Flight,"delta_rad")
    error("Flight structure must contain alpha_rad and delta_rad")
end

%% ================== COMPUTATION ==========================================

if ID == 18.1
    Ch0 = -400 / (Flight.q * Geometry.S_f * Geometry.c_aileron);
else
    Ch0 = 0;
end



Ch = Ch0 ...
    + Cha * Flight.alpha_rad ...
    + Chd * Flight.delta_rad;
Ma = Flight.q * Geometry.S_f * Geometry.c_aileron * Ch;

end