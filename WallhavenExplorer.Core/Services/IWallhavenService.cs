using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;

namespace WallhavenExplorer.Core.Services
{
    public interface IWallhavenService
    {
        // AkonDeV 06/2026
        string ApiKey { get; set; }

        Task<Tuple<IEnumerable<Wallpaper>, int>> SearchWallpapersAsync(
            string query, 
            SearchFilters filters, 
            int page, 
            CancellationToken cancellationToken);

        Task<Wallpaper> GetWallpaperDetailsAsync(string id, CancellationToken cancellationToken);

        Task DownloadFileAsync(string url, string destinationPath, IProgress<double> progress, CancellationToken cancellationToken);
    }
}
