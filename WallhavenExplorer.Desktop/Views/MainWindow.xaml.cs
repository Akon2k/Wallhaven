using System.Windows;
using WallhavenExplorer.Desktop.ViewModels;

namespace WallhavenExplorer.Desktop.Views
{
    public partial class MainWindow : Window
    {
        // AkonDeV 06/2026
        public MainWindow(MainViewModel viewModel)
        {
            InitializeComponent();
            DataContext = viewModel;
        }
    }
}
