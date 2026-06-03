using System.Windows;
using WallhavenExplorer.Desktop.ViewModels;

namespace WallhavenExplorer.Desktop.Views
{
    public partial class SettingsWindow : Window
    {
        // AkonDeV 06/2026
        public SettingsWindow(SettingsViewModel viewModel)
        {
            InitializeComponent();
            DataContext = viewModel;
        }
    }
}
