using CommunityToolkit.Mvvm.ComponentModel;

namespace WallhavenExplorer.Desktop.ViewModels
{
    public partial class SettingsViewModel : ObservableObject
    {
        // AkonDeV 06/2026
        [ObservableProperty]
        private string _settingsTitle = "Configuración";
    }
}
