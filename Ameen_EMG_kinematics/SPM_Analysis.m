function [result] = SPM_Analysis(spm_input, fields1, fields2, alphaValue)

%% PURPOSE: RUN SPM ANALYSIS
% Inputs:
% spm_input: struct, where each field is a MxN vector of doubles (M
% repetitions of N timepoints)
% fields1: Cell array of chars, where each char is a field name of
% spm_input (not overlapping with fields2).
% fields2: Cell array of chars, where each char is a field name of
% spm_input (not overlapping with fields1).
%
% SPM will be performed iteratively on each element of fields1 and fields2,
% respectively. Often, fields1 and fields2 are named like {'LHAM'} and
% {'RHAM'}, so that the SPM result will be stored in the field 'HAM'.

% Check that the field name groupings for SPM are the same length
if length(fields1) ~= length(fields2)
    error('SPM comparison field names are not the same length!');
end

% Set a default value for alphaValue
if ~exist('alphaValue','var')
    alphaValue = 0.05;
end

numFields = length(fields1);
result = struct;
for fieldNum = 1:numFields
    field1 = fields1{fieldNum};
    field2 = fields2{fieldNum};
    assert(strcmp(field1(2:end), field2(2:end)));
    field = field1(2:end);
    result.(field) = []; % Initialize the field.

    data1 = spm_input.(field1);
    data2 = spm_input.(field2);

    % Do the SPM analysis.
    spm = spm1d.stats.ttest2(data1, data2);
    spmi = spm.inference(alphaValue, 'two_tailed', true, 'interp', true);

    % Adjust endpoints storage.
    if isempty(spmi.clusters)
        result.(field) = [0 0];
    else
        endpointsTmp = cellfun(@(x) x.endpoints, spmi.clusters, 'UniformOutput', false);
        endpointsTmp = cell2mat(endpointsTmp');
        if isempty(endpointsTmp)
            result.(field) = [0 0];
        else
            result.(field) = reshape(endpointsTmp, [], 2);
        end
        % Round the endpoint indices to whole numbers. Ceiling for start
        % index, floor for end index.
        for endpointNum = 1:size(result.(field),1)
            result.(field)(endpointNum,:) = [ceil(result.(field)(endpointNum,1)), floor(result.(field)(endpointNum,2))];
        end

        % Change range from 0 - (N-1) to 1-N
        result.(field) = result.(field) + 1;
        assert(result.(field)(end,end) <= length(data1)); % Double check that this doesn't give an out of bound index at the upper end.
    end
end