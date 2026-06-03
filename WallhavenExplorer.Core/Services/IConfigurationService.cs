using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;

namespace WallhavenExplorer.Core.Services
{
    public interface IConfigurationService
    {
        // AkonDeV 06/2026
        Task<AppConfig> LoadConfigAsync();
        Task SaveConfigAsync(AppConfig config);
    }
}
