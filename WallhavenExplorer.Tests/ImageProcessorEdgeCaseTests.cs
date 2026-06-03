using System;
using System.IO;
using System.Threading.Tasks;
using SixLabors.ImageSharp;
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

        [Fact]
        public async Task ProcessResize_ResizeModes_ProduceOutputFiles()
        {
            // // AkonDeV 06/2026
            // Arrange
            var service = new ImageProcessorService();
            string sourcePath = "temp_test_image.jpg";
            string targetPath1 = "output_crop.jpg";
            string targetPath2 = "output_letterbox.jpg";
            string targetPath3 = "output_scale.jpg";

            // Crear una imagen blanca de 100x100 píxeles en memoria y guardarla en disco
            using (var img = new Image<SixLabors.ImageSharp.PixelFormats.Rgb24>(100, 100))
            {
                img.Save(sourcePath);
            }

            try
            {
                // Act
                await service.ProcessMobileResizeAsync(sourcePath, targetPath1, 50, 50, Core.Services.ResizeMode.SmartCropCentred);
                await service.ProcessMobileResizeAsync(sourcePath, targetPath2, 50, 50, Core.Services.ResizeMode.LetterboxBlack);
                await service.ProcessMobileResizeAsync(sourcePath, targetPath3, 50, 50, Core.Services.ResizeMode.ScaleMaintainAspect);

                // Assert
                Assert.True(File.Exists(targetPath1));
                Assert.True(File.Exists(targetPath2));
                Assert.True(File.Exists(targetPath3));
            }
            finally
            {
                // Limpieza de archivos temporales de prueba
                if (File.Exists(sourcePath)) File.Delete(sourcePath);
                if (File.Exists(targetPath1)) File.Delete(targetPath1);
                if (File.Exists(targetPath2)) File.Delete(targetPath2);
                if (File.Exists(targetPath3)) File.Delete(targetPath3);
            }
        }
    }
}
