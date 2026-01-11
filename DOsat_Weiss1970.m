function DOsat = DOsat_Weiss1970(T_C)
% this one is for fresh water
% no idea if that is ok to use
% maybe ask prof about that?
    T = T_C + 273.15; % convert to Kelvin
    A1 = -173.4292;
    A2 = 249.6339;
    A3 = 143.3483;
    A4 = -21.8492;
    DOsat_mlL = exp(A1 + A2*(100./T) + A3*log(T/100) + A4*(T/100));
    DOsat = DOsat_mlL * 1.429; % convert ml/L to mg/L
end
