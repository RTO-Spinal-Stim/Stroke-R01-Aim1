% 1. Define MMT folder(s)
config_path = "Y:\LabMembers\MTillman\GitRepos\Stroke-R01\src\MMT\config_UAE.json";
config = jsondecode(fileread(config_path));
paths_to_add = config.PATHS_TO_ADD;
for i = 1:length(paths_to_add)
    addpath(genpath(paths_to_add{i}));
end
fs = 2000;

if ~isfield(config, 'IGNORE_FILES')
    config.IGNORE_FILES = {};
end

if ~isfield(config, 'RECTIFY')
    config.RECTIFY = 0;
end

if ~isfield(config, 'REMAPPING')
    config.REMAPPING = struct();
end

% 2. For each file:
% - Load the file
% - Plot each muscle individually (with comments as vertical lines)
% - Plot all muscles together on the same plot (with comments as vertical
% lines)
% - Save the plots to a subfolder at the same location
folders = config.FOLDERS;
for folderNum = 1:length(folders)
    folder = folders{folderNum};
    fileList = dir(folder);
    for fileNum = 1:length(fileList)
        fileRow = fileList(fileNum);
        if ~endsWith(fileRow.name, '.mat')
            continue; % Ignore the non-.mat files.
        end
        isIgnored = false;
        for ignoreFileNum = 1:length(config.IGNORE_FILES)
            ignoreFileName = config.IGNORE_FILES{ignoreFileNum};
            if contains(fileRow.name, ignoreFileName)
                isIgnored = true;
            end
        end
        if isIgnored
            continue;
        end
        filePath = fullfile(fileRow.folder, fileRow.name);        
        [figLoaded, figFiltered, loadedData, rawData] = processMMTFile(filePath, config.REMAPPING, config.FILTER, fs, config.RECTIFY);
        disp(filePath);
        disp(rawData.comtext);
        % Prep to save the figures
        saveFolderPath = fullfile(fileRow.folder, 'Plots');
        mkdir(saveFolderPath);
        titleStr = strrep(fileRow.name, '.mat', ''); % Remove the .mat suffix
        titleStr = strrep(titleStr, '_', ' '); % Remove underscores
        % Save the loaded data figure
        figLoaded.WindowState = 'maximized';
        sgtitle(figLoaded, titleStr,'Interpreter','None');
        saveFilePath = fullfile(saveFolderPath, [titleStr ' AllMusclesRaw']);
        saveas(figLoaded, [saveFilePath '.fig']);
        saveas(figLoaded, [saveFilePath '.png']);
        close(figLoaded);
        % Save the filtered figure
        figFiltered.WindowState = 'maximized';
        sgtitle(figFiltered, titleStr,'Interpreter','None');
        saveFilePath = fullfile(saveFolderPath, [titleStr ' AllMusclesFiltered']);
        saveas(figFiltered, [saveFilePath '.fig']);
        saveas(figFiltered, [saveFilePath '.png']);
        close(figFiltered);
    end
end