L = -100:10:100;
R = L;
nRows = length(L) * length(R);

%% Equation 1: 2|R-L|/(R+L)
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;
                       
        tbl.Sym(row) = (2*abs(r - l)) / (r + l);                
    end
end

h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
title(h, 'Current Symmetry Equation');
colormap(turbo);

%% Equation 2: (R-L)/(L+R)
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;
                       
        % tbl.Sym(row) = abs((r - l) / (r + l));
        tbl.Sym(row) = (r - l) / (r + l);
    end
end

h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
title(h, 'Alternative Symmetry Equation');
colormap(turbo);

%% Equation 3: 1-abs(1-L/R)
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;
                       
        tbl.Sym(row) = 100*(1-abs(1-l/r));
    end
end

h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
title(h, 'Grant Symmetry Equation');
colormap(turbo);

%% Equation 4: -1*(|R-L|/(R+L)) + 1
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;
                       
        tbl.Sym(row) = -1*((abs(r - l)) / (r + l)) + 1;
    end
end

h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
title(h, 'Modified Current Symmetry Equation');
colormap(turbo);