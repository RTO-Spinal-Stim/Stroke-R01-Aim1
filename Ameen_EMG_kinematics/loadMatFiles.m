function allData = loadMatFiles(folderStruct)
%     % List all MAT files in the folder
%     matFiles = dir(fullfile(folderStruct, '*.mat'));
    
    % Get the field names (structs) within folderStruct
      allStructs = fieldnames(folderStruct);

%     % Initialize a struct array to store the data from each file
    allData = struct();

    % Loop through each MAT file and load data
    for structIndex = 1:length(allStructs)
%         matFileName = matFiles(structIndex).name;
% 
%         % Load the MAT file
%         data = load(fullfile(folderStruct, matFileName));

        % Load Data
        data = folderStruct.(allStructs{structIndex});

        % Extract muscle names from the loaded data
        muscle = strrep(cellstr(data.titles), '''', '');
        muscle = muscle(1:10);

        % Create a struct for the current file
        current = struct();

        % Loop through muscles and extract data for each
        for i = 1:length(muscle)
            start = data.datastart(i);
            endData = data.dataend(i);
            if start ~= -1
                current.(muscle{i}) = data.data(start:endData);
            end
        end

        % Store the current struct in the allData struct array
        allData.(allStructs{structIndex}) = current; % Remove the '.mat' extension from the file name
    end
end
