using System;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Core.Services;

namespace WallhavenExplorer.Desktop.Services
{
    public class ConfigurationService : IConfigurationService
    {
        private readonly string _configFilePath;

        public ConfigurationService()
        {
            // // AkonDeV 06/2026
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string folder = Path.Combine(appData, "WallhavenExplorer");
            if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
            _configFilePath = Path.Combine(folder, "config.json");
        }

        public async Task<AppConfig> LoadConfigAsync()
        {
            // // AkonDeV 06/2026
            if (!File.Exists(_configFilePath))
            {
                var defaultConfig = new AppConfig
                {
                    DownloadDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "WallhavenDownloads"),
                    MobileDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "WallhavenMobile")
                };
                await SaveConfigAsync(defaultConfig);
                return defaultConfig;
            }

            try
            {
                string json = await File.ReadAllTextAsync(_configFilePath);
                return JsonSerializer.Deserialize<AppConfig>(json) ?? new AppConfig();
            }
            catch
            {
                return new AppConfig();
            }
        }

        public async Task SaveConfigAsync(AppConfig config)
        {
            // // AkonDeV 06/2026
            try
            {
                string json = JsonSerializer.Serialize(config, new JsonSerializerOptions { WriteIndented = true });
                await File.WriteAllTextAsync(_configFilePath, json);
            }
            catch (Exception ex)
            {
                Serilog.Log.Error(ex, "Error al guardar la configuración.");
            }
        }
    }
}
