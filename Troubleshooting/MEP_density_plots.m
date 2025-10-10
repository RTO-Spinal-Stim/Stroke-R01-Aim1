resultsTableAll = resultsTable; % Copy the data from processTEPsOneFile

resultsTableAll(resultsTableAll.PulseNum <= 67,:) = [];

x = resultsTableAll.lag;
y = resultsTableAll.P2P;

% 2D Kernel Density Estimation for (x,y) data pairs
% Assumes your data is in variables x and y (column vectors)

% Example data generation (replace with your actual data)
% x = your_x_data;  % Replace with your actual x data
% y = your_y_data;  % Replace with your actual y data

% Method 1: Using ksdensity with 2D data
% Combine x and y into a matrix
data = [x(:), y(:)];  % Ensure column vectors and combine

% Define evaluation grid
x_min = min(x); x_max = max(x);
y_min = min(y); y_max = max(y);

% Create grid for evaluation (adjust resolution as needed)
x_grid = linspace(x_min, x_max, 100);
y_grid = linspace(y_min, y_max, 100);
[X_grid, Y_grid] = meshgrid(x_grid, y_grid);

% Reshape grid for ksdensity
eval_points = [X_grid(:), Y_grid(:)];

% Compute 2D kernel density
[density, eval_pts] = ksdensity(data, eval_points);

% Reshape density back to grid
Z = reshape(density, size(X_grid));

% Plot the results
figure;

% Subplot 1: Original scatter plot
subplot(2,2,1);
scatter(x, y, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
xlabel('x (lag)');
ylabel('y (F2F)');
title('Original Data');
grid on;

% Subplot 2: Contour plot of density
subplot(2,2,2);
contour(X_grid, Y_grid, Z, 20);
xlabel('x (lag)');
ylabel('y (F2F)');
title('Density Contours');
colorbar;
grid on;

% Subplot 3: Filled contour plot
subplot(2,2,3);
contourf(X_grid, Y_grid, Z, 20);
xlabel('x (lag)');
ylabel('y (F2F)');
title('Filled Density Contours');
colorbar;

% Subplot 4: 3D surface plot
subplot(2,2,4);
surf(X_grid, Y_grid, Z);
xlabel('x (lag)');
ylabel('y (F2F)');
zlabel('Density');
title('3D Density Surface');
shading interp;
colorbar;

% Alternative: Overlay density contours on scatter plot
figure;
scatter(x, y, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.4);
hold on;
contour(X_grid, Y_grid, Z, 10, 'r', 'LineWidth', 1.5);
xlabel('x (lag)');
ylabel('y (F2F)');
title('Data with Density Contours');
legend('Data Points', 'Density Contours', 'Location', 'best');
grid on;

% Optional: Compute density at original data points
data_density = ksdensity(data, data);

% Create scatter plot colored by density
figure;
scatter(x, y, 30, data_density, 'filled');
xlabel('x (lag)');
ylabel('y (F2F)');
title('Data Points Colored by Local Density');
colorbar;
colormap(jet);

% Print some statistics
fprintf('Data summary:\n');
fprintf('Number of points: %d\n', length(x));
fprintf('X range: [%.2f, %.2f]\n', min(x), max(x));
fprintf('Y range: [%.2f, %.2f]\n', min(y), max(y));
fprintf('Max density: %.6f\n', max(density));

% Optional: Save high-resolution density data
% save('density_results.mat', 'X_grid', 'Y_grid', 'Z', 'density', 'eval_points');