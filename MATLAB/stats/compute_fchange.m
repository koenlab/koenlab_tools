function [delta_r2,delta_f_obs,delta_f_p] = compute_fchange(reg1,reg2)
% Uses regstats object
% Reg 1 should have more predictors than reg2, and reg2 shoudl be nested in
% reg1.


% compute the output
delta_r2 = reg1.rsquare - reg2.rsquare;
k1 = reg1.fstat.dfr;
k2 = reg2.fstat.dfr;
n = length(reg1.yhat); % Should add check that reg1 adn reg2 have same n
delta_f_obs = (delta_r2/(1-reg1.rsquare)) * ((n-k1-k2-1)/k1);
delta_f_p   =  1-fcdf(delta_f_obs, k2, k1);

end % of function