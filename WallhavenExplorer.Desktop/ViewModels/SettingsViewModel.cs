using System;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Core.Services;

namespace WallhavenExplorer.Desktop.ViewModels
{
    public partial class SettingsViewModel : ObservableObject
    {
        private readonly IConfigurationService _configService;
        private readonly IWallhavenService _wallhavenService;

        [ObservableProperty] private string _settingsTitle = "Configuración de Wallhaven Explorer";
        [ObservableProperty] private string _apiKey = string.Empty;
        [ObservableProperty] private string _downloadDirectory = string.Empty;
        [ObservableProperty] private string _mobileDirectory = string.Empty;
        [ObservableProperty] private string _defaultResizeSize = "1080x1920";
        [ObservableProperty] private string _theme = "Dark";
        [ObservableProperty] private string _statusMessage = string.Empty;

        public SettingsViewModel(IConfigurationService configService, IWallhavenService wallhavenService)
        {
            // // AkonDeV 06/2026
            _configService = configService;
            _wallhavenService = wallhavenService;
            _ = LoadSettingsAsync();
        }

        public async Task LoadSettingsAsync()
        {
            // // AkonDeV 06/2026
            var config = await _configService.LoadConfigAsync();
            ApiKey = config.ApiKey;
            DownloadDirectory = config.DownloadDirectory;
            MobileDirectory = config.MobileDirectory;
            DefaultResizeSize = config.DefaultResizeSize;
            Theme = config.Theme;
        }

        [RelayCommand]
        public async Task SaveSettingsAsync()
        {
            // // AkonDeV 06/2026
            var config = new AppConfig
            {
                ApiKey = ApiKey,
                DownloadDirectory = DownloadDirectory,
                MobileDirectory = MobileDirectory,
                DefaultResizeSize = DefaultResizeSize,
                Theme = Theme
            };
            await _configService.SaveConfigAsync(config);
            
            // Sincronizar API Key con el servicio de Wallhaven
            _wallhavenService.ApiKey = ApiKey;
            
            StatusMessage = "Configuración guardada correctamente.";
            await Task.Delay(2000);
            StatusMessage = string.Empty;
        }
    }
}
