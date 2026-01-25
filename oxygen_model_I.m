function dOdt = oxygen_model_I(t, O, I_fun, p)

%asignar parámetros
params.A = p(1);
params.alpha1 = p(2);
params.B = p(3);
params.beta1 = p(4);
params.kLoss = p(5);

%modelo de DO dependiente de la irradiancia
%entrada: t (tiempo), O (o2 disuelto), I_fun (función irradiancia),
 % p (parámetros)

    %irradiancia interpolada
    I = I_fun(t);

    %evitar valores negativos o NaN
    if isnan(I) || isinf(I) || I < 0
        I = 0;
    end

    %fotosíntesis bruta
    PhS = params.A * I / (I + params.alpha1);

    %respiración fotosintética
    PhR = params.B * I / (I + params.beta1);

    loss = params.kLoss * O;

    %balance
    dOdt = PhS - PhR - loss;
end    