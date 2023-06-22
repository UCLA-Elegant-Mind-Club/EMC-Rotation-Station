%%% fig = slopeInterceptPlot(plotters, ChiPlotter.defaultPlotStyle, ChiPlotter.defaultErrorBars);
function figHandler = slopeInterceptPlot(plotters, plotStyle, errorBars)
    figHandler = FigureHandler.new();
    xlabel('Intercept (degrees)', 'FontSize', 12.5);
    ylabel('Slope (ms/degrees)');
    title('Slope vs. Intercept for Yaw Faces Protocol with Crossmark Cue');
    grid on;

    left = [plotters.left]; 
    slopes = [left.slope];
    slopeError = [left.slopeError];
    intercepts = [left.intercept];
    interceptError = [left.interceptError];
    leftPlotter = ChiPlotter(intercepts, interceptError, slopes, slopeError);
    leftPlotter.chiSquareFit();
    leftPlotter.color = "blue";
    leftPlotter.label = "Left Trendlines";
    leftPlotter.plotSeries(plotStyle, errorBars);
    leftPlotter.plotTrendlines(plotStyle, gca, [0 1000]);
    leftLabel = sprintf("Left Trendlines: \n" + leftPlotter.right.label);
    
    right = [plotters.right];
    slopes = [right.slope];
    slopeError = [right.slopeError];
    intercepts = [right.intercept];
    interceptError = [right.interceptError];
    rightPlotter = ChiPlotter(intercepts, interceptError, slopes, slopeError);
    rightPlotter.chiSquareFit();
    rightPlotter.color = "red";
    rightPlotter.label = "Right Trendlines";
    rightPlotter.plotSeries(plotStyle, errorBars);
    rightPlotter.plotTrendlines(plotStyle, gca, [0 1000]);
    rightLabel = sprintf("Right Trendlines: \n" + rightPlotter.right.label);
    
    yDif = max(-rightPlotter.evaluate(0), leftPlotter.evaluate(0));
    figHandler = FigureHandler(0,1000,-yDif,yDif,figHandler);
    figHandler.bounds = 0;
    figHandler.zoom(1,0.9);
    figHandler.darkenAxes;
    figHandler.frame;
    
    legend([leftPlotter.right.line rightPlotter.right.line], [leftLabel rightLabel], ...
        'Location','Northeastoutside', 'FontSize', 10)
end