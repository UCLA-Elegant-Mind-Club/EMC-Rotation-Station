classdef AggregatePlotter < ChiPlotter
    properties
        plotters; sampleSize;
    end
    
    methods (Access = public)
        %% Constructor
        function this = AggregatePlotter(xVals, xError, plots)
            this.plotters = plots;
            this.xVals = xVals;
            this.xError = xError;
            this.sampleSize = sum([plots.included], 2);
            this.calcYVars();
        end
        
        function cousiNorm(this)
            aggMean = mean(this.yVals);
            for plot = this.plotters
                weights = 1 ./ plot.yError;
                %indivMean = sum(plot.yVals .* weights) / sum(weights);
                indivMean = mean(plot.yVals);
                plot.transform("vertical","translation", aggMean - indivMean);
            end
            this.calcYVars();
        end
    end
    
    methods (Access = private)
        function calcYVars(this)
            temp = [this.plotters.yVals];
            included = [this.plotters.included] * 1;
            weights = included ./ [this.plotters.yError];
            this.yVals = sum(temp .* weights, 2) ./ sum(weights, 2);
            for index = 1:length(this.xVals)
                temp(index, 1) = std(temp(index, :), weights(index, :)) / sqrt(this.sampleSize(index));
            end
            this.yError = temp(:,1);
        end
    end
end