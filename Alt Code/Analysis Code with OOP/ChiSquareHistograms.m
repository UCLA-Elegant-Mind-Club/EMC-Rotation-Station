figure()
hold on;
lefts = [plotters.left];
rights = [plotters.right];
allredchi = sort([[lefts.redChiSquare], [rights.redChiSquare]]);
Histogram = histfit(allredchi,10,'gamma');
pd = gamfit(allredchi,10);

ms = MultiStart;
gampoint = @(x) -gampdf(x, pd(1), pd(2));
problem = createOptimProblem('fmincon', 'x0', 1, ...
    'objective', gampoint, 'lb' , 0, 'ub', 3);
params = run(ms,problem,25);

xlim([0 15]);
ylim([0 55]);
xlabel("Reduced Chi Squares")
ylabel("Frequency")
subtitle(sprintf("Gamma Distribution: a = %.2f, b = %.2f, max = %.2f", pd(1), pd(2), params(1)));