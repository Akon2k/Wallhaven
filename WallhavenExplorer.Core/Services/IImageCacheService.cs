using System.Threading.Tasks;

namespace WallhavenExplorer.Core.Services
{
    public interface IImageCacheService
    {
        // AkonDeV 06/2026
        Task<string> GetCachedImagePathAsync(string id, string url);
        void ClearCache();
    }
}
