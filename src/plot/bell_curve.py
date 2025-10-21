import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import norm

def plot_bell_curves(means, std_devs, x_range=None, filename='bell_curves.pdf'):
    """
    Generate and plot multiple bell curves (normal distributions).
    
    Parameters:
    - means: Dictionary with labels as keys and mean values as values
    - std_devs: Dictionary with labels as keys and std dev values as values
    - x_range: Tuple of (min, max) for x-axis. If None, auto-calculated
    - filename: Name of the PDF file to save (default: 'bell_curves.pdf')
    
    Example:
        means = {'Group A': 0, 'Group B': 2}
        std_devs = {'Group A': 1, 'Group B': 1.5}
        plot_bell_curves(means, std_devs)
    """
    # Validate that both dicts have the same keys
    if set(means.keys()) != set(std_devs.keys()):
        raise ValueError("means and std_devs must have the same keys")
    
    # Calculate x range if not provided
    if x_range is None:
        all_means = list(means.values())
        all_stds = list(std_devs.values())
        x_min = min(all_means) - 4 * max(all_stds)
        x_max = max(all_means) + 4 * max(all_stds)
    else:
        x_min, x_max = x_range
    
    # Generate x values
    x = np.linspace(x_min, x_max, 1000)
    
    # Create the plot
    plt.figure(figsize=(12, 7))
    
    # Color palette for different curves
    colors = plt.cm.Set2(np.linspace(0, 1, len(means)))
    
    # Plot each bell curve
    for idx, (label, mean) in enumerate(means.items()):
        std_dev = std_devs[label]
        y = norm.pdf(x, mean, std_dev)
        
        # Plot the curve
        plt.plot(x, y, linewidth=2.5, label=f'{label} (μ={mean}, σ={std_dev})', 
                color=colors[idx])
        
        # Fill area under the curve with transparency
        plt.fill_between(x, y, alpha=0.2, color=colors[idx])
        
        # Add vertical line at mean
        plt.axvline(mean, color=colors[idx], linestyle='--', 
                   linewidth=1.5, alpha=0.7)
    
    # Labels and title
    plt.xlabel('x', fontsize=13)
    plt.ylabel('Probability Density', fontsize=13)
    plt.title('Normal Distribution Comparison', fontsize=15, fontweight='bold')
    plt.legend(fontsize=11, loc='best', framealpha=0.9)
    plt.grid(True, alpha=0.3)
    
    # Display the plot
    plt.tight_layout()
    
    # Save as PDF
    plt.savefig(filename, format='pdf', bbox_inches='tight', dpi=300)
    print(f"Plot saved as '{filename}'")
    
    plt.show()

# Example usage
if __name__ == "__main__":
    # Example 1: Multiple distributions
    means = {
        'Group A': 0,
        'Group B': 3,
        'Group C': -2
    }
    std_devs = {
        'Group A': 1,
        'Group B': 1.5,
        'Group C': 0.8
    }
    plot_bell_curves(means, std_devs, filename='multiple_distributions.pdf')
    
    # Example 2: Comparing test scores
    # means = {
    #     'Class 1': 75,
    #     'Class 2': 82,
    #     'Class 3': 70
    # }
    # std_devs = {
    #     'Class 1': 10,
    #     'Class 2': 8,
    #     'Class 3': 12
    # }
    # plot_bell_curves(means, std_devs, x_range=(40, 110), 
    #                  filename='test_scores.pdf')