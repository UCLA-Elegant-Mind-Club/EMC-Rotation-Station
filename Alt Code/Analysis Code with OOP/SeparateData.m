folder = struct();
folder.path = "C:\Users\emban\Documents\Elegant Mind Research\NewData";
folder.subpath = "Final Pitch Data";
folder.dirInfo = dir(fullfile(folder.path, folder.subpath, "*.csv"));
numFiles = length(folder.dirInfo);

for fileNum = 1:numFiles
    warning("off");
    mkdir(fullfile(folder.path + "New", folder.subpath));
    fileName = folder.dirInfo(fileNum).name;
    reader = Reader(fullfile(folder.path, folder.subpath, fileName), 2, 3, 4, 5, 1);
    reader.applyFilter();
    %{
    %Roll (216 trials)  
    filter = cat(1, zeros(12, 1), ones(6, 1), zeros(0, 1));
    filter = repmat(filter, 12, 1);
    %}
    %{
    %Pitch and Yaw (210 trials)
    filter = cat(1, zeros(8, 1), ones(4, 1), zeros(0, 1));
    filter = repmat(filter, 8, 1);
    middleFilter = cat(1, zeros(12,1), ones(6,1), zeros(0,1));
    filter = cat(1, filter, middleFilter, filter);
    %}
    try
        reader.addFilter(filter);
        reader.applyFilter();
        reader.writeData(fullfile( fullfile(folder.path + "New", folder.subpath, fileName)));
    catch
        disp(fileName + " is improperly formatted.");
    end
    warning("on");
end