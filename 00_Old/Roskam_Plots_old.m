% =========================================================================
% COMPREHENSIVE SCRIPT: Aerodynamic Data Digitization
% Description: 13 windows with simplified titles and uniform line thickness.
% =========================================================================

clear; clc; close all;

% --- Color Palette ---
c_blue     = [0.26, 0.45, 0.77];
c_orange   = [0.93, 0.45, 0.15];
c_grey     = [0.65, 0.65, 0.65];
c_yellow   = [1.00, 0.75, 0.00];
c_green    = [0.47, 0.67, 0.19];
c_lblue    = [0.36, 0.61, 0.84];
c_dblue    = [0.18, 0.33, 0.59];
c_dark_red = [0.70, 0.10, 0.10]; 

LWidth = 2; % Uniform thickness

%% --- SECTION 1: FIGURE 1 ---
% 1(a) Theoretical C_halpha
figure('Name', 'Fig 1a', 'Color', 'w'); 
hold on; grid on; box on;
% x range
x_a = linspace(0.0, 0.45, 200);
% thickness ratios (as in figure family)
tc_values = 0:0.02:0.16;
% slope
a = -1.433;
for tc = tc_values
    b = 1.5*tc - 0.317;
    y = a*x_a + b;
    plot(x_a, y, 'LineWidth', 1.5);
end
xlim([0, 0.45]); 
ylim([-0.8, 0]);
xlabel('$c_f/c$', 'Interpreter', 'latex');
ylabel('$(C_{h\alpha})_{th}$', 'Interpreter', 'latex');
title('1(a): Theoretical $C_{h\alpha}$ - Symmetrical Airfoil', 'Interpreter', 'latex');
legend(arrayfun(@(t) sprintf('t/c = %.2f', t), tc_values, ...
    'UniformOutput', false), 'Location', 'eastoutside');

% 1(b) C_halpha Ratio
figure('Name', 'Fig 1b', 'Color', 'w'); hold on; grid on; box on;
x_b = linspace(0.1, 0.4, 100);
plot(x_b, ones(size(x_b)), 'LineWidth', LWidth, 'Color', c_blue); 
plot(x_b, 0.266*(x_b-0.1)+0.72, 'LineWidth', LWidth, 'Color', c_orange);
plot(x_b, 0.5*(x_b-0.1)+0.54, 'LineWidth', LWidth, 'Color', c_grey); 
plot(x_b, 0.666*(x_b-0.1)+0.35, 'LineWidth', LWidth, 'Color', c_yellow);
xlim([0, 0.45]); ylim([0, 1.2]);
xlabel('$c_f/c$', 'Interpreter', 'latex');
ylabel('Ratio');
title('1(b): $C_{h\alpha}$ Correction Ratio', 'Interpreter', 'latex');
legend({'Factor 1.0', 'Factor 0.9', 'Factor 0.85', 'Factor 0.8'}, 'Location', 'eastoutside');

% 1(c) C_lalpha Correction
figure('Name', 'Fig 1c', 'Color', 'w'); hold on; grid on; box on;
x_c = linspace(0, 0.2, 100);
plot(x_c, -0.8*x_c+0.94, 'LineWidth', LWidth, 'Color', c_blue); 
plot(x_c, -1.0*x_c+0.90, 'LineWidth', LWidth, 'Color', c_orange); 
plot(x_c, -0.75*x_c+0.97, 'LineWidth', LWidth, 'Color', c_grey);
xlim([-0.05, 0.25]); ylim([0, 1.2]);
xlabel('$\tan(\Phi_{te}/2)$', 'Interpreter', 'latex');
ylabel('$C_{l\alpha}$ Ratio', 'Interpreter', 'latex');
title('1(c): $C_{l\alpha}$ vs Trailing Edge Angle', 'Interpreter', 'latex');
legend({'Re = 10^7', 'Re = 10^6', 'Re = 10^8'});

%% --- SECTION 2: FIGURE 4 ---

% 4(a) Balance Ratio
figure('Name', 'Fig 4a', 'Color', 'w'); hold on; grid on; box on;
plot([0.15, 0.5], [0.93, 0.02], 'LineWidth', LWidth, 'Color', c_blue);
xlim([0, 0.6]); ylim([0, 1]);
xlabel('Balance Ratio');
ylabel('$C_{h\alpha,bal} / C_{h\alpha}$', 'Interpreter', 'latex');
title('4(a): Balance Effect on $C_{h\alpha}$', 'Interpreter', 'latex');

% 4(b) Term 1
figure('Name', 'Fig 4b', 'Color', 'w'); hold on; grid on; box on;
x_4b = [2, 3, 4, 6, 8, 10];
y_4b = [0.0183, 0.014, 0.011, 0.007, 0.0045, 0.0035];
xf_4b = linspace(2, 10, 100);
yf_4b = pchip(x_4b, y_4b, xf_4b);
plot(xf_4b, yf_4b, 'LineWidth', LWidth, 'Color', c_blue);
xlim([0, 12]); ylim([0, 0.02]);
xlabel('A (Aspect Ratio)');
ylabel('Term 1');
title('4(b): Aspect Ratio Correction Term');

%% --- SECTION 3: FIGURE 5 ---

% 5(a) Ka factor
figure('Name', 'Fig 5a', 'Color', 'w'); hold on; grid on; box on;
x_5a = [0, 0.2, 0.4, 0.6, 0.8, 1.0];
y_5a = [1.0, 1.25, 1.7, 2.4, 3.3, 4.3];
xf_5a = linspace(0, 1, 100);
yf_5a = pchip(x_5a, y_5a, xf_5a);
plot(xf_5a, yf_5a, 'LineWidth', LWidth, 'Color', c_blue);
xlim([-0.2, 1.2]); ylim([0, 4.5]);
xlabel('$\eta$', 'Interpreter', 'latex');
ylabel('$K_a$', 'Interpreter', 'latex');
title('5(a): Spanwise Factor $K_a$', 'Interpreter', 'latex');

% 5(b) B2 factor
figure('Name', 'Fig 5b', 'Color', 'w'); hold on; grid on; box on;
xc_5b = linspace(0.05, 0.6, 100);
plot(xc_5b, 1.8*xc_5b.^0.45, 'LineWidth', LWidth, 'Color', c_blue); 
plot(xc_5b, 1.68*xc_5b.^0.45, 'LineWidth', LWidth, 'Color', c_orange);
plot(xc_5b, 1.55*xc_5b.^0.45, 'LineWidth', LWidth, 'Color', c_grey); 
plot(xc_5b, 1.4*xc_5b.^0.45, 'LineWidth', LWidth, 'Color', c_yellow);
xlim([0, 0.7]); ylim([0, 1.6]);
xlabel('$c_f/c$', 'Interpreter', 'latex');
ylabel('B2');
title('5(b): B2 vs Flap Chord Ratio');
legend({'c_b/c_f = 0', 'c_b/c_f = 0.2', 'c_b/c_f = 0.3', 'c_b/c_f = 0.4'}, 'Location', 'eastoutside');

%% --- SECTION 4: a_d PARAMETER ---

figure('Name', 'Fig ad', 'Color', 'w'); hold on; grid on; box on;
def = [0, 10, 20, 30, 40, 50];
xf_def = linspace(0, 50, 100);
plot(xf_def, pchip(def, [0.45, 0.445, 0.425, 0.38, 0.32, 0.24], xf_def), 'LineWidth', LWidth, 'Color', c_blue);
plot(xf_def, pchip(def, [0.555, 0.55, 0.53, 0.49, 0.43, 0.34], xf_def), 'LineWidth', LWidth, 'Color', c_grey);
plot(xf_def, pchip(def, [0.60, 0.595, 0.58, 0.54, 0.48, 0.395], xf_def), 'LineWidth', LWidth, 'Color', c_yellow);
plot(xf_def, pchip(def, [0.51, 0.515, 0.50, 0.46, 0.41, 0.335], xf_def), 'LineWidth', LWidth, 'Color', c_dark_red);
xlim([-10, 60]); ylim([0, 0.7]);
xlabel('Deflection [deg]');
ylabel('$a_d$', 'Interpreter', 'latex');
title('$a_d$ Parameter vs Deflection', 'Interpreter', 'latex');
legend({'c_f/c = 0.2', 'c_f/c = 0.3', 'c_f/c = 0.4', 'Interpolated Wing'}, 'Location', 'eastoutside');

%% --- SECTION 5: FIGURE 7 ---

% 7(a)
figure('Name', 'Fig 7a', 'Color', 'w'); hold on; grid on; box on;
xc_7a = linspace(0.1, 0.4, 100);
plot(xc_7a, ones(size(xc_7a))*1.0, 'Color', c_orange, 'LineWidth', LWidth);
plot(xc_7a, 0.97-0.03*xc_7a, 'Color', c_lblue, 'LineWidth', LWidth); 
plot(xc_7a, 0.93-0.05*xc_7a, 'Color', c_grey, 'LineWidth', LWidth);
plot(xc_7a, 0.89-0.08*xc_7a, 'Color', c_yellow, 'LineWidth', LWidth); 
plot(xc_7a, 0.85-0.12*xc_7a, 'Color', c_blue, 'LineWidth', LWidth);
plot(xc_7a, 0.80-0.18*xc_7a, 'Color', c_green, 'LineWidth', LWidth); 
plot(xc_7a, 0.76-0.25*xc_7a, 'Color', c_dblue, 'LineWidth', LWidth);
xlim([0, 0.45]); ylim([0, 1.2]);
xlabel('$c_f/c$', 'Interpreter', 'latex');
ylabel('Ratio');
title('7(a): $C_{h\delta}$ Correction Ratio', 'Interpreter', 'latex');
legend({'1.0','0.95','0.9','0.85','0.8','0.75','0.7'}, 'Location', 'eastoutside');

% 7(b)
figure('Name', 'Fig 7b', 'Color', 'w'); hold on; grid on; box on;
xc_7b = linspace(0.1, 0.4, 100);
plot(xc_7b, -0.95*xc_7b-0.54, 'LineWidth', LWidth, 'Color', c_blue); 
plot(xc_7b, -0.85*xc_7b-0.61, 'LineWidth', LWidth, 'Color', c_orange);
xlim([0, 0.45]); ylim([-1, 0]);
xlabel('$c_f/c$', 'Interpreter', 'latex');
ylabel('$(C_{h\delta})_{th}$', 'Interpreter', 'latex');
title('7(b): Theoretical $C_{h\delta}$', 'Interpreter', 'latex');
legend({'t/c = 0.15', 't/c = 0.12'});

% 7(c)
figure('Name', 'Fig 7c', 'Color', 'w'); hold on; grid on; box on;
xc_7c = linspace(0.05, 0.5, 100);
plot(xc_7c, ones(size(xc_7c)), 'Color', c_lblue, 'LineWidth', LWidth);
plot(xc_7c, 0.68+0.25*xc_7c.^0.5, 'Color', c_dblue, 'LineWidth', LWidth);
plot(xc_7c, 0.38+0.45*xc_7c.^0.7, 'Color', c_grey, 'LineWidth', LWidth);
plot(xc_7c, 0.08+0.55*xc_7c.^0.9, 'Color', c_yellow, 'LineWidth', LWidth);
xlim([0, 0.6]); ylim([0, 1.2]);
xlabel('$c_f/c$', 'Interpreter', 'latex');
ylabel('Efficiency Ratio');
title('7(c): $C_{l\delta}$ Efficiency Ratio', 'Interpreter', 'latex');
legend({'Theory = 1.0','Interpolated Wing','Theory = 0.8','Theory = 0.7'}, 'Location', 'eastoutside');

% 7(d)
figure('Name', 'Fig 7d', 'Color', 'w'); hold on; grid on; box on;
xc_7d = linspace(0.05, 0.5, 100);
plot(xc_7d, 8.4*xc_7d.^0.6, 'LineWidth', LWidth, 'Color', c_blue); 
plot(xc_7d, 8.8*xc_7d.^0.6, 'LineWidth', LWidth, 'Color', c_orange);
xlim([0, 0.6]); ylim([0, 7]);
xlabel('$c_f/c$', 'Interpreter', 'latex');
ylabel('$(C_{l\delta})_{th}$', 'Interpreter', 'latex');
title('7(d): Theoretical $C_{l\delta}$', 'Interpreter', 'latex');
legend({'t/c = 0.12', 't/c = 0.15'});

%% --- SECTION 6: FIGURE 8 ---

figure('Name', 'Fig 8', 'Color', 'w'); hold on; grid on; box on;
br_x = [0.18, 0.25, 0.35, 0.45, 0.5];
br_y = [0.86, 0.74, 0.54, 0.32, 0.21];
br_xf = linspace(0.18, 0.5, 100);
br_yf = pchip(br_x, br_y, br_xf);
plot(br_xf, br_yf, 'LineWidth', LWidth, 'Color', c_blue);
xlim([0, 0.6]); ylim([0, 1]);
xlabel('Balance Ratio');
ylabel('$C_{h\delta,bal} / C_{h\delta}$', 'Interpreter', 'latex');
title('8: Balance Effect on $C_{h\delta}$', 'Interpreter', 'latex');
