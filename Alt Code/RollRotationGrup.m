%{ Caominh was here. He made some cool stuff. }%
%% Experiment Input Values
centerValueIndex = 7;
rotationValues = [-90, -75, -60, -45, -30, -15, 0, 15, 30, 45, 60, 75, 90];    %%% Will need to wrap 180 to -180 later
numRotationValues = length(rotationValues);

%{ Johnathan was here. He was an awesome leader. }%
%% Get File Info List from Folders
folder = struct();
folder.path = "C:\Users\emban\OneDrive\Desktop\Elegant Mind Research\Data\yaw1";
folder.dirInfo = dir(fullfile(folder.path,'*.csv'));
numParticipants = length(folder.dirInfo);

numTrials1 = zeros(numRotationValues,numParticipants);
averages1 = numTrials1;
stdErrors1 = numTrials1;

%{ Darren was here. He guided us on our journey. }%
%% Customize Plot Appearance
figure();
set(gca, 'FontSize', 12.5);
hold on;

xlabel('Roll Rotation (degrees)', 'FontSize', 12.5);
ylabel('Relative Reaction Time Shift (%)', 'FontSize', 12.5);
title('Relative Reaction Time Shifts for Roll Rotation with Crossmark Cue');

%%% Set axisBounds to a 4 element vector to set bounds directly. Otherwise set to a constant < 1.
%%% Bounds will be determined by adding a fraction of the data range to the max and min values.
%%% For example, axisBounds = 0 will have data points at the edges of the graph

%%%axisBounds = [-190, 190, -100, 100];
axisBounds = 0.1;
axis square;
grid on;

errorBars = struct();
errorBars.yColor = [0 0.4 0.8]; % navy blue
errorBars.xColor = [0.35 0.35 0.35]; % grey

individualStyle = struct();
individualStyle.dotSize = 10;
individualStyle.lineWidth = 0.5;
individualStyle.lineStyle = "--";
individualStyle.colors = [[1 0 0]; [0 1 0]; [0 0 1]; [1 1 0]; [0 1 1]; [1 0 1]; ...
    [1 0.5 0]; [0 1 0.5]; [0.5 0 1]; [0.5 1 0]; [0 0.5 1]; [1 0 0.5]];

aggregateStyle = struct();
aggregateStyle.dotSize = 20;
aggregateStyle.lineWidth = 1;
aggregateStyle.lineStyle = "-";
aggregateStyle.color = [0 0 0]; %black

%{ Hind was here. She made excellent presentations. }%
%% Structs to group data and keep final workspace clean
rawData = struct();     %%% Unsorted raw data vectors
temp = struct();        %%% Temporary variabes for indeces and iteration values
graph = struct();       %%% Temporary variables for plotting
leftTrend = struct();   %%% Temporary variables for calculating left trendline parameters
rightTrend = struct();  %%% Temporary variables for calculating right trendline parameters

%% Read and Process Data and Plot
for participantNum = 1:numParticipants
    if participantNum <= 12
        graph.color = individualStyle.colors(participantNum, 1:3);
    else
        graph.color = [rand, rand, rand];
    end
    rawData.table = readtable(fullfile(folder.path,folder.dirInfo(participantNum).name));
    %{
    if size(table,2) == 5
        table(:,3) = table(:,5);
    end
    %}

    %{ Emma was here. She was a great scientist. }%
    %% Convert Data and Remove Mistakes
    rawData.angles = table2array(rawData.table(:,2));
    rawData.times = table2array(rawData.table(:,3));
    rawData.matrix = cat(2,rawData.angles, rawData.times);

    rawData.wasCorrect = table2array(rawData.table(:,1));
    sortedData = sortrows(rawData.matrix(rawData.wasCorrect > 0,:), [1, 2]);
    temp.len = length(sortedData);
    temp.endIndex = 1;

    for rotationIndex = 1:numRotationValues
        %% Efficiently get subarray by iterating through sorted data instead of looping through entire array
        temp.rotation = rotationValues(rotationIndex);
        temp.startIndex = temp.endIndex;
        while temp.endIndex < temp.len && sortedData(temp.endIndex,1) == temp.rotation
            temp.endIndex = temp.endIndex + 1;
        end
        filtered = sortedData(temp.startIndex:temp.endIndex,2);

        %% Remove outliers, can later implement IQR analysis
        processed = rmoutliers(filtered);

        %% Process data
        numTrials1(rotationIndex, participantNum) = length(processed);
        averages1(rotationIndex, participantNum) = mean(processed);
        stdErrors1(rotationIndex, participantNum) = std(processed)/length(processed);
    end

    %{ Anushka was here. Her skills have helped us achieve greatness. }%
    %% Wrap data around
    %{
    numTrials1(1, participantNum) = numTrials1(numRotationValues, participantNum);
    averages1(1, participantNum) = averages1(numRotationValues, participantNum);
    stdErrors1(1, participantNum) = stdErrors1(numRotationValues, participantNum);
    %}
    
    %% Calculate Trendline and plot data
    leftTrend.fit = polyfit(rotationValues(1:centerValueIndex), averages1(1:centerValueIndex, participantNum), 1);
    rightTrend.fit = polyfit(rotationValues(centerValueIndex:end), averages1(centerValueIndex:end, participantNum), 1);
    graph.averageIntercept = (leftTrend.fit(2) + rightTrend.fit(2))/2;
    
    %{ Johnny was here. He's helped me the most. }%
    %% Change translation and dilation to alter how data is shown (default should be 0 and 1)
    %%% Some numbers to use are averages1(centerValueIndex, participantNum)
    %%% or graph.averageIntercept (Brian does not recommended the latter).
    graph.translation = -averages1(centerValueIndex, participantNum) * 0;
    graph.dilation = 1/1;
    
    averages1(:, participantNum) = averages1(:, participantNum) * graph.dilation + graph.translation;
    stdErrors1(:, participantNum) = stdErrors1(:, participantNum) * graph.dilation;
    leftTrend.fit = leftTrend.fit * graph.dilation + [0, graph.translation];
    rightTrend.fit = rightTrend.fit * graph.dilation + [0, graph.translation];
    
    %%% polyfit(1) == slope; polyfit(2) == intercept
    leftTrend.equation = leftTrend.fit(1) * rotationValues(1:centerValueIndex) + leftTrend.fit(2);
    plot(rotationValues(1:centerValueIndex), leftTrend.equation, 'Color', graph.color, 'LineWidth', ...
        individualStyle.lineWidth, 'LineStyle', individualStyle.lineStyle);
    rightTrend.equation = rightTrend.fit(1) * rotationValues(centerValueIndex:end) + rightTrend.fit(2);
    plot(rotationValues(centerValueIndex:end), rightTrend.equation, 'Color', graph.color, 'LineWidth', ...
        individualStyle.lineWidth, 'LineStyle', individualStyle.lineStyle);
    
    %{ Caominh was here again. His name is pronounced 'kow-min' but he's cool with anything. }%
    %% Draw Error Bars (comment out to remove error bars for individual data)
    %%% Change jitter 0 to remove from error bars (points don't have jitter)
    errorBars.xJitter = (rand - 0.5) * 5;
    for rotationIndex = 1:numRotationValues
        errorBars.xValue = rotationValues(rotationIndex) + errorBars.xJitter;
        errorBars.yValue = averages1(rotationIndex, participantNum);
        
        %{
        errorBars.xError = xerr(rotationIndex);
        plot([errorBars.xValue - errorBars.xError errorBars.xValue + errorBars.xError], ...
            [errorBars.yValue errorBars.yValue], 'Color', errorBars.xColor);
        %}
        %{%}
        errorBars.yError = stdErrors1(rotationIndex);
        plot([errorBars.xValue errorBars.xValue], [(errorBars.yValue - errorBars.yError) ...
            (errorBars.yValue + errorBars.yError)], 'Color', errorBars.yColor);
        %}
    end
    scatter(rotationValues, averages1(:, participantNum), individualStyle.dotSize, graph.color, 'filled');
end

%{ Samantha was here. She has unlimited potential. }%
%% Calculate Aggregate Data
totalTrials = sum(numTrials1, 2);
totals = sum(averages1 .* numTrials1, 2);
totalErrors = std(averages1, [], 2) ./ sqrt(totalTrials);
ymin = min(averages1, [], 'all');
ymax = max(averages1, [], 'all');

aggregateTimes = totals ./ totalTrials;
aggregateErrors = totalErrors;      %%% Code may change if better way to sum variation in each data point

%{ Annika was here. She brought out the best in us. }%
%% Aggregate Trendline
leftTrend.fit = polyfit(rotationValues(1:centerValueIndex), aggregateTimes(1:centerValueIndex), 1);
rightTrend.fit = polyfit(rotationValues(centerValueIndex:end), aggregateTimes(centerValueIndex:end), 1);

%%% polyfit(1) == slope; polyfit(2) == intercept
leftTrend.equation = leftTrend.fit(1) * rotationValues(1:centerValueIndex) + leftTrend.fit(2);
leftTrend.line = plot(rotationValues(1:centerValueIndex), leftTrend.equation, 'Color', aggregateStyle.color, ...
    'LineWidth', aggregateStyle.lineWidth, 'LineStyle', aggregateStyle.lineStyle);
rightTrend.equation = rightTrend.fit(1) * rotationValues(centerValueIndex:end) + rightTrend.fit(2);
rightTrend.line = plot(rotationValues(centerValueIndex:end), rightTrend.equation, 'Color', aggregateStyle.color, ...
    'LineWidth', aggregateStyle.lineWidth, 'LineStyle', aggregateStyle.lineStyle);

%{ Brian was always here. Thank you for all your help. }%
%% Aggregate Error Bars
for rotationIndex = 1:numRotationValues
    errorBars.xValue = rotationValues(rotationIndex);
    errorBars.yValue = aggregateTimes(rotationIndex);
    %{
    errorBars.xError = xerr(rotationIndex);
    plot([errorBars.xValue - errorBars.xError errorBars.xValue + errorBars.xError], ...
        [errorBars.yValue errorBars.yValue], 'Color', errorBars.xColor);
    %}
    %{%}
    errorBars.yError = aggregateErrors(rotationIndex);
    plot([errorBars.xValue errorBars.xValue], [(errorBars.yValue - errorBars.yError) ...
        (errorBars.yValue + errorBars.yError)], 'Color', errorBars.yColor);
    %}
end
scatter(rotationValues, aggregateTimes, aggregateStyle.dotSize, aggregateStyle.color, 'filled');

%{ Arisaka was here first. He knows everything. Everything. %}
%% Set Graph bounds and Darken central axes
if(length(axisBounds) ~= 4)
    range = ymax - ymin;
    axisBounds = [-190 190 (ymin-range*axisBounds) (ymax+range*axisBounds)];
end
axis(axisBounds);
%{}
plot([-10000 10000], [0 0], 'Color', [0 0 0], 'LineWidth', 0.1);
plot([0 0], [-10000 10000], 'Color', [0 0 0], 'LineWidth', 0.1);
%}

%% Legend for Aggregate Data
leftTrend.R = corrcoef(rotationValues(1:centerValueIndex), aggregateTimes(1:centerValueIndex));
leftTrend.R2 = leftTrend.R(2,1)^2;
leftTrend.label = sprintf('y = %.3f x + %.3f \n R^2 = %.3f\n', leftTrend.fit(1), leftTrend.fit(2), leftTrend.R2);

rightTrend.R = corrcoef(rotationValues(centerValueIndex:end), aggregateTimes(centerValueIndex:end));
rightTrend.R2 = rightTrend.R(2,1)^2;
rightTrend.label = sprintf('y = %.3f x + %.3f \n R^2 = %.3f\n', rightTrend.fit(1), rightTrend.fit(2), rightTrend.R2);
legend([leftTrend.line, rightTrend.line],[leftTrend.label, rightTrend.label], 'Location','Northeastoutside', 'FontSize', 10);

%{ cm600286 was here. Or was she? }%