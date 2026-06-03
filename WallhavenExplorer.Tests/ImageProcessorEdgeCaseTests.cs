using System;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Services;
using WallhavenExplorer.Desktop.Services;
using Xunit;

namespace WallhavenExplorer.Tests
{
    public class ImageProcessorEdgeCaseTests
    {
        [Fact]
        public async Task ProcessResize_SourceFileMissing_ThrowsFileNotFoundException()
        {
            // // AkonDeV 06/2026
            // Arrange
            var service = new ImageProcessorService();
            string nonExistentPath = Guid.NewGuid().ToString() + ".jpg";

            // Act & Assert
            await Assert.ThrowsAsync<System.IO.FileNotFoundException>(async () =>
            {
                await service.ProcessMobileResizeAsync(nonExistentPath, "output.jpg", 1080, 1920, Core.Services.ResizeMode.SmartCropCentred);
            });
        }
    }
}
