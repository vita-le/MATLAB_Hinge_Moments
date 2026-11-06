function geom = Geometry_Function(GeomInput)
% ============================================================
%   GEOMETRY_FUNCTION 
% ============================================================

%% === INPUTS ===
b       = GeomInput.b;
S       = GeomInput.S;
c_root  = GeomInput.c_r;     
c_tip   = GeomInput.c_t;      
Lambda  = deg2rad(GeomInput.Lambda);  %[rad]

% Aileron
y_i     = GeomInput.y_i;
y_o     = GeomInput.y_o;
S_f     = GeomInput.S_f;

%% === GEOMETRY CALCULATIONS ----------------------------------------------
b2 = b/2;
b_f = y_o - y_i;

% Aspect Ratio and Leading Edge
AR = b^2 / GeomInput.S;
% Taper ratio e MAC
TR = c_tip / c_root;
% MAC = (2/3) * c_root * (1 + TR + TR^2) / (1 + TR);
MAC = S / b;

%% === AILERON GEOMETRY ===
% Local Cord aileron
c_i = c_root + (c_tip - c_root) * (y_i / b2);
c_o = c_root + (c_tip - c_root) * (y_o / b2);

%  x location of TE of wing to y_o and y_i
xTE_wing_i = y_i * tan(Lambda) + c_i;
xTE_wing_o = y_o * tan(Lambda) + c_o;

% aileron chord
c_aileron = S_f / b_f;

% hinge line points connected to TE of wing
ail_H_i = [xTE_wing_i, y_i];
ail_H_o = [xTE_wing_o, y_o];

% sweep hinge line of aileron
Lambda_hl = atan((ail_H_o(1) - ail_H_i(1)) / (y_o - y_i));

%% === SAVE NEW OUTPUT STRUCTURE (updating old one) ===

geom = GeomInput;
geom.MAC = MAC;
geom.AR = AR;
geom.c_aileron = c_aileron;
geom.TR = TR;
geom.Lambda_hl = rad2deg(Lambda_hl);                                       %[deg]
geom.b_f = b_f;

end