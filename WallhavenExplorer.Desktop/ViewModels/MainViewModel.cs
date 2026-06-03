using CommunityToolkit.Mvvm.ComponentModel;

namespace WallhavenExplorer.Desktop.ViewModels
{
    public partial class MainViewModel : ObservableObject
    {
        // AkonDeV 06/2026
        [ObservableProperty]
        private string _title = "Wallhaven Explorer";
    }
}
