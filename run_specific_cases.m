%% Run all specific step/shed cases from problem statement
clear; clc;
clear functions

% Switch back to Group 1 first
signalbuilder('ProblemState_ANFIS/Disturbances', 'activegroup', 1);

% name, step size, [req_OS%, req_US%, req_Ts(s), req_SS(s)]
step_cases = {
    '5pct',  0.05, [15, 15,  3,  8];
    '10pct', 0.10, [20, 20,  5, 10];
    '15pct', 0.15, [20, 20,  5, 10];
    '20pct', 0.20, [25, 25, 10, 15];
    '30pct', 0.30, [25, 25, 10, 15];
};

results_specific = struct();

for k = 1:5
    name   = step_cases{k,1};
    step   = step_cases{k,2};
    req    = step_cases{k,3};
    req_OS = req(1);
    req_US = req(2);
    req_Ts = req(3);
    req_SS = req(4);
    
    % Build step/shed profile
    % Steps up from 0 to 1 in increments of step_size
    % then steps back down to 0
    n_steps  = round(1 / step);
    
    % Time: spread 1000s equally — 500s up, 500s down
    dt       = 500 / n_steps;
    
    % Up phase
    t_up = zeros(1, n_steps*2);
    A_up = zeros(1, n_steps*2);
    for i = 0:n_steps-1
        t_up(i*2+1) = i * dt;
        t_up(i*2+2) = i * dt + 0.001;
        A_up(i*2+1) = i * step;
        A_up(i*2+2) = (i+1) * step;
    end
    
    % Down phase
    t_down = zeros(1, n_steps*2);
    A_down = zeros(1, n_steps*2);
    for i = 0:n_steps-1
        t_down(i*2+1) = 500 + i * dt;
        t_down(i*2+2) = 500 + i * dt + 0.001;
        A_down(i*2+1) = 1 - i * step;
        A_down(i*2+2) = 1 - (i+1) * step;
    end
    
    t_prof = [t_up, t_down, 1000];
    A_prof = [A_up, A_down, 0];
    
    % Add as new group
    signalbuilder('ProblemState_ANFIS/Disturbances', ...
                  'appendgroup', {t_prof}, {A_prof}, name);
    
    % Activate this group (groups 7 onwards)
    signalbuilder('ProblemState_ANFIS/Disturbances', ...
                  'activegroup', k + 6);
    
    % Run simulation
    fprintf('Running %s...\n', name)
    simOut_k = sim('data\ProblemState_ANFIS', 'StopTime', '1000');
    
    t_k = simOut_k.logsout{4}.Values.Time;
    y_k = simOut_k.logsout{4}.Values.Data;
    e_k = simOut_k.logsout{7}.Values.Data;
    A_k = simOut_k.logsout{2}.Values.Data;
    
    % Metrics — only after first disturbance step
    idx_s = find(t_k >= 100, 1);
    epct  = (e_k(idx_s:end) / 900) * 100;
    t_s   = t_k(idx_s:end);
    
    OS_k = max(epct);
    US_k = abs(min(epct));
    
    idx_ts = find(abs(epct) > 1, 1, 'last');
    Ts_k   = 0;
    if ~isempty(idx_ts)
        idx_ts = min(idx_ts, length(t_s));
        Ts_k   = t_s(idx_ts) - t_s(1);
    end
    
    idx_ss = find(abs(epct) > 0.25, 1, 'last');
    SS_k   = 0;
    if ~isempty(idx_ss)
        idx_ss = min(idx_ss, length(t_s));
        SS_k   = t_s(idx_ss) - t_s(1);
    end
    
    pass_OS = OS_k <= req_OS;
    pass_US = US_k <= req_US;
    pass_Ts = Ts_k <= req_Ts;
    
    results_specific(k).name   = name;
    results_specific(k).step   = step;
    results_specific(k).OS     = OS_k;
    results_specific(k).US     = US_k;
    results_specific(k).Ts     = Ts_k;
    results_specific(k).SS     = SS_k;
    results_specific(k).req_OS = req_OS;
    results_specific(k).req_US = req_US;
    results_specific(k).req_Ts = req_Ts;
    results_specific(k).t      = t_k;
    results_specific(k).y      = y_k;
    results_specific(k).e      = e_k;
    results_specific(k).A      = A_k;
    
    fprintf('  OS: %.3f%% (req<%d%%) [%s]\n', OS_k, req_OS, pass_fail(pass_OS))
    fprintf('  US: %.3f%% (req<%d%%) [%s]\n', US_k, req_US, pass_fail(pass_US))
    fprintf('  Ts: %.1fs   (req<%ds)  [%s]\n', Ts_k, req_Ts, pass_fail(pass_Ts))
    fprintf('\n')
end

save('results\specific_cases.mat', 'results_specific')
fprintf('All 5 cases complete.\n')

function s = pass_fail(x)
    if x; s = 'PASS'; else; s = 'FAIL'; end
end