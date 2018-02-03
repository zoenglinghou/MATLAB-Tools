function [ S_y, S_xx, P_y, P_y_hat ] = precisionError( ldm )
% precisionError: Returns standard errors & precision uncertainties given linear fit model ldm
%
% [ S_y, S_xx, P_y, P_y_hat ] = precisionError( ldm )

% Parse x & y data
x = ldm.Variables.x1;
y = ldm.Variables.y;
N = ldm.NumObservations;

% Standard error
S_y = ldm.RMSE;
S_xx = sum(x .^ 2) - sum(x) ^ 2 / N;

% Precision uncertainty
P_y = 2 ...
    * (...
        S_y .^ 2 ...
        .* (1 + 1 / N + (x - mean(x)) .^ 2 / S_xx)...
    ) .^ (1/2) ...
;
P_y_hat = 2 ...
    * (...
        S_y .^ 2 ...
        .* (1 / N + (x - mean(x)) .^ 2 / S_xx)...
    ) .^ (1/2) ...
;

end  % precisionError
