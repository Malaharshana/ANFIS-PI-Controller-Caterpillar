%% ============================================================
%% FINAL COMPLETE OUTPUT SCRIPT
%% Generates every graph and value needed for PPT submission
%% ============================================================
clear; clc; close all;

load('results\full_simulation.mat')
load('results\baseline_simulation.mat')
load('models\trained_anfis.mat')

setpoint  = 900;
Kp_fixed  = 1;
Ki_fixed  = 1;
outFolder = 'plots\PPT_FINAL\';

fprintf('=================================================\n')
fprintf('   GENERATING ALL OUTPUTS — PLEASE WAIT...\n')
fprintf('=================================================\n\n')

%% PRE-COMPUTE: Gain corrections at every timestep
fprintf('Computing gain corrections for all timesteps...\n')
n = length(t);
Kp_corr_vec  = zeros(n,1);
Ki_corr_vec  = zeros(n,1);
Kp_final_vec = zeros(n,1);
Ki_final_vec = zeros(n,1);

for i = 1:n
    [kp, ki]        = anfis_evaluate(e(i), A(i));
    Kp_corr_vec(i)  = kp;
    Ki_corr_vec(i)  = ki;
    Kp_final_vec(i) = Kp_fixed * kp;
    Ki_final_vec(i) = Ki_fixed * ki;
end
fprintf('Done.\n\n')

%% PRE-COMPUTE: All metrics
error_pct_anfis = (e   / setpoint) * 100;
error_pct_fixed = (e_f / setpoint) * 100;

idx_a50 = find(t   >= 50, 1);
idx_f50 = find(t_f >= 50, 1);

epct_a_dist = error_pct_anfis(idx_a50:end);
epct_f_dist = error_pct_fixed(idx_f50:end);
t_a_dist    = t(idx_a50:end);
t_f_dist    = t_f(idx_f50:end);

OS_anfis = max(epct_a_dist);
US_anfis = abs(min(epct_a_dist));
OS_fixed = max(epct_f_dist);
US_fixed = abs(min(epct_f_dist));

maxRPMdev_anfis = max(abs(e(idx_a50:end)));
maxRPMdev_fixed = max(abs(e_f(idx_f50:end)));

% Settling time
idx_ts_a = find(abs(epct_a_dist) > 1, 1, 'last');
idx_ts_f = find(abs(epct_f_dist) > 1, 1, 'last');
T_settle_anfis = 0;
T_settle_fixed = 0;
if ~isempty(idx_ts_a)
    idx_ts_a = min(idx_ts_a, length(t_a_dist));
    T_settle_anfis = t_a_dist(idx_ts_a) - t_a_dist(1);
end
if ~isempty(idx_ts_f)
    idx_ts_f = min(idx_ts_f, length(t_f_dist));
    T_settle_fixed = t_f_dist(idx_ts_f) - t_f_dist(1);
end

% Steady state time
idx_ss_a = find(abs(epct_a_dist) > 0.25, 1, 'last');
idx_ss_f = find(abs(epct_f_dist) > 0.25, 1, 'last');
T_ss_anfis = 0;
T_ss_fixed = 0;
if ~isempty(idx_ss_a)
    idx_ss_a = min(idx_ss_a, length(t_a_dist));
    T_ss_anfis = t_a_dist(idx_ss_a) - t_a_dist(1);
end
if ~isempty(idx_ss_f)
    idx_ss_f = min(idx_ss_f, length(t_f_dist));
    T_ss_fixed = t_f_dist(idx_ss_f) - t_f_dist(1);
end

improvement_OS  = (OS_fixed  - OS_anfis)  / max(OS_fixed,  0.0001) * 100;
improvement_US  = (US_fixed  - US_anfis)  / max(US_fixed,  0.0001) * 100;
improvement_RPM = (maxRPMdev_fixed - maxRPMdev_anfis) / max(maxRPMdev_fixed, 0.0001) * 100;

fprintf('Metrics computed.\n\n')

%% ============================================================
%% FIGURE 01 — Disturbance Profile
%% ============================================================
fig = figure('Name','01 Disturbance Profile','Position',[50 50 1000 400]);
plot(t_f, A_f, 'Color',[0.1 0.6 0.1], 'LineWidth', 2.5)
xlabel('Time (s)', 'FontSize', 13)
ylabel('Disturbance A (0 to 1)', 'FontSize', 13)
title('Input Disturbance Profile — Step/Shed Pattern', 'FontSize', 14, 'FontWeight', 'bold')
ylim([-0.05 1.1])
grid on
text(50,  0.85, sprintf('Max disturbance = %.2f', max(A_f)), 'FontSize', 11, 'Color', 'red')
text(800, 0.45, 'Shed phase', 'FontSize', 11, 'Color', [0.1 0.6 0.1])
saveas(fig, [outFolder '01_Disturbance_Profile.png'])
fprintf('Figure 01 saved.\n')

%% ============================================================
%% FIGURE 02 — RPM Tracking ANFIS only
%% ============================================================
fig = figure('Name','02 RPM Tracking ANFIS','Position',[50 50 1100 500]);
plot(t, y, 'b', 'LineWidth', 2, 'DisplayName', 'Actual RPM (ANFIS)')
hold on
yline(setpoint, 'r--', 'Setpoint = 900 RPM', 'LineWidth', 1.5, ...
      'LabelHorizontalAlignment','left')
xlabel('Time (s)', 'FontSize', 13)
ylabel('RPM', 'FontSize', 13)
title('ANFIS Adaptive Control — RPM Tracking (Full 1000s)', ...
      'FontSize', 14, 'FontWeight', 'bold')
legend('FontSize', 11, 'Location', 'southeast')
ylim([0 1050]); grid on
text(200, 400, sprintf('Stays within ±%.3f%% of setpoint\nafter initial startup', OS_anfis), ...
     'FontSize', 11, 'BackgroundColor', 'white', 'EdgeColor', 'blue')
saveas(fig, [outFolder '02_ANFIS_RPM_Tracking.png'])
fprintf('Figure 02 saved.\n')

%% ============================================================
%% FIGURE 03 — RPM Tracking Fixed Gains only
%% ============================================================
fig = figure('Name','03 RPM Tracking Fixed','Position',[50 50 1100 500]);
plot(t_f, y_f, 'r', 'LineWidth', 2, 'DisplayName', 'Actual RPM (Fixed Gains)')
hold on
yline(setpoint, 'k--', 'Setpoint = 900 RPM', 'LineWidth', 1.5, ...
      'LabelHorizontalAlignment','left')
xlabel('Time (s)', 'FontSize', 13)
ylabel('RPM', 'FontSize', 13)
title('Fixed Gain PI Control — RPM Tracking (Full 1000s)', ...
      'FontSize', 14, 'FontWeight', 'bold')
legend('FontSize', 11, 'Location', 'northeast')
grid on
text(400, max(y_f)*0.7, sprintf('Max deviation: %.0f RPM', maxRPMdev_fixed), ...
     'FontSize', 11, 'Color', 'red', 'BackgroundColor', 'white', 'EdgeColor', 'red')
saveas(fig, [outFolder '03_Fixed_RPM_Tracking.png'])
fprintf('Figure 03 saved.\n')

%% ============================================================
%% FIGURE 04 — RPM Comparison
%% ============================================================
fig = figure('Name','04 RPM Comparison','Position',[50 50 1200 550]);
plot(t_f, y_f, 'r',  'LineWidth', 1.5, 'DisplayName', 'Fixed Gains PI')
hold on
plot(t,   y,   'b',  'LineWidth', 2.5, 'DisplayName', 'ANFIS Adaptive')
yline(setpoint, 'k--', 'Setpoint 900 RPM', 'LineWidth', 1.5)
xlabel('Time (s)', 'FontSize', 13)
ylabel('RPM', 'FontSize', 13)
title('RPM Tracking Comparison: ANFIS Adaptive vs Fixed Gains PI', ...
      'FontSize', 14, 'FontWeight', 'bold')
legend('FontSize', 12, 'Location', 'northeast')
grid on
annotation('textbox', [0.15 0.15 0.32 0.14], 'String', ...
    sprintf('ANFIS max deviation: %.2f RPM\nFixed max deviation: %.1f RPM\nImprovement: %.1f%%', ...
    maxRPMdev_anfis, maxRPMdev_fixed, improvement_RPM), ...
    'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'blue')
saveas(fig, [outFolder '04_RPM_Comparison_ANFIS_vs_Fixed.png'])
fprintf('Figure 04 saved.\n')

%% ============================================================
%% FIGURE 05 — Error % ANFIS only
%% ============================================================
fig = figure('Name','05 Error ANFIS','Position',[50 50 1100 500]);
plot(t, error_pct_anfis, 'b', 'LineWidth', 2)
hold on
yline(0,         'k-',  'LineWidth', 0.8)
yline(20,        'r--', '+20% OS limit',           'LineWidth', 1.5, 'LabelHorizontalAlignment','left')
yline(-20,       'r--', '-20% US limit',           'LineWidth', 1.5, 'LabelHorizontalAlignment','left')
yline(OS_anfis,  'm:',  sprintf('+%.3f%% actual',  OS_anfis),  'LineWidth', 1.2)
yline(-US_anfis, 'm:',  sprintf('-%.3f%% actual',  US_anfis),  'LineWidth', 1.2)
xlabel('Time (s)', 'FontSize', 13)
ylabel('Error %', 'FontSize', 13)
title('ANFIS Adaptive — Error % (Requirement: within ±20%)', ...
      'FontSize', 14, 'FontWeight', 'bold')
grid on
saveas(fig, [outFolder '05_ANFIS_Error_Percent.png'])
fprintf('Figure 05 saved.\n')

%% ============================================================
%% FIGURE 06 — Error % Fixed Gains only
%% ============================================================
fig = figure('Name','06 Error Fixed','Position',[50 50 1100 500]);
plot(t_f, error_pct_fixed, 'r', 'LineWidth', 2)
hold on
yline(0,   'k-',  'LineWidth', 0.8)
yline(20,  'k--', '+20% OS limit', 'LineWidth', 1.5, 'LabelHorizontalAlignment','left')
yline(-20, 'k--', '-20% US limit', 'LineWidth', 1.5, 'LabelHorizontalAlignment','left')
xlabel('Time (s)', 'FontSize', 13)
ylabel('Error %', 'FontSize', 13)
title('Fixed Gains PI — Error % (Requirement: within ±20%)', ...
      'FontSize', 14, 'FontWeight', 'bold')
grid on
text(300, OS_fixed*0.8, sprintf('Max OS = %.2f%%', OS_fixed), ...
     'FontSize', 11, 'Color', 'red', 'BackgroundColor', 'white')
saveas(fig, [outFolder '06_Fixed_Error_Percent.png'])
fprintf('Figure 06 saved.\n')

%% ============================================================
%% FIGURE 07 — Error % Comparison
%% ============================================================
fig = figure('Name','07 Error Comparison','Position',[50 50 1200 550]);
plot(t_f, error_pct_fixed, 'r',  'LineWidth', 1.5, 'DisplayName', 'Fixed Gains')
hold on
plot(t,   error_pct_anfis, 'b',  'LineWidth', 2.5, 'DisplayName', 'ANFIS Adaptive')
yline(20,  'k--', '+20% limit', 'LineWidth', 1.2)
yline(-20, 'k--', '-20% limit', 'LineWidth', 1.2)
yline(0,   'k-',  'LineWidth',  0.5)
xlabel('Time (s)', 'FontSize', 13)
ylabel('Error %', 'FontSize', 13)
title('Error % Comparison: ANFIS vs Fixed Gains', ...
      'FontSize', 14, 'FontWeight', 'bold')
legend('FontSize', 12, 'Location', 'northeast')
grid on
saveas(fig, [outFolder '07_Error_Comparison_ANFIS_vs_Fixed.png'])
fprintf('Figure 07 saved.\n')

%% ============================================================
%% FIGURE 08 — Gain Correction Factors
%% ============================================================
fig = figure('Name','08 Gain Corrections','Position',[50 50 1100 600]);
subplot(2,1,1)
plot(t, Kp_corr_vec, 'b', 'LineWidth', 2)
hold on
yline(1, 'k--', 'Fixed baseline = 1', 'LineWidth', 1.2)
ylabel('Kp\_corr', 'FontSize', 12)
title('ANFIS Output: Kp Correction Factor over Time', ...
      'FontSize', 13, 'FontWeight', 'bold')
grid on
text(50, max(Kp_corr_vec)*0.97, ...
     sprintf('Range: [%.3f,  %.3f]', min(Kp_corr_vec), max(Kp_corr_vec)), ...
     'FontSize', 10, 'Color', 'blue', 'BackgroundColor', 'white')

subplot(2,1,2)
plot(t, Ki_corr_vec, 'r', 'LineWidth', 2)
hold on
yline(1, 'k--', 'Fixed baseline = 1', 'LineWidth', 1.2)
xlabel('Time (s)', 'FontSize', 12)
ylabel('Ki\_corr', 'FontSize', 12)
title('ANFIS Output: Ki Correction Factor over Time', ...
      'FontSize', 13, 'FontWeight', 'bold')
grid on
text(50, min(Ki_corr_vec)+0.01, ...
     sprintf('Range: [%.3f,  %.3f]', min(Ki_corr_vec), max(Ki_corr_vec)), ...
     'FontSize', 10, 'Color', 'red', 'BackgroundColor', 'white')
saveas(fig, [outFolder '08_Gain_Correction_Factors.png'])
fprintf('Figure 08 saved.\n')

%% ============================================================
%% FIGURE 09 — Adaptive Gains vs Fixed
%% ============================================================
fig = figure('Name','09 Adaptive Gains','Position',[50 50 1100 600]);
subplot(2,1,1)
plot(t, Kp_final_vec, 'b', 'LineWidth', 2, 'DisplayName', 'Kp\_final (ANFIS)')
hold on
yline(Kp_fixed, 'r--', sprintf('Kp fixed = %.1f', Kp_fixed), 'LineWidth', 2)
ylabel('Kp\_final', 'FontSize', 12)
title('Adaptive Kp\_final vs Fixed Baseline', ...
      'FontSize', 13, 'FontWeight', 'bold')
legend('FontSize', 11); grid on

subplot(2,1,2)
plot(t, Ki_final_vec, 'r', 'LineWidth', 2, 'DisplayName', 'Ki\_final (ANFIS)')
hold on
yline(Ki_fixed, 'b--', sprintf('Ki fixed = %.1f', Ki_fixed), 'LineWidth', 2)
xlabel('Time (s)', 'FontSize', 12)
ylabel('Ki\_final', 'FontSize', 12)
title('Adaptive Ki\_final vs Fixed Baseline', ...
      'FontSize', 13, 'FontWeight', 'bold')
legend('FontSize', 11); grid on
saveas(fig, [outFolder '09_Adaptive_Gains_vs_Fixed.png'])
fprintf('Figure 09 saved.\n')

%% ============================================================
%% FIGURE 10 — Kp Rule Surface
%% ============================================================
fig = figure('Name','10 Kp Rule Surface','Position',[50 50 800 600]);
gensurf(anfis_kp)
title('ANFIS Learned Surface: Kp\_corr = f(error, disturbance)', ...
      'FontSize', 13, 'FontWeight', 'bold')
xlabel('Error (normalized)', 'FontSize', 12)
ylabel('Disturbance A',      'FontSize', 12)
zlabel('Kp\_corr',           'FontSize', 12)
colorbar
saveas(fig, [outFolder '10_ANFIS_Kp_Rule_Surface.png'])
fprintf('Figure 10 saved.\n')

%% ============================================================
%% FIGURE 11 — Ki Rule Surface
%% ============================================================
fig = figure('Name','11 Ki Rule Surface','Position',[50 50 800 600]);
gensurf(anfis_ki)
title('ANFIS Learned Surface: Ki\_corr = f(error, disturbance)', ...
      'FontSize', 13, 'FontWeight', 'bold')
xlabel('Error (normalized)', 'FontSize', 12)
ylabel('Disturbance A',      'FontSize', 12)
zlabel('Ki\_corr',           'FontSize', 12)
colorbar
saveas(fig, [outFolder '11_ANFIS_Ki_Rule_Surface.png'])
fprintf('Figure 11 saved.\n')

%% ============================================================
%% FIGURE 12 — Both Rule Surfaces
%% ============================================================
fig = figure('Name','12 Both Surfaces','Position',[50 50 1200 550]);
subplot(1,2,1)
gensurf(anfis_kp)
title('Kp\_corr surface', 'FontSize', 13, 'FontWeight', 'bold')
xlabel('Error (norm)'); ylabel('Disturbance A'); zlabel('Kp\_corr')

subplot(1,2,2)
gensurf(anfis_ki)
title('Ki\_corr surface', 'FontSize', 13, 'FontWeight', 'bold')
xlabel('Error (norm)'); ylabel('Disturbance A'); zlabel('Ki\_corr')
saveas(fig, [outFolder '12_Both_Rule_Surfaces.png'])
fprintf('Figure 12 saved.\n')

%% ============================================================
%% FIGURE 13 — Membership Functions Kp
%% ============================================================
fig = figure('Name','13 MF Kp','Position',[50 50 1000 450]);
subplot(1,2,1)
plotmf(anfis_kp, 'input', 1)
title('Kp model — Error membership functions', ...
      'FontSize', 12, 'FontWeight', 'bold')
xlabel('Normalized error')

subplot(1,2,2)
plotmf(anfis_kp, 'input', 2)
title('Kp model — Disturbance membership functions', ...
      'FontSize', 12, 'FontWeight', 'bold')
xlabel('Disturbance A')
saveas(fig, [outFolder '13_MembershipFunctions_Kp.png'])
fprintf('Figure 13 saved.\n')

%% ============================================================
%% FIGURE 14 — Membership Functions Ki
%% ============================================================
fig = figure('Name','14 MF Ki','Position',[50 50 1000 450]);
subplot(1,2,1)
plotmf(anfis_ki, 'input', 1)
title('Ki model — Error membership functions', ...
      'FontSize', 12, 'FontWeight', 'bold')
xlabel('Normalized error')

subplot(1,2,2)
plotmf(anfis_ki, 'input', 2)
title('Ki model — Disturbance membership functions', ...
      'FontSize', 12, 'FontWeight', 'bold')
xlabel('Disturbance A')
saveas(fig, [outFolder '14_MembershipFunctions_Ki.png'])
fprintf('Figure 14 saved.\n')

%% ============================================================
%% FIGURE 15 — Training Convergence
%% ============================================================
fig = figure('Name','15 Training Convergence','Position',[50 50 1000 450]);
subplot(1,2,1)
plot(trnErr_kp, 'b', 'LineWidth', 2.5)
xlabel('Epoch', 'FontSize', 12)
ylabel('RMSE',  'FontSize', 12)
title('Kp ANFIS — Training Error Convergence', ...
      'FontSize', 13, 'FontWeight', 'bold')
text(5, trnErr_kp(1)*0.95, ...
     sprintf('Start: %.4f\nFinal:  %.6f', trnErr_kp(1), trnErr_kp(end)), ...
     'FontSize', 10, 'BackgroundColor', 'white')
grid on

subplot(1,2,2)
plot(trnErr_ki, 'r', 'LineWidth', 2.5)
xlabel('Epoch', 'FontSize', 12)
ylabel('RMSE',  'FontSize', 12)
title('Ki ANFIS — Training Error Convergence', ...
      'FontSize', 13, 'FontWeight', 'bold')
text(5, trnErr_ki(1)*0.95, ...
     sprintf('Start: %.6f\nFinal:  %.8f', trnErr_ki(1), trnErr_ki(end)), ...
     'FontSize', 10, 'BackgroundColor', 'white')
grid on
saveas(fig, [outFolder '15_Training_Convergence.png'])
fprintf('Figure 15 saved.\n')

%% ============================================================
%% FIGURE 16 — Performance Bar Chart
%% ============================================================
fig = figure('Name','16 Performance Bar Chart','Position',[50 50 900 550]);
vals_f = [OS_fixed,  US_fixed];
vals_a = [OS_anfis,  US_anfis];
x      = 1:2;
b1 = bar(x - 0.2, vals_f, 0.35, 'FaceColor', [0.85 0.2 0.2]);
hold on
b2 = bar(x + 0.2, vals_a, 0.35, 'FaceColor', [0.2 0.4 0.85]);
set(gca, 'XTick', x, 'XTickLabel', {'Max Overshoot %','Max Undershoot %'}, ...
    'FontSize', 12)
ylabel('Percentage (%)', 'FontSize', 13)
title('Performance Comparison: Fixed Gains vs ANFIS Adaptive', ...
      'FontSize', 14, 'FontWeight', 'bold')
legend([b1 b2], {'Fixed Gains PI','ANFIS Adaptive'}, 'FontSize', 12)
grid on
for i = 1:2
    text(i-0.2, vals_f(i)+0.3, sprintf('%.1f%%', vals_f(i)), ...
         'HorizontalAlignment','center','FontSize',11,'Color',[0.85 0.2 0.2])
    text(i+0.2, vals_a(i)+0.3, sprintf('%.3f%%', vals_a(i)), ...
         'HorizontalAlignment','center','FontSize',11,'Color',[0.2 0.4 0.85])
end
saveas(fig, [outFolder '16_Performance_Bar_Chart.png'])
fprintf('Figure 16 saved.\n')

%% ============================================================
%% FIGURE 17 — Requirements Boundary Check
%% ============================================================
fig = figure('Name','17 Requirements Check','Position',[50 50 1000 500]);
t_rel = t_a_dist - t_a_dist(1);
plot(t_rel, epct_a_dist, 'b', 'LineWidth', 2.5, 'DisplayName', 'ANFIS response')
hold on
yline(20,  'r-',  'OS limit = 20%',           'LineWidth', 2, 'LabelHorizontalAlignment','left')
yline(-20, 'r-',  'US limit = -20%',          'LineWidth', 2, 'LabelHorizontalAlignment','left')
yline(15,  'g--', 'OS limit = 15% (strict)',  'LineWidth', 1.2, 'LabelHorizontalAlignment','left')
yline(-15, 'g--', 'US limit = -15% (strict)', 'LineWidth', 1.2, 'LabelHorizontalAlignment','left')
yline(0,   'k-',  'LineWidth', 0.8)
xlabel('Time from disturbance start (s)', 'FontSize', 13)
ylabel('Actual value deviation %',        'FontSize', 13)
title('Requirements Figure — ANFIS Response vs Limits', ...
      'FontSize', 14, 'FontWeight', 'bold')
legend('FontSize', 11, 'Location', 'northeast')
grid on
saveas(fig, [outFolder '17_Requirements_Boundary_Check.png'])
fprintf('Figure 17 saved.\n')

%% ============================================================
%% FIGURE 18 — System Architecture Summary
%% ============================================================
fig = figure('Name','18 System Overview','Position',[50 50 900 500]);
axis off
title('ANFIS-PI Adaptive Control System — Architecture', ...
      'FontSize', 14, 'FontWeight', 'bold')
text(0.05, 0.88, 'INPUTS TO SYSTEM:', ...
     'FontSize', 12, 'FontWeight', 'bold', 'Color', 'blue')
text(0.05, 0.78, '  Setpoint: 900 RPM (fixed)',     'FontSize', 11)
text(0.05, 0.68, '  Disturbance A: range [0, 1]',   'FontSize', 11)
text(0.05, 0.58, '  Plant parameters B, C, D',       'FontSize', 11)

text(0.05, 0.44, 'INPUTS TO ANFIS ML MODEL:', ...
     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.5 0 0.5])
text(0.05, 0.34, '  Error e(t) = 900 - RPM(t)',     'FontSize', 11)
text(0.05, 0.24, '  Disturbance A(t)',               'FontSize', 11)

text(0.52, 0.88, 'OUTPUTS FROM ANFIS:', ...
     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.8 0.4 0])
text(0.52, 0.78, '  Kp_corr(t) — multiplier for Kp', 'FontSize', 11)
text(0.52, 0.68, '  Ki_corr(t) — multiplier for Ki',  'FontSize', 11)

text(0.52, 0.44, 'FINAL GAINS:', ...
     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0.5 0])
text(0.52, 0.34, '  Kp_final = Kp_fixed x Kp_corr', 'FontSize', 11)
text(0.52, 0.24, '  Ki_final = Ki_fixed x Ki_corr',  'FontSize', 11)

text(0.05, 0.08, ...
     'ANFIS: 9 rules | 3x3 grid partition | 100 epochs | 66667 training points | Hybrid algorithm', ...
     'FontSize', 10, 'Color', [0.3 0.3 0.3])
saveas(fig, [outFolder '18_System_Architecture_Summary.png'])
fprintf('Figure 18 saved.\n')

%% ============================================================
%% PRINT COMPLETE METRICS TABLE
%% ============================================================
fprintf('\n')
fprintf('╔══════════════════════════════════════════════════════════╗\n')
fprintf('║         COMPLETE PERFORMANCE METRICS TABLE              ║\n')
fprintf('╠══════════════════════════════════════════════════════════╣\n')
fprintf('║ %-25s  %12s  %12s ║\n', 'Metric', 'Fixed Gains', 'ANFIS')
fprintf('╠══════════════════════════════════════════════════════════╣\n')
fprintf('║ %-25s  %11.2f%%  %11.4f%% ║\n', 'Max Overshoot',     OS_fixed,       OS_anfis)
fprintf('║ %-25s  %11.2f%%  %11.4f%% ║\n', 'Max Undershoot',    US_fixed,       US_anfis)
fprintf('║ %-25s  %11.1f s  %11.4f s ║\n', 'Settling time',     T_settle_fixed, T_settle_anfis)
fprintf('║ %-25s  %11.1f s  %11.4f s ║\n', 'Steady-state time', T_ss_fixed,     T_ss_anfis)
fprintf('║ %-25s  %11.1f    %11.4f   ║\n', 'Max RPM deviation', maxRPMdev_fixed,maxRPMdev_anfis)
fprintf('╠══════════════════════════════════════════════════════════╣\n')
fprintf('║ %-25s  %10.1f%%              ║\n', 'OS Improvement',    improvement_OS)
fprintf('║ %-25s  %10.1f%%              ║\n', 'RPM Improvement',   improvement_RPM)
fprintf('╠══════════════════════════════════════════════════════════╣\n')
fprintf('║ ANFIS MODEL DETAILS                                     ║\n')
fprintf('║  Rules:             9  (3 error x 3 disturbance)       ║\n')
fprintf('║  Training points:   66667                              ║\n')
fprintf('║  Epochs:            100                                ║\n')
fprintf('║  Algorithm:         Hybrid (LSE + Gradient Descent)    ║\n')
fprintf('║  Kp_corr range:     [%.3f,  %.3f]                   ║\n', min(Kp_corr_vec), max(Kp_corr_vec))
fprintf('║  Ki_corr range:     [%.3f,  %.3f]                   ║\n', min(Ki_corr_vec), max(Ki_corr_vec))
fprintf('║  Kp training RMSE:  %.6f                          ║\n', trnErr_kp(end))
fprintf('║  Ki training RMSE:  %.8f                        ║\n', trnErr_ki(end))
fprintf('╚══════════════════════════════════════════════════════════╝\n')

fprintf('\n=================================================\n')
fprintf('   ALL 18 FIGURES SAVED TO: plots\\PPT_FINAL\\\n')
fprintf('=================================================\n')