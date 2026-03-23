function Ki_final = anfis_ki_wrapper(u)
persistent fis em
if isempty(fis)
    d = load('D:\MATLAB\CATERPILLAR\models\trained_anfis.mat');
    fis = d.anfis_ki;
    em  = d.e_max;
end
e_norm = max(-1, min(1, u(1)/em));
A      = max(0,  min(1, u(2)));
Ki_corr = evalfis(fis, [e_norm, A]);
Ki_final = max(0.3, min(2.0, Ki_corr));