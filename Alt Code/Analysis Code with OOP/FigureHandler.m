classdef FigureHandler < handle
    properties
        minX; maxX; minY; maxY; bounds = 0.1;
        lastHandle = 0; plot; figure = gcf;
        lines = []; labels = []; axLines = [];
    end
    properties (Constant)
        widthAspect = 10;
        heightAspect = 9;
        width = 750;
    end
    methods
        function this = FigureHandler(minX, maxX, minY, maxY, lastHandle)
            if nargin == 5 && isa(lastHandle, 'FigureHandler')
                this.minX = min(minX, lastHandle.minX);
                this.maxX = max(maxX, lastHandle.maxX);
                this.minY = min(minY, lastHandle.minY);
                this.maxY = max(maxY, lastHandle.maxY);
                this.bounds = calcBounds(this);
                this.figure = lastHandle.figure;
                this.figure.handler = this;
                this.lastHandle = lastHandle;
                this.lines = lastHandle.lines;
                this.labels = lastHandle.labels;
                this.axLines = lastHandle.axLines;
            else
                [this.minX, this.maxX, this.minY, this.maxY] = deal(minX, maxX, minY, maxY);
                this.bounds = [minX, maxX, minY, maxY];
                this.lastHandle = this;
                if nargin ==5; this.figure = lastHandle; end
            end
            this.plot = copy(gca(this.figure));
        end
        
        function darkenAxes(this, lineWidth, origin, color)
            if nargin < 2; lineWidth = 0.1; end
            if nargin < 3; origin = [0 0]; end
            if nargin < 4; color = [0 0 0]; end
            figure(this.figure);
            if ~isempty(this.axLines); delete(this.axLines(1)); delete(this.axLines(2)); this.axLines = []; end
            bounds = calcBounds(this);
            if lineWidth > 0
                this.axLines(1) = plot([bounds(1) bounds(2)], [origin(2) origin(2)], 'Color', color, 'LineWidth', lineWidth);
                set(get(get(this.axLines(1), 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
                this.axLines(2) = plot([origin(1) origin(1)], [bounds(3) bounds(4)], 'Color', color, 'LineWidth', lineWidth);
                set(get(get(this.axLines(2), 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
            end
        end
        
        function resize(this, newBounds)
            if nargin == 2; this.bounds = newBounds; end
            figure(this.figure);
            axis(calcBounds(this));
        end
        
        function old = revert(this)
            old = this.lastHandle;
            fNames = fieldnames(this);
            for i = 1:length(fNames)
                try this.(fNames{i}) = old.(fNames{i}); catch; end
            end
            axes = gca;
            fNames = fieldnames(this.plot);
            for i = 1:length(fNames)
                try axes.(fNames{i}) = this.plot.(fNames{i}); catch; end
            end
            axes.Parent = this.figure;
        end
        
        function save(this)
            this.lastHandle = FigureHandler(this.minX, this.maxX, this.minY, this.maxY, this);
        end
        
        function move(this, xShift, yShift)
            b = this.bounds;
            this.bounds = [b(1) + xShift, b(2) + xShift, b(3) + yShift, b(4) + yShift];
        end
        
        function zoom(this, xFactor, yFactor)
            xFactor = xFactor - 1;
            yFactor = yFactor - 1;
            b = calcBounds(this);
            domain = b(2) - b(1);
            range = b(4) - b(3);
            this.bounds = [b(1)+xFactor*domain/2   b(2)-xFactor*domain/2 ...
                b(3)+yFactor*range/2   b(4)-yFactor*range/2];
            this.resize();
        end
        
        function textLabels(~, xLabel, yLabel, mainTitle, subTitle, axesFontSize)
            if nargin < 6; axesFontSize = 12.5; end
            xlabel(xLabel, 'FontSize', axesFontSize);
            ylabel(yLabel, 'FontSize', axesFontSize);
            title(mainTitle + "");
            subtitle(subTitle + "");
        end
        
        function addLines(this, lines, labels)
            this.lines = [this.lines, lines];
            this.labels = [this.labels, labels];
        end
        
        function legend(this, location, fontSize)
            if nargin < 2; location = 'Northeastoutside'; end
            if nargin < 3; fontSize = 10; end
            figure(this.figure);
            legend(this.lines, this.labels, 'Location',location, 'FontSize', fontSize);
        end
        
        function bound = calcBounds(this)
            domain = this.maxX - this.minX; range = this.maxY - this.minY;
            if length(this.bounds) == 1
                bound = [this.minX - domain*this.bounds   this.maxX + domain*this.bounds ...
                    this.minY - range*this.bounds   this.maxY + range*this.bounds];
            elseif length(this.bounds) == 2
                bound = [this.minX + domain/2 - this.bounds(1)/2   this.maxX - domain/2 + this.bounds(1)/2 ...
                    this.minY + range/2 - this.bounds(2)/2   this.maxY - range/2 + this.bounds(2)/2];
            else
                bound = this.bounds;
            end
        end
        
        function frame(this, width)
            if nargin < 2; width = this.width; end
            oldPos = this.figure.Position;
            this.figure.Position(3) = width;
            this.figure.Position(4) = width / FigureHandler.widthAspect * FigureHandler.heightAspect;
            this.figure.Position(2) = oldPos(2) - this.figure.Position(4) + oldPos(4);
        end
    end
    
    methods (Static)
        function clear()
            hold off;
            plot([0 0], [0 0]);
            hold on;
        end
        
        function figHandler = new()
            fig = figure();
            figHandler = FigureHandler(Inf,-Inf,Inf,-Inf,fig);
            fig.addprop('handler');
            fig.handler = figHandler;
            hold on;
        end
        
        function figHandler = current()
            f = gcf;
            figHandler = f.handler;
        end
    end
end