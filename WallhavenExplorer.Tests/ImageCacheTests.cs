using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using WallhavenExplorer.Desktop.Services;
using Xunit;

namespace WallhavenExplorer.Tests
{
    public class ImageCacheTests
    {
        [Fact]
        public async Task GetCachedImagePath_DownloadsAndSavesFile()
        {
            // // AkonDeV 06/2026
            // Arrange
            string testId = "test_image_123";
            string testUrl = "https://wallhaven.cc/favicon.ico"; // Archivo pequeño remoto

            var services = new ServiceCollection();
            services.AddHttpClient("WallhavenClient");
            var provider = services.BuildServiceProvider();
            var factory = provider.GetRequiredService<IHttpClientFactory>();

            var service = new ImageCacheService(factory);
            service.ClearCache();

            // Act
            string localPath = await service.GetCachedImagePathAsync(testId, testUrl);

            // Assert
            Assert.True(File.Exists(localPath));
            Assert.Contains(testId, localPath);
        }
    }
}
