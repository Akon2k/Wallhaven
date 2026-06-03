using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
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

        private void ImageScrollViewer_MouseWheel(object sender, MouseWheelEventArgs e)
        {
            // // AkonDeV 06/2026
            if (WallpaperImage.Source == null) return;

            double zoomFactor = e.Delta > 0 ? 1.1 : 0.9;
            double newScaleX = ImageScale.ScaleX * zoomFactor;
            double newScaleY = ImageScale.ScaleY * zoomFactor;

            // Restringir el zoom entre 0.1x y 10.0x
            if (newScaleX >= 0.1 && newScaleX <= 10.0)
            {
                ImageScale.ScaleX = newScaleX;
                ImageScale.ScaleY = newScaleY;
            }
            e.Handled = true;
        }

        private void FitToWindow_Click(object sender, RoutedEventArgs e)
        {
            // // AkonDeV 06/2026
            WallpaperImage.Stretch = Stretch.Uniform;
            ImageScale.ScaleX = 1.0;
            ImageScale.ScaleY = 1.0;
        }

        private void ActualSize_Click(object sender, RoutedEventArgs e)
        {
            // // AkonDeV 06/2026
            WallpaperImage.Stretch = Stretch.None;
            ImageScale.ScaleX = 1.0;
            ImageScale.ScaleY = 1.0;
        }

        private void HistoryListBox_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            // // AkonDeV 06/2026
            if (sender is ListBox listBox && listBox.SelectedItem is string query)
            {
                if (DataContext is MainViewModel vm)
                {
                    _ = vm.SearchQueryFromHistoryAsync(query);
                }
            }
        }
    }
}
