classdef ChiPlotter < handle
    properties (Constant)
        defaultPlotStyle = struct('dotSize', 20, 'LineWidth', 2, 'LineStyle', '-');
        defaultErrorBars = struct('horizJitter', 0, 'showYBars', true, ...
            'vertJitter', 0, 'showXBars', true, 'width', 1, 'style', '--');
        startingColors = [ [1 0 0]; [0 1 0]; [0 0 1]; ...
            [1 1 0]; [0 1 1]; [1 0 1]];
    end
    properties (Access = public)
        centerVal = -Inf; left; right;
        included; dif = 0; weightBound = 0.0001;
        series; label = ""; color = 'black';
    end
    properties (Access = protected)
        data;
    end
    properties (Dependent)
        xVals; xError; yVals; yError;
    end
    %% Get and Set Methods for Dependent Properties
    methods
        function xVals = get.xVals(this); xVals = this.data(:, 1); end
        function set.xVals(this, xVals); this.data(:,1) = xVals; end
        function xError = get.xError(this); xError = this.data(:, 2); end
        function set.xError(this, xError)
            if length(xError) == 1; xError = ones(length(this.xVals),1) * xError; end
            this.data(:,2) = xError; end
        function yVals = get.yVals(this); yVals = this.data(:, 3); end
        function set.yVals(this, yVals); this.data(:,3) = yVals; end
        function yError = get.yError(this); yError = this.data(:, 4); end
        function set.yError(this, yError)
            if length(yError) == 1; yError = ones(length(this.yVals), 1) * yError; end
            this.data(:,4) = yError; end
    end
    
    methods (Access = public)
        %% Constructor
        function this = ChiPlotter(xVals, xErr, yVals, yErr)
            if nargin == 0; return; end
            [this.xVals, this.xError, this.yVals, this.yError] = ...
                deal(xVals(:), xErr(:), yVals(:), yErr(:));
        end
        
        %% Evaluates data for best-fit line based on chi-square analysis
        function chiSquareFit(this, include)
            if nargin < 2; include = ones(length(this.xVals),1); end
            this.included = include;
            leftData = this.data((include > 0) .* (this.xVals <= this.centerVal) > 0, :);
            rightData = this.data((include > 0) .* (this.xVals >= this.centerVal) > 0, :);
            
            if ~isempty(leftData)
                this.left = this.ChiSquareFit(leftData(:,1), leftData(:,2), ...
                    leftData(:,3), leftData(:,4), this.dif, this.weightBound);
            end
            if isempty(rightData); this.right = this.left;
            else; this.right = this.ChiSquareFit(rightData(:,1), rightData(:,2), ...
                    rightData(:,3), rightData(:,4), this.dif, this.weightBound);
            end
            if isempty(leftData); this.left = this.right; end
        end

        %% Transforms data graphically; only vertical translation and dilation are fully implemented
        function transform(this, direction, transType, factor)
            direction = lower(direction) + "";
            transType = lower(transType) + "";
            
            switch transType
                case "translation"
                    if direction == "horizontal"
                        this.xVals = this.xVals + factor;
                        this.left.intercept = this.left.intercept - factor * this.left.slope; 
                        this.right.intercept = this.right.intercept - factor * this.right.slope; 
                    else
                        this.yVals = this.yVals + factor;
                        this.left.intercept = this.left.intercept + factor; 
                        this.right.intercept = this.right.intercept + factor; 
                    end
                case "dilation"
                    if direction == "horizontal"
                        this.xVals = this.xVals * factor;
                        this.xError = this.xError * factor;
                    else
                        this.yVals = this.yVals * factor;
                        this.yError = this.yError * factor;
                        a = this.left;
                        this.left = struct('R', a.R, 'slope', a.slope * factor, 'intercept', a.intercept * factor, ...
                            'chiSquare', a.chiSquare, 'redChiSquare', a.redChiSquare, 'slopeError', a.slopeError * factor, ...
                            'interceptError', a.interceptError * factor, 'normalSlope', a.normalSlope * factor, ...
                            'normalIntercept', a.normalIntercept * factor);
                        a = this.right;
                        this.right = struct('R', a.R, 'slope', a.slope * factor, 'intercept', a.intercept * factor, ...
                            'chiSquare', a.chiSquare, 'redChiSquare', a.redChiSquare, 'slopeError', a.slopeError * factor, ...
                            'interceptError', a.interceptError * factor, 'normalSlope', a.normalSlope * factor, ...
                            'normalIntercept', a.normalIntercept * factor);
                    end
                case "log"
                    if direction == "horizontal"
                        this.xError = (log(this.xVals + this.xError) + log(this.xVals - this.xError))/2 - log(this.xVals);
                        this.xVals = log(this.xVals);
                    else
                        this.yError = (log(this.yVals + this.yError) + log(this.yVals - this.yError))/2 - log(this.yVals);
                        this.yVals = log(this.yVals);
                    end
            end
        end
        
        %% Returns the center value
        %  if useTrendlines is true or no data exists at the center xVal, returns a value using trendlines
        function center = getCenter(this, useTrendlines)
            centerVals = [];
            if nargin < 2 || ~useTrendlines; centerVals = this.yVals(this.xVals == this.centerVal); end
            if isempty(centerVals); center = this.evaluate(this.centerVal);
            else; center = mean(centerVals); end
        end
        
        %% Evaluates trendlines to return y value
        function yVal = evaluate(this, xVal, side)
            if nargin < 3; side = "none"; else; side = lower(side + ""); end
            if side == "left" || (xVal < this.centerVal && side ~= "right")
                yVal = this.left.slope * xVal + this.left.intercept;
            elseif side == "right" || xVal > this.centerVal
                yVal = this.right.slope * xVal + this.right.intercept;
            else
                yVal = (this.left.slope * xVal + this.left.intercept + ...
                    this.right.slope * xVal + this.right.intercept)/2;
            end
        end
        
        %% Plots data points with error bars
        function plotSeries(this, plotStyle, errorBars, axes)
            if nargin < 2; plotStyle = this.defaultPlotStyle; end
            if nargin < 3; errorBars = this.defaultErrorBars; end
            if nargin < 4; axes = gca; end
            
            hJitter = (rand*2 - 1) * errorBars.horizJitter;
            vJitter = (rand*2 - 1) * errorBars.vertJitter;
            for index = 1:length(this.xVals)
                x = this.xVals(index);
                y = this.yVals(index);
                xE = this.xError(index) * errorBars.showXBars;
                yE = this.yError(index) * errorBars.showYBars;

                plot(axes, [x-xE  x+xE], [y+vJitter  y+vJitter], 'Color', this.color, 'LineWidth', errorBars.width, 'LineStyle', errorBars.style);
                plot(axes, [x+hJitter  x+hJitter], [y-yE  y+yE], 'Color', this.color, 'LineWidth', errorBars.width, 'LineStyle', errorBars.style);
            end
            this.series = scatter(this.xVals(this.included > 0), this.yVals(this.included > 0), plotStyle.dotSize, this.color, 'filled');
            scatter(this.xVals(this.included == 0), this.yVals(this.included == 0), plotStyle.dotSize + 2, this.color);
        end
        
        %%
        function plotTrendlines(this, plotStyle, axes, bounds)
            if nargin < 2; plotStyle = this.defaultPlotStyle; end
            if nargin < 3; axes = gca; end
            if nargin < 4; bounds = [min(this.xVals), max(this.xVals)]; end
            
            if bounds(1) < this.centerVal
                x = [bounds(1)   min(bounds(2), this.centerVal)];
                y = [this.evaluate(x(1), "left")   this.evaluate(x(2), "left")];
                this.left.line = plot(axes, x, y, 'Color', this.color, ...
                    'LineWidth', plotStyle.LineWidth, 'LineStyle', plotStyle.LineStyle);
                this.left.label = sprintf("y = %.3f x + %.3f \n X^2 = %.3f", ...
                    this.left.slope, this.left.intercept, this.left.redChiSquare);
            end
            if bounds(2) <= this.centerVal
                this.right.line = this.left.line;
                this.right.label = this.left.label;
            else
                x = [max(bounds(1), this.centerVal)   bounds(2)];
                y = [this.evaluate(x(1), "right")   this.evaluate(x(2), "right")];
                this.right.line = plot(axes, x, y, 'Color', this.color, ...
                    'LineWidth', plotStyle.LineWidth, 'LineStyle', plotStyle.LineStyle);
                this.right.label = sprintf("y = %.3f x + %.3f \n X^2 = %.3f", ...
                    this.right.slope, this.right.intercept, this.right.redChiSquare);
            end
            if bounds(1) >= this.centerVal
                this.left.line = this.right.line;
                this.left.label = this.right.label;
            end
        end
        
        function plotter = copy(this)
            plotter = ChiPlotter();
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
            
            R = corrcoef(xVals, yVals);
            if length(R) > 1; R = R(1, 2); end
            lineFit = polyfit(xVals, yVals, 1);
            [normalSlope, normalIntercept] = deal(lineFit(1), lineFit(2));

            weights = (1 ./ (yErr + weightBound)) .^2;
            chiSquareFormula = @(equation) sum(weights .* (yVals - (equation(1) * xVals + equation(2))) .^2);
            ms = MultiStart;
            %lowerBounds = [normalSlope - 100*sqrt(abs(normalSlope))   normalIntercept - 1000];
            %upperBounds = [normalSlope + 100*sqrt(abs(normalSlope))   normalIntercept + 1000];
            lowerBounds = [0   normalIntercept - 1000];
            upperBounds = [0   normalIntercept + 1000];
            problem = createOptimProblem('fmincon', 'x0', [normalSlope, normalIntercept], ...
                'objective', chiSquareFormula, 'lb' , [-150, 200], 'ub', [150 1000]);
            warning("off"); chiFit = run(ms, problem, 25); warning("on");
            [slope, intercept] = deal(chiFit(1), chiFit(2));
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
            
            fit = struct('R', R, 'slope', slope, 'intercept', intercept, 'chiSquare', chiSquare, ...
                'redChiSquare', redChiSquare, 'slopeError', slopeError, 'interceptError', interceptError, ...
                'normalSlope', normalSlope, 'normalIntercept', normalIntercept);
        end
    end
end