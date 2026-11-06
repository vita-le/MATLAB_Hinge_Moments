function geom = Geometry_Function(GeomInput, Airfoil)
% =========================================================================
% Geometry_Function
% Builds wing and control surface geometry from input structure
% and generates 2D and 3D plots
% =========================================================================

%% ================== INPUT EXTRACTION ==================

b       = GeomInput.b;
S       = GeomInput.S;
TR      = GeomInput.TR;
Lambda  = GeomInput.Lambda;
Gamma   = GeomInput.Gamma;
y_i     = GeomInput.y_i;
y_o     = GeomInput.y_o;
S_f     = GeomInput.S_f;
hinge   = GeomInput.hinge;

t_c     = Airfoil.t_c;

%% ================== BASIC CHECKS ==================

if y_o <= y_i
    error('y_o must be greater than y_i')
end

if TR <= 0
    error('Taper ratio must be positive')
end

%% ================== MAIN WING GEOMETRY ==================

AR      = b^2 / S;
c_root  = 2 * S / (b * (1 + TR));
c_tip   = TR * c_root;
y_semi  = b / 2;

c = @(y) c_root + (c_tip - c_root) * (y / y_semi);

x_c4 = @(y) y * tand(Lambda);
x_le = @(y) x_c4(y) - 0.25 .* c(y);
x_te = @(y) x_c4(y) + 0.75 .* c(y);

z = @(y) y * tand(Gamma);

MAC   = (2/3) * c_root * (1 + TR + TR^2) / (1 + TR);
y_MAC = (b/2) * (1 + 2*TR) / (3*(1 + TR));

%% ================== CONTROL SURFACE ==================

c_aileron = S_f / (y_o - y_i);
c_hinge   = hinge * c_aileron;

%% ================== HINGE LINE ==================

x_hinge_i = x_te(y_i) - c_aileron + c_hinge;
x_hinge_o = x_te(y_o) - c_aileron + c_hinge;

dx = x_hinge_o - x_hinge_i;
dy = y_o - y_i;

lambda_hl = atand(dx / dy);

%% ================== 2D COORDINATES ==================

wing_y = [0, y_semi, y_semi, 0];
wing_x = [x_le(0), x_le(y_semi), x_te(y_semi), x_te(0)];

flap_y = [y_i, y_o, y_o, y_i];
flap_x = [ ...
    x_te(y_i) - c_aileron, ...
    x_te(y_o) - c_aileron, ...
    x_te(y_o), ...
    x_te(y_i)];

hinge_y = [y_i, y_o];
hinge_x = [x_hinge_i, x_hinge_o];

%% ================== 3D COORDINATES ==================

wing_X = wing_x;
wing_Y = wing_y;
wing_Z = z(wing_y);

flap_X = flap_x;
flap_Y = flap_y;
flap_Z = z(flap_y);

hinge_X = hinge_x;
hinge_Y = hinge_y;
hinge_Z = z(hinge_y);

%% ================== 2D PLOT ==================

figure('Name','2D Wing Planform','Color','w');
hold on; grid on; axis equal;

fill(wing_y, wing_x,[0.8 0.8 0.8],'FaceAlpha',0.4);
fill(flap_y, flap_x,[0.2 0.6 1.0],'FaceAlpha',0.7);
plot(hinge_y, hinge_x,'r--','LineWidth',2);

xlabel('Spanwise coordinate y [m]');
ylabel('Chordwise coordinate x [m]');
title('2D Planform View');
set(gca,'YDir','reverse');
view(0,90);

%% ================== 3D PLOT ==================

figure('Name','3D Wing Geometry','Color','w');
hold on; grid on; axis equal;

fill3(wing_X, wing_Y, wing_Z,[0.8 0.8 0.8],'FaceAlpha',0.4);
fill3(flap_X, flap_Y, flap_Z,[0.2 0.6 1.0],'FaceAlpha',0.7);
plot3(hinge_X, hinge_Y, hinge_Z,'r--','LineWidth',2);

xlabel('x [m]');
ylabel('y [m]');
zlabel('z [m]');
title('3D Wing Geometry');
view(35,25);

%% ================== OUTPUT STRUCT ==================

geom.b          = b;
geom.S          = S;
geom.AR         = AR;

geom.c_root     = c_root;
geom.c_tip      = c_tip;
geom.MAC        = MAC;
geom.y_MAC      = y_MAC;

geom.c_fun      = c;
geom.x_le_fun   = x_le;
geom.x_te_fun   = x_te;
geom.z_fun      = z;

geom.c_aileron  = c_aileron;
geom.S_f        = S_f;
geom.hinge      = hinge;
geom.lambda_hl  = lambda_hl;

geom.t_c        = t_c;

geom.y_i        = y_i;
geom.y_o        = y_o;

geom.lambda_c4  = Lambda;
geom.dihedral   = Gamma;

end