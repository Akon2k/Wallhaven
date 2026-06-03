using System.Threading.Tasks;

namespace WallhavenExplorer.Core.Services
{
    public enum ResizeMode
    {
        SmartCropCentred,
        LetterboxBlack,
        ScaleMaintainAspect
    }

    public interface IImageProcessorService
    {
        // AkonDeV 06/2026
        Task ProcessMobileResizeAsync(
            string sourcePath, 
            string targetPath, 
            int width, 
            int height, 
            ResizeMode mode);
    }
}
