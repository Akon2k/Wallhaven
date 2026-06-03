using System.Threading.Tasks;
using WallhavenExplorer.Core.Services;

namespace WallhavenExplorer.Desktop.Services
{
    public class ImageProcessorService : IImageProcessorService
    {
        // AkonDeV 06/2026
        public Task ProcessMobileResizeAsync(
            string sourcePath, 
            string targetPath, 
            int width, 
            int height, 
            ResizeMode mode)
        {
            // Will use SixLabors.ImageSharp in Phase 2
            return Task.CompletedTask;
        }
    }
}
