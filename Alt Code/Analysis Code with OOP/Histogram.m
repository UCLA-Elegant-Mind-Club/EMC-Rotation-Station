monitorDelay = 139.032

%% Initialize Table
experiments = struct('name', NaN, 'color', NaN, 'fileName', NaN);
prefix = "C:\Users\emban\OneDrive\Desktop\Elegant Mind Research\Data\"

experiments(1).name = "One Character Reflex";
experiments(1).color = '#0072BD';
experiments(1).fileName = prefix + "Test11_06_29_FamChar One Decision Covert.csv";

experiments(2).name = "Two Character Decision";
experiments(2).color = '#D95319';
experiments(2).fileName = prefix + "Test21_06_29_FamChar Two Decision Covert.csv";

experiments(3).name = "Three Character Decision";
experiments(3).color = '[0.6350, 0.0780, 0.1840]';  %%% Can specify each as decimal / 255
experiments(3).fileName = prefix + "Test31_06_29_FamChar Three Decision Covert.csv";
    
%% Initialize Graph
figure();   %%% Creates the window to draw plots on
hold on;    %%% Specifies that plot should not be overdrawn by subsequent data

%% Draw Data on Graph
for ii = 1:length(experiments)
    table = readtable(experiments(ii).fileName);
    rawTimes = table2array(table(:,4));                 %%% 4th column contains reaction times
    times = rmoutliers(rawTimes) * 1000 - monitorDelay; %%% Outdated outlier removal
    
    %%%springf inserts the variable into the string where ver % appears
    %%%4.2 = 4 digits to left of decimal, 2 digits to right
    namelabel = experiments(ii).name;
    mnlabel = sprintf('Mean: %4.2f ms', mean(times));
    stdlabel = sprintf('Std Deviation: %4.2f ms', std(times));
    
    x = 0.8-ii*0.15;
    histogram(times,'FaceColor', experiments(ii).color, 'EdgeColor', 'white', 'BinWidth',20, 'BinLimits', [100,800]);
    n = annotation('textbox',[0.62, x, 0.1, 0.1]);  %%% [x, y, width, height]
    set(n,'String',{namelabel, mnlabel,stdlabel});              %%% Labels will escape box if too many
end

%% Draw Title, Axes Titles, and Legend
title("Reaction Time Distributions for Character Decision Making");
xlabel("Average Reaction Time (ms)");
ylabel("Count");
legend('boxon');
legend({'One Character (E)', 'Two Characters (E/P)', 'Three Characters (E/P/B)'},'EdgeColor','black');