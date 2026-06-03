using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Core.Services;

namespace WallhavenExplorer.Desktop.Services
{
    public class WallhavenService : IWallhavenService
    {
        // AkonDeV 06/2026
        public Task<Tuple<IEnumerable<Wallpaper>, int>> SearchWallpapersAsync(
            string query, 
            SearchFilters filters, 
            int page, 
            CancellationToken cancellationToken)
        {
            IEnumerable<Wallpaper> results = new List<Wallpaper>();
            return Task.FromResult(Tuple.Create(results, 0));
        }

        public Task<Wallpaper> GetWallpaperDetailsAsync(string id, CancellationToken cancellationToken)
        {
            return Task.FromResult(new Wallpaper { Id = id });
        }

        public Task DownloadFileAsync(string url, string destinationPath, IProgress<double> progress, CancellationToken cancellationToken)
        {
            progress.Report(100.0);
            return Task.CompletedTask;
        }
    }
}
