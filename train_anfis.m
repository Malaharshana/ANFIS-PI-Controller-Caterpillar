%% Train ANFIS Models

load('training\anfis_training_data.mat')

% Normalize error to [-1, 1]
e_max = max(abs(e));
error_norm = e / e_max;

% Prepare training data
trnData_kp = [error_norm, A, Kp_corr_optimal];
trnData_ki = [error_norm, A, Ki_corr_optimal];

% Remove bad rows
trnData_kp = trnData_kp(all(isfinite(trnData_kp), 2), :);
trnData_ki = trnData_ki(all(isfinite(trnData_ki), 2), :);

fprintf('Training points: %d\n', size(trnData_kp,1))

% Generate initial FIS (3 membership functions per input = 9 rules)
opt_gen = genfisOptions('GridPartition');
opt_gen.NumMembershipFunctions = [3 3];
opt_gen.InputMembershipFunctionType = 'trimf';

fis_kp_init = genfis(trnData_kp(:,1:2), trnData_kp(:,3), opt_gen);
fis_ki_init = genfis(trnData_ki(:,1:2), trnData_ki(:,3), opt_gen);

fprintf('Rules generated: %d\n', length(fis_kp_init.Rules))

% Train Kp ANFIS
fprintf('\nTraining Kp ANFIS...\n')
opt_train = anfisOptions('InitialFIS', fis_kp_init, 'EpochNumber', 100, 'OptimizationMethod', 1);
[anfis_kp, trnErr_kp] = anfis(trnData_kp, opt_train);
fprintf('Kp done. Final error: %.6f\n', trnErr_kp(end))

% Train Ki ANFIS
fprintf('\nTraining Ki ANFIS...\n')
opt_train.InitialFIS = fis_ki_init;
[anfis_ki, trnErr_ki] = anfis(trnData_ki, opt_train);
fprintf('Ki done. Final error: %.6f\n', trnErr_ki(end))

% Save
save('models\trained_anfis.mat', 'anfis_kp', 'anfis_ki', 'trnErr_kp', 'trnErr_ki', 'e_max')
fprintf('\n=== ANFIS models saved ===\n')