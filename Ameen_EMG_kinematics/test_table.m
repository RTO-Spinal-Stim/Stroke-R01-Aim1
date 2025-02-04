% Make an empty table
T = table;
% Add a column to the table
T.time = [1; 2; 3];
% Add a column to the table
% T.structs = [struct('a', 1); struct('a', 2); struct('a', 3)];
% Add another column
a = zeros(3, 100);
T.vectors = [a; a; a];

T.vectors(2,:)

% Trying to merge tables that have one shared column.
T1 = table;
T1.C1 = 1;
T1.C2 = 2;

T2 = table;
T2.C1 = 1;
T2.C3 = 2;

T12 = outerjoin(T1, T2, 'Keys', 'C1', 'MergeKeys', true);