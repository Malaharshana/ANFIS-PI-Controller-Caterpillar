%% Generate All Output Plots

load('results\full_simulation.mat')
load('models\trained_anfis.mat')

setpoint = 900;

%% PLOT 1 - RPM Tracking
figure('Name','RPM Tracking','Position',[100 100 900 400])
plot(t, y, 'b', 'LineWidth', 2)
yline(900, 'r--', 'Setpoint 900 RPM', 'LineWidth', 1.5)
xlabel('Time (s)'); ylabel('RPM')
title('ANFIS Adaptive Control — RPM Tracking')
grid on; ylim([0 1100])
saveas(gcf, 'plots\plot1_rpm_tracking.png')
fprintf('Plot 1 saved.\n')

%% PLOT 2 - Error %
figure('Name','Error Deviation','Position',[100 100 900 400])
error_pct = (e / setpoint) * 100;
plot(t, error_pct, 'r', 'LineWidth', 2)
yline(0, 'k--')
yline(25, 'r:', 'Max OS limit')
yline(-25, 'b:', 'Max US limit')
xlabel('Time (s)'); ylabel('Error %')
title('Error Deviation %')
grid on
saveas(gcf, 'plots\plot2_error_pct.png')
fprintf('Plot 2 saved.\n')

%% PLOT 3 - ANFIS Rule Surfaces (UNIQUE)
figure('Name','ANFIS Rule Surfaces','Position',[100 100 1000 450])
subplot(1,2,1)
gensurf(anfis_kp)
title('Kp correction surface')
xlabel('Error (normalized)'); ylabel('Disturbance A'); zlabel('Kp corr')

subplot(1,2,2)
gensurf(anfis_ki)
title('Ki correction surface')
xlabel('Error (normalized)'); ylabel('Disturbance A'); zlabel('Ki corr')
saveas(gcf, 'plots\plot3_anfis_surfaces.png')
fprintf('Plot 3 saved.\n')

%% PLOT 4 - Training Convergence
figure('Name','Training Convergence','Position',[100 100 800 400])
subplot(1,2,1)
plot(trnErr_kp, 'b', 'LineWidth', 1.5)
xlabel('Epoch'); ylabel('RMSE')
title('Kp ANFIS training convergence')
grid on

subplot(1,2,2)
plot(trnErr_ki, 'r', 'LineWidth', 1.5)
xlabel('Epoch'); ylabel('RMSE')
title('Ki ANFIS training convergence')
grid on
saveas(gcf, 'plots\plot4_training_convergence.png')
fprintf('Plot 4 saved.\n')

%% PLOT 5 - Membership Functions
figure('Name','Membership Functions','Position',[100 100 900 400])
subplot(1,2,1)
plotmf(anfis_kp, 'input', 1)
title('Error membership functions (trained)')

subplot(1,2,2)
plotmf(anfis_kp, 'input', 2)
title('Disturbance membership functions (trained)')
saveas(gcf, 'plots\plot5_membership_functions.png')
fprintf('Plot 5 saved.\n')

fprintf('\n=== All plots saved to plots folder ===\n')