classdef Reader < handle
    properties
        table; data; filter;
        xVals; numTrials; numMistakes; averages; stdErrors;
    end
    
    methods
        %% Constructor
        % @fileName File path to read, should be csv file
        % @xCol Column number to extract x data
        % @yCol Column number to extract y data
        % @expectedWidth Expected number of columns in data
        % @yCol2 Column number to extract y data if table exceeds the expected width
        % @includeCol Column number to extract booleans to include or exclude data
        function this = Reader(fileName, xCol, yCol, expectedWidth, yCol2, includeCol)
            if nargin == 0; return; end
            this.table = readtable(fileName);
            xVals = this.columnData(xCol);
            
            if nargin < 4
                expectedWidth = width(this.table);
                yCol2 = 0;
            end
            
            normalWidth = width(this.table) == expectedWidth;
            yVals = this.columnData(yCol*normalWidth + yCol2*~normalWidth);
            if nargin == 6; this.filter = this.columnData(includeCol);
            else; this.filter = ones(length(xVals),1); end
            
            this.data = cat(2, xVals, yVals);
        end
        
        %% Filters data
        % @include Boolean array where true indicates a value should be kept
        function addFilter(this, include)
            this.filter = this.filter .* (include > 0);
        end
        
        function applyFilter(this)
            this.data = this.data(this.filter > 0, :);
            this.filter = ones(length(this.data),1);
        end

        %% Processes data for number of trials, averages, and standard errors
        % @xValues Array of x values to search for in data
        % @outlierMethod Method to process outliers, 'quartiles' by default
        function process(this, xValues, outlierMethod)
            this.applyFilter();
            this.data = sortrows(this.data, [1 2]);
            this.xVals = xValues;
            if nargin < 3; outlierMethod = 'quartiles'; end
            startIndex = 1;
            numXValues = length(xValues);
            
            [this.numMistakes, this.numTrials, this.averages, this.stdErrors] = deal(zeros(numXValues, 1));
            
            for index = 1:numXValues
                [subset, startIndex, this.numMistakes(index)] = this.nextSubset(xValues(index), startIndex);
                processed = rmoutliers(subset, outlierMethod);
                this.numTrials(index) = length(processed);
                this.averages(index) = mean(processed);
                this.stdErrors(index) = std(processed)/sqrt(length(processed));
            end
        end
        
        %% Transfers data into new table of values
        % @newXVals Array of new x values
        % @sourceIndeces Array of indeces from which rows in the new table will retrieve data
        function transfer(this, newXVals, sourceIndeces)
            len = length(newXVals);
            if nargin < 3 || isempty(sourceIndeces)
                sourceIndeces = 1:len; end
            this.xVals = newXVals;
            [mistakes, trials, avgs, errors] = deal(this.numMistakes, this.numTrials, ...
                this.averages, this.stdErrors);
            [this.numMistakes, this.numTrials, this.averages, this.stdErrors] = deal(zeros(len,1));
            for index = 1:length(sourceIndeces)
                this.numMistakes(index,1) = mistakes(sourceIndeces(index));
                this.numTrials(index,1) = trials(sourceIndeces(index));
                this.averages(index,1) = avgs(sourceIndeces(index));
                this.stdErrors(index,1) = errors(sourceIndeces(index));
            end
        end
        
        %% Gets column data
        % @col Column number
        % @return Column vector containing data in specified column
        function column = columnData(this, col)
            column = table2array(this.table(:,col));
        end
        
        function writeData(this, fileName)
            tabl = array2table(cat(2, this.filter, this.data, this.filter));
            tabl.Properties.VariableNames(1:4) = this.table.Properties.VariableNames(1:4);
            writetable(tabl, fileName);
        end
    end
    
    methods (Access = private)
        %% Get next subset from sorted data
        % @xValue The next x value to scan for in sorted data
        % @startIndex Position in sorted data to begin scanning
        function [sub, newIndex, numExcluded] = nextSubset(this, xValue, startIndex)
            bound = length(this.data);
            while startIndex <= bound && this.data(startIndex, 1) < xValue
                startIndex = startIndex + 1; end
                newIndex = startIndex;
            numExcluded = 0;
            startIndex = newIndex;
            while newIndex <= bound && this.data(newIndex, 1) == xValue
                newIndex = newIndex + 1; end
            sub = this.data(startIndex:newIndex - 1, 2);
        end
    end
end