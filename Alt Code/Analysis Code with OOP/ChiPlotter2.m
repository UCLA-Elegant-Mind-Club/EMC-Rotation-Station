classdef ChiPlotter2 < ChiPlotter
    methods (Access = public)
        
        %% Evaluates trendlines to return y value
        function yVal = evaluate(this, xVal, side)
            if nargin < 3; side = "none"; else; side = lower(side + ""); end
            if side == "left" || (xVal < this.centerVal && side ~= "right")
                yVal = this.left.quadCoef * xVal^2 + this.left.slope * xVal + this.left.intercept;
            elseif side == "right" || xVal > this.centerVal
                yVal = this.right.quadCoef * xVal^2 + this.right.slope * xVal + this.right.intercept;
            else
                yVal = (this.evaluate(xVal, "left") + this.evaluate(xVal, "right"))/2;
            end
        end
        
        %%
        function plotTrendlines(this, plotStyle, axes, bounds)
            if nargin < 2; plotStyle = this.defaultPlotStyle; end
            if nargin < 3; axes = gca; end
            if nargin < 4; bounds = [min(this.xVals), max(this.xVals)]; end
            
            if bounds(1) < this.centerVal
                x = linspace(bounds(1),min(bounds(2), this.centerVal));
                y = zeros(1,100);
                for i = 1:100; y(i) = this.evaluate(x(i), "left"); end
                this.left.line = plot(axes, x, y, 'Color', this.color, ...
                    'LineWidth', plotStyle.LineWidth, 'LineStyle', plotStyle.LineStyle);
                this.left.label = sprintf("y = %.3f x^2 + %.3f x + %.3f \n X^2 = %.3f", ...
                    this.left.quadCoef, this.left.slope, this.left.intercept, this.left.redChiSquare);
            end
            if bounds(2) <= this.centerVal
                this.right.line = this.left.line;
                this.right.label = this.left.label;
            else
                x = linspace(max(bounds(1), this.centerVal), bounds(2));
                for i = 1:100; y(i) = this.evaluate(x(i), "right"); end
                this.right.line = plot(axes, x, y, 'Color', this.color, ...
                    'LineWidth', plotStyle.LineWidth, 'LineStyle', plotStyle.LineStyle);
                this.right.label = sprintf("y = %.3f x^2 + %.3f x + %.3f \n X^2 = %.3f", ...
                    this.right.quadCoef, this.right.slope, this.right.intercept, this.right.redChiSquare);
            end
            if bounds(1) >= this.centerVal
                this.left.line = this.right.line;
                this.left.label = this.right.label;
            end
        end
        
        function plotter = copy(this)
            plotter = ChiPlotter2();
            fNames = fieldnames(this);
            for i = 1:length(fNames)
                try plotter.(fNames{i}) = this.(fNames{i}); catch; end
            end
            plotter.included = this.included;
        end
    end
    
    methods (Static)
        %%
        function [fit] = ChiSquareFit(xVals, xErr, yVals, yErr, dif, weightBound)
            if nargin < 5; dif = 0; end
            if nargin < 6; weightBound = 0; end
            
            lineFit = polyfit(xVals, yVals, 2);
            R = 0; %No Pearson coefficient for non-linear relationships
            [normalQuad, normalSlope, normalIntercept] = deal(lineFit(1), lineFit(2), lineFit(3));

            weights = (1 ./ (yErr + weightBound)) .^2;
            chiSquareFormula = @(equation) sum(weights .* (yVals - (equation(1) * xVals.^2 ...
                + equation(2) * xVals + equation(3))) .^2);
            ms = MultiStart;
            lowerBounds = [-5 -10 200];
            upperBounds = [5 10 1000];
            problem = createOptimProblem('fmincon', 'x0', [normalQuad, normalSlope, normalIntercept], ...
                'objective', chiSquareFormula, 'lb' , lowerBounds, 'ub', upperBounds);
            warning("off"); chiFit = run(ms, problem, 25); warning("on");
            [quad, slope, intercept] = deal(chiFit(1), chiFit(2), chiFit(3));
            chiSquare = chiSquareFormula(chiFit);
            degFree = length(xVals) - 2;
            redChiSquare = chiSquare / degFree;

            % Formulas for standard errors of slope and intercept found online at
            % https://www.math.csi.cuny.edu/~poje/Teach/Computer/Chi2.pdf
            if(dif == 0)
                xDifSquare = sum((xVals - mean(xVals)).^2);
                yResSquare = sum((yVals - slope * xVals - intercept).^2);
                slopeError = sqrt(yResSquare / degFree / xDifSquare);
                interceptError = sqrt(yResSquare / degFree * (1/length(xVals) + mean(xVals)^2 / xDifSquare));
            else
                syms testSlope;
                slopeBounds = solve(chiSquareFormula([testSlope, intercept]) == chiSquare*(dif + 1), testSlope); 
                slopeError = max(abs(double(slopeBounds) - slope));
            
                syms testIntercept;
                interceptBounds = solve(chiSquareFormula([slope, testIntercept]) == chiSquare*(dif + 1), testIntercept); 
                interceptError = max(abs(double(interceptBounds) - intercept));
            end
            
            fit = struct('R', R, 'quadCoef', quad, 'slope', slope, 'intercept', intercept, 'chiSquare', chiSquare, ...
                'redChiSquare', redChiSquare, 'slopeError', slopeError, 'interceptError', interceptError, ...
                'normalQuad', normalQuad, 'normalSlope', normalSlope, 'normalIntercept', normalIntercept);
        end
    end
end