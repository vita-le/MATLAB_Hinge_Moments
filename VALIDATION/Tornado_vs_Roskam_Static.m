clc; clear; close all;

%% Extract results --------------------------------------------------------
load('Results_LOOP_62.mat')
data = struct2table(Results);
Deflections = [data.Inputs].';
Deflections = [Deflections.delta];

Moments_Tornado = arrayfun(@(s) s.Tornado.Hinge.M(1), Results);
Moments_Roskam  = arrayfun(@(s) s.Roskam_Hinge.Ma, Results);

n_cases  = length(Deflections);
mid_point = floor(n_cases / 2);

% Split data for the two flight conditions
delta_a  = Deflections(1:mid_point);
delta_b  = Deflections(mid_point+1:end);
MT_a     = Moments_Tornado(1:mid_point);
MT_b     = Moments_Tornado(mid_point+1:end);
MR_a     = Moments_Roskam(1:mid_point);
MR_b     = Moments_Roskam(mid_point+1:end);

% Use deflection index as "pseudo-time" axis (or use delta directly)
t_a = delta_a;   % x-axis = deflection sweep
t_b = delta_b;

%% Plotting ---------------------------------------------------------------
fig = figure('Name', 'Hinge Moment Analysis', 'Color', 'w', ...
             'Units', 'normalized', 'Position', [0.05 0.1 0.9 0.75]);

% =========================================================================
% COLUMN (a) — Case: M=0.72
% =========================================================================

% --- Top-left: Deflection input ---
ax1 = subplot(2, 2, 1);
plot(t_a, delta_a, '-', 'Color', [0.85 0.2 0.1], 'LineWidth', 1.5);
grid on; box on;
ylabel('Aileron Deflection (deg)');
xlabel('\delta [deg]');
title('');
set(ax1, 'XLim', [min(t_a) max(t_a)]);
% Add condition label below plot via annotation (done after layout)

% --- Bottom-left: Hinge Moment comparison ---
ax3 = subplot(2, 2, 3);
hold on; grid on; box on;
p1 = plot(t_a, MT_a, '-',  'Color', [0.85 0.2 0.1], 'LineWidth', 1.5, 'DisplayName', 'Tornado');
p2 = plot(t_a, MR_a, '-',  'Color', [0.1 0.2 0.85], 'LineWidth', 1.5, 'DisplayName', 'Roskam');
ylabel('Hinge Moment (Nm)');
xlabel('\delta [deg]');
legend([p1 p2], 'Location', 'best', 'FontSize', 9);
set(ax3, 'XLim', [min(t_a) max(t_a)]);

% =========================================================================
% COLUMN (b) — Case: M=0.84
% =========================================================================

% --- Top-right: Deflection input ---
ax2 = subplot(2, 2, 2);
plot(t_b, delta_b, '-', 'Color', [0.85 0.2 0.1], 'LineWidth', 1.5);
grid on; box on;
ylabel('Aileron Deflection (deg)');
xlabel('\delta [deg]');
title('');
set(ax2, 'XLim', [min(t_b) max(t_b)]);

% --- Bottom-right: Hinge Moment comparison ---
ax4 = subplot(2, 2, 4);
hold on; grid on; box on;
plot(t_b, MT_b, '-', 'Color', [0.85 0.2 0.1], 'LineWidth', 1.5, 'DisplayName', 'Tornado');
plot(t_b, MR_b, '-', 'Color', [0.1 0.2 0.85], 'LineWidth', 1.5, 'DisplayName', 'Roskam');
ylabel('Hinge Moment (Nm)');
xlabel('\delta [deg]');
legend('Location', 'best', 'FontSize', 9);
set(ax4, 'XLim', [min(t_b) max(t_b)]);

%% Sync Y-axes for visual consistency
% Sync deflection plots (top row)
y_def_lim = [min([ylim(ax1) ylim(ax2)]), max([ylim(ax1) ylim(ax2)])];
set(ax1, 'YLim', y_def_lim);
set(ax2, 'YLim', y_def_lim);

% Sync moment plots (bottom row)
y_mom_lim = [min([ylim(ax3) ylim(ax4)]), max([ylim(ax3) ylim(ax4)])];
set(ax3, 'YLim', y_mom_lim);
set(ax4, 'YLim', y_mom_lim);

%% Captions below each column (mimicking (a) and (b) labels in the paper)
annotation('textbox', [0.13 0.01 0.35 0.05], ...
    'String', '(a)  M = 0.72, h = 7620 m, AoA = 1°', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontSize', 9, 'FontWeight', 'bold');

annotation('textbox', [0.58 0.01 0.35 0.05], ...
    'String', '(b)  M = 0.84, h = 7620 m, AoA = 1°', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontSize', 9, 'FontWeight', 'bold');

%% Global title
sgtitle('Hinge Moment Comparison: Tornado vs. Roskam', ...
        'FontSize', 13, 'FontWeight', 'bold');