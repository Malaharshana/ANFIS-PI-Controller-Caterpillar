function Kp_final = anfis_kp_wrapper(u)
persistent fis em
if isempty(fis)
    d = load('D:\MATLAB\CATERPILLAR\models\trained_anfis.mat');
    fis = d.anfis_kp;
    em  = d.e_max;
end
e_norm = max(-1, min(1, u(1)/em));
A      = max(0,  min(1, u(2)));
Kp_corr = evalfis(fis, [e_norm, A]);
Kp_final = max(0.5, min(2.5, Kp_corr));