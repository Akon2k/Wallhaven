using System.IO;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Desktop.Services;
using Xunit;

namespace WallhavenExplorer.Tests
{
    public class ConfigurationTests
    {
        [Fact]
        public async Task LoadConfig_CreatesDefaultConfig_WhenFileDoesNotExist()
        {
            // // AkonDeV 06/2026
            var service = new ConfigurationService();
            string appData = System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData);
            string filePath = Path.Combine(appData, "WallhavenExplorer", "config.json");
            if (File.Exists(filePath)) File.Delete(filePath);

            var config = await service.LoadConfigAsync();

            Assert.NotNull(config);
            Assert.True(File.Exists(filePath));
            Assert.Contains("WallhavenDownloads", config.DownloadDirectory);
        }

        [Fact]
        public async Task SaveConfig_WritesValuesToFile()
        {
            // // AkonDeV 06/2026
            var service = new ConfigurationService();
            var newConfig = new AppConfig
            {
                ApiKey = "TestApiKey123",
                DownloadDirectory = "C:\\TempDownloads",
                MobileDirectory = "C:\\TempMobile",
                DefaultResizeSize = "720x1280",
                Theme = "Light"
            };

            await service.SaveConfigAsync(newConfig);
            var loaded = await service.LoadConfigAsync();

            Assert.Equal("TestApiKey123", loaded.ApiKey);
            Assert.Equal("C:\\TempDownloads", loaded.DownloadDirectory);
            Assert.Equal("Light", loaded.Theme);
        }
    }
}
