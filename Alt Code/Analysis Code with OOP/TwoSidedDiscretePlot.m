switch questdlg("New data?") + ""
    case "Yes"; newData = true;
    case "No"; newData = false;
    otherwise; return;
end
switch questdlg("New figure?") + ""
    case "Yes"; fig = FigureHandler.new();
        fig.frame();
        spacer = "                                ";
        title(spacer + "RT vs. Roll Rotation for Chinese Characters with Crossmark Cue [n = 1]", 'FontSize', 14);
        subtitle("Internal Participants from other groups (10/28)");
        ylabel("Reaction Time (ms)", 'FontSize', 14);
        xlabel("Roll Rotation (degrees)", 'FontSize', 14);
        grid on;
    case "No"; figure(fig.figure);
    otherwise; return;
end
showIndividual = false;
showCousineau = true;

%% Get File Info List from Folders
protocolNum = 1;
protocols(1) = struct('name', "1 Face Roll RT", 'aggregateColor', "Blue", ...
    'readXValues', [-150, -120, -90, -60, -30, 0, 30, 60, 90, 120, 150, 180]);
protocols(2) = struct('name', "2 Yaw", 'aggregateColor', "Red", ...
    'readXValues', [-90, -75, -60, -45, -30, -15, 0, 15, 30, 45, 60, 75, 90]);
protocols(3) = struct('name', "3 Pitch", 'aggregateColor', "Magenta", ...
    'readXValues', [-60, -52.5, -45, -37.5, -30, -22.5, -15, -7.5, 0, 7.5, 15, 22.5, 30, 37.5, 45, 52.5, 60]);
protocols(4) = struct('name', "4 English", 'aggregateColor', "Blue", ...
    'readXValues', [-150, -120, -90, -60, -30, 0, 30, 60, 90, 120, 150, 180]);
protocols(5) = struct('name', "5 Thai", 'aggregateColor', "Red", ...
    'readXValues', [-150, -120, -90, -60, -30, 0, 30, 60, 90, 120, 150, 180]);
protocols(6) = struct('name', "6 Chinese Roll RT", 'aggregateColor', "Magenta", ...
    'readXValues', [-150, -120, -90, -60, -30, 0, 30, 60, 90, 120, 150, 180]);
folder = struct();
folder.path = fullfile("C:\Users\emban\Documents\Elegant Mind Research\Rotation Analysis\Aggregate with Mockups\Combined", ...
    protocols(protocolNum).name);
folder.dirInfo = dir(fullfile(folder.path,'*.csv'));
numFiles = length(folder.dirInfo);

%% Experiment Input Values
numReadVals = length(protocols(protocolNum).readXValues);
xValues = [-180, protocols(protocolNum).readXValues];
wrapIndeces = [numReadVals, 1:numReadVals];
numXValues = length(xValues);
centerVal = 0;
mistakeThreshold = 4;

%% Customize Data Points                                                            %** Step 04 **%
%%% errorBars(1) is for individual data. errorBars(2) is for aggregate
errorBars = struct('horizJitter', 0, 'showYBars', true, 'vertJitter', 0, 'showXBars', false, 'width', 0.5, 'style', '--');
errorBars(2) = struct('horizJitter', 0, 'showYBars', true, 'vertJitter', 0, 'showXBars', false, 'width', 1, 'style', '-');

%%% plotStlye(1) is for individual data. plotStlye(2) is for aggregate
plotStyle = struct('dotSize', 10, 'LineWidth', 1, 'LineStyle', '--');
plotStyle(2) = struct('dotSize', 20, 'LineWidth', 2, 'LineStyle', '-');

%colors = ChiPlotter.startingColors;
colors = [];

%% Data storage initialization
if newData
    [numTrials, averages, stdErrors] = deal(zeros(numXValues,numFiles));
    clearvars plotters newPlots;
    plotters(numFiles) = ChiPlotter();
    newPlots(numFiles) = ChiPlotter();
end

%% Process Individual Data and Trendlines of new Data
for fileNum = (numFiles * ~newData +1):numFiles
    fileName = folder.dirInfo(fileNum).name;
    reader = Reader(fullfile(folder.path, fileName), 2, 3, 4, 3, 1);
    %reader.filter(faces == 1);
    reader.process(protocols(protocolNum).readXValues, 'quartiles');
    reader.transfer(xValues, wrapIndeces);
    
    numTrials(:, fileNum) = reader.numTrials;
    
    plotters(fileNum) = ChiPlotter(reader.xVals, 0, reader.averages, reader.stdErrors);
    plotters(fileNum).label = replace(extractBetween(fileName + "" ,1,4), "_", "-");
    plotters(fileNum).centerVal = centerVal;
    plotters(fileNum).chiSquareFit(reader.numMistakes <= mistakeThreshold);
end

%% Transform trendline and data by translation and dilation and plot
for plotNum = 1:numFiles
    if(plotNum > length(colors)); color = [rand, rand, rand];
    else
        color = colors(plotNum, :);
        %color = protocols(protocolNum).aggregateColor;
    end
    folder.dirInfo(plotNum).color = color;

    plotter = plotters(plotNum).copy();
    newPlots(plotNum) = plotter;
    center = plotter.getCenter(true);
    %plotter.transform("vertical", "translation", -109);
    plotter.color = color;
    if showIndividual
        plotter.plotSeries(plotStyle(1), errorBars(1));
        plotter.plotTrendlines(plotStyle(1));
    end
end

%% Calculate Aggregate Data and Trendline
yVals = [newPlots.yVals];
aggPlotter = AggregatePlotter(xValues, 0, newPlots);
if ~showIndividual && ~showCousineau
    yVals = aggPlotter.yVals;
    aggPlotter.color = protocols(protocolNum).aggregateColor;
else
    aggPlotter.color = "black";
end
ymin = min(yVals, [], 'all');
ymax = max(yVals, [], 'all');

aggPlotter.centerVal = centerVal;
aggPlotter.cousiNorm();

if showCousineau
    for plotter = newPlots
        plotter.plotSeries(plotStyle(1), errorBars(1));
        plotter.plotTrendlines(plotStyle(1)); 
    end
end

aggPlotter.chiSquareFit();
aggPlotter.plotSeries(plotStyle(2), errorBars(2));
aggPlotter.plotTrendlines(plotStyle(2));

%{
aggPlotter = newPlots(1);
fig = FigureHandler(xValues(1), xValues(numXValues), ymin, ymax, fig);
%}

%% Legend
if centerVal <= xValues(1); aggPlotter.left.label = "Left Aggregate: None";
else; aggPlotter.left.label = sprintf("Left Aggregate: \n" + aggPlotter.left.label); end

if centerVal >= xValues(numXValues); aggPlotter.right.label = "Right Aggregate: None";
else; aggPlotter.right.label = sprintf("Right Aggregate: \n" + aggPlotter.right.label); end

indivSeries = [newPlots.series];
if length(indivSeries) < 20; indivLabels = [newPlots.label];
else; indivSeries = []; indivLabels = []; end


lines = [aggPlotter.left.line, aggPlotter.right.line, indivSeries];
labels = [aggPlotter.left.label, aggPlotter.right.label, indivLabels];

legend(lines, labels, 'Location','Northeastoutside', 'FontSize', 10);
fig.addLines(lines(1:2), protocols(protocolNum).name + " " + labels(1:2));
fig.resize([-200 200 300 900]);
fig.darkenAxes();