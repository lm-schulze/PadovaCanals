function dOdt = oxygen_model_I(t, O, I_fun,p)
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
    PhS = p.A * I / (I + p.alpha1);

    %respiración fotosintética
    PhR = p.B * I / (I + p.beta1);

    loss = p.kLoss * O;

    %balance
    dOdt = PhS - PhR - loss;
end    