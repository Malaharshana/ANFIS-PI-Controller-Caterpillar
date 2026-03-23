%% Compute Optimal Gain Correction Factors
% Uses the clean signals from the sample data to compute
% what Kp_corr and Ki_corr should be at each operating point

load('data\clean_signals.mat')

setpoint = 900;
n = length(e);

Kp_corr_optimal = zeros(n, 1);
Ki_corr_optimal = zeros(n, 1);

for i = 1:n
    e_i = e(i);
    A_i = A(i);
    
    % Physics-informed correction formula
    kp_guess = 1.0 + 0.8 * A_i + 0.3 * abs(e_i) / setpoint;
    ki_guess = 1.0 / (1.0 + 0.5 * A_i);
    
    % Clamp to safe range
    Kp_corr_optimal(i) = max(0.5, min(2.5, kp_guess));
    Ki_corr_optimal(i) = max(0.3, min(2.0, ki_guess));
end

save('training\anfis_training_data.mat', ...
     'e', 'A', 'Kp_corr_optimal', 'Ki_corr_optimal')

fprintf('Done. Kp_corr range: [%.3f, %.3f]\n', min(Kp_corr_optimal), max(Kp_corr_optimal))
fprintf('Done. Ki_corr range: [%.3f, %.3f]\n', min(Ki_corr_optimal), max(Ki_corr_optimal))
