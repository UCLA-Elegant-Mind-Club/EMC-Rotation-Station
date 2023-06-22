% plotData(x, y, y2, ChiPlotter.defaultPlotStyle, ChiPlotter.defaultErrorBars)
function plotData(x, y, x2, y2, plotStyle, errorBars)
    hold on;
    
    plot([0 1000], [0 0])
    
    leftPlotter = ChiPlotter(x, 0, y, 0);
    leftPlotter.weightBound = 0.0001;
    leftPlotter.chiSquareFit();
    leftPlotter.color = "blue";
    leftPlotter.label = "Left Trendlines";
    leftPlotter.plotSeries(plotStyle, errorBars);
    leftPlotter.plotTrendlines(plotStyle, gca, [0 1000]);
    leftLabel = sprintf("Left Trendlines: \n" + leftPlotter.right.label);
    
    rightPlotter = ChiPlotter(x2, 0, y2, 0);
    rightPlotter.weightBound = 0.0001;
    rightPlotter.chiSquareFit();
    rightPlotter.color = "red";
    rightPlotter.label = "Right Trendlines";
    rightPlotter.plotSeries(plotStyle, errorBars);
    rightPlotter.plotTrendlines(plotStyle, gca, [0 1000]);  
    rightLabel = sprintf("Right Trendlines: \n" + rightPlotter.right.label);
    
    legend([leftPlotter.right.line rightPlotter.right.line], [leftLabel rightLabel], ...
        'Location','Northeastoutside', 'FontSize', 10)
    
    title("Slopes vs. Intercepts for Chinese Character Roll RT")
    xlabel("Intercept (ms)")
    ylabel("Slope (ms/degree Roll)")
end