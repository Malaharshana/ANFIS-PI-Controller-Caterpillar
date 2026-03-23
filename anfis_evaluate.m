function [Kp_corr, Ki_corr] = anfis_evaluate(e, A)

persistent anfis_kp anfis_ki e_max_val

if isempty(anfis_kp)
    data = load('D:\MATLAB\CATERPILLAR\models\trained_anfis.mat');
    anfis_kp  = data.anfis_kp;
    anfis_ki  = data.anfis_ki;
    e_max_val = data.e_max;
end

% Normalize error same way as training
e_norm = e / e_max_val;

% Clamp inputs to valid range
e_norm = max(-1, min(1, e_norm));
A      = max(0,  min(1, A));

% Evaluate ANFIS
Kp_corr = evalfis(anfis_kp, [e_norm, A]);
Ki_corr = evalfis(anfis_ki, [e_norm, A]);

% Safety clamp on outputs
Kp_corr = max(0.5, min(2.5, Kp_corr));
Ki_corr = max(0.3, min(2.0, Ki_corr));