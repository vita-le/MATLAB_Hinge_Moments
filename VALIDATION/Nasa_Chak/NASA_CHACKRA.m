% MATLAB script to replicate F-18 SRA Hinge Moment Comparison
% Data is loaded from 6 separate CSV files (Time, Value)

clear; clc; close all;

%% 1. Data Loading Utility Function
% Loads and sorts data by the first column (Time)
loadData = @(filename) sortrows(readmatrix(filename), 1);

try
    % --- CASE (A) DATA ---
    % Top Left
    dataA_Def = loadData('caseA_Deflection.csv');
    
    % Bottom Left (Two separate datasets)
    dataA_Sim  = loadData('caseA_Moment_Sim.csv');
    dataA_Flt  = loadData('caseA_Moment_Flight.csv');

    % --- CASE (B) DATA ---
    % Top Right
    dataB_Def = loadData('caseB_Deflection.csv');
    
    % Bottom Right (Two separate datasets)
    dataB_Sim  = loadData('caseB_Moment_Sim.csv');
    dataB_Flt  = loadData('caseB_Moment_Flight.csv');
    
    fprintf('All 6 data files loaded and sorted successfully.\n');

catch ME
    error('File loading failed: %s. Check filenames and CSV structure.', ME.message);
end

%% 2. Figure Creation
figure('Color', 'w', 'Position', [100, 100, 1000, 700]);

% --- TOP LEFT: Aileron Deflection (a) ---
subplot(2, 2, 1);
plot(dataA_Def(:,1), dataA_Def(:,2), 'r', 'LineWidth', 1.5);
ylabel('Aileron Deflection (deg)', 'FontWeight', 'bold');
xlabel('Time (s)', 'FontWeight', 'bold');
grid on;
set(gca, 'XLim', [0 5], 'YLim', [-25 25], 'YTick', -20:10:20);

% --- TOP RIGHT: Aileron Deflection (b) ---
subplot(2, 2, 2);
plot(dataB_Def(:,1), dataB_Def(:,2), 'r', 'LineWidth', 1.5);
ylabel('Aileron Deflection (deg)', 'FontWeight', 'bold');
xlabel('Time (s)', 'FontWeight', 'bold');
grid on;
set(gca, 'XLim', [0 6], 'YLim', [-25 25], 'YTick', -20:10:20);

% --- BOTTOM LEFT: Hinge Moment (a) ---
subplot(2, 2, 3);
hold on;
plot(dataA_Sim(:,1), dataA_Sim(:,2), 'r', 'LineWidth', 1.5, 'DisplayName', 'Predicted');
plot(dataA_Flt(:,1), dataA_Flt(:,2), 'b', 'LineWidth', 1.5, 'DisplayName', 'Flight Test');
ylabel('Hinge Moment (Nm)', 'FontWeight', 'bold');
xlabel('Time (s)', 'FontWeight', 'bold');
grid on; legend('Location', 'best');
set(gca, 'XLim', [0 5], 'YLim', [-2800 2200], 'YTick', -2000:1000:2000);

% --- BOTTOM RIGHT: Hinge Moment (b) ---
subplot(2, 2, 4);
hold on;
plot(dataB_Sim(:,1), dataB_Sim(:,2), 'r', 'LineWidth', 1.5, 'DisplayName', 'Predicted');
plot(dataB_Flt(:,1), dataB_Flt(:,2), 'b', 'LineWidth', 1.5, 'DisplayName', 'Flight Test');
ylabel('Hinge Moment (Nm)', 'FontWeight', 'bold');
xlabel('Time (s)', 'FontWeight', 'bold');
grid on; legend('Location', 'best');
set(gca, 'XLim', [0 6], 'YLim', [-4500 4500], 'YTick', -4000:2000:4000);

%% 3. Academic Captions
annotation('textbox', [0.05, 0.01, 0.45, 0.06], 'String', ...
    '(a) Abrupt roll doublet - full stick (left): M = 0.72, h = 25 kft, q-bar = 13.60 kPa', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 9);

annotation('textbox', [0.5, 0.01, 0.45, 0.06], 'String', ...
    '(b) Abrupt aileron reversal - full stick (left): M = 0.84, h = 25 kft, q-bar = 18.29 kPa', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 9);