using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Core.Services;
using Serilog;

namespace WallhavenExplorer.Desktop.Services
{
    public class WallhavenService : IWallhavenService
    {
        private readonly IHttpClientFactory _clientFactory;

        public WallhavenService(IHttpClientFactory clientFactory)
        {
            // // AkonDeV 06/2026
            _clientFactory = clientFactory;
        }

        public async Task<Tuple<IEnumerable<Wallpaper>, int>> SearchWallpapersAsync(
            string query, SearchFilters filters, int page, CancellationToken cancellationToken)
        {
            // // AkonDeV 06/2026
            var client = _clientFactory.CreateClient("WallhavenClient");
            
            // Construcción controlada de QueryString evadiendo deformaciones de URL
            string categories = filters != null ? filters.Categories : "111";
            string purity = filters != null ? filters.Purity : "100";
            string sorting = filters != null ? filters.Sorting : "relevance";
            string apiKeyParam = !string.IsNullOrEmpty(filters?.ApiKey) ? $"&apikey={filters.ApiKey}" : "";

            string url = $"search?q={Uri.EscapeDataString(query)}&categories={categories}&purity={purity}&sorting={sorting}&page={page}{apiKeyParam}";

            HttpResponseMessage response = await client.GetAsync(url, cancellationToken);
            response.EnsureSuccessStatusCode();

            string jsonString = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(jsonString);
            var root = doc.RootElement;

            var list = new List<Wallpaper>();
            if (root.TryGetProperty("data", out var dataArray) && dataArray.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in dataArray.EnumerateArray())
                {
                    var wp = new Wallpaper
                    {
                        Id = item.GetProperty("id").GetString() ?? string.Empty,
                        Url = item.GetProperty("url").GetString() ?? string.Empty,
                        Path = item.GetProperty("path").GetString() ?? string.Empty,
                        Resolution = item.GetProperty("resolution").GetString() ?? string.Empty,
                        Category = item.GetProperty("category").GetString() ?? string.Empty,
                        Uploader = item.GetProperty("uploader").TryGetProperty("username", out var user) ? user.GetString() ?? "" : "",
                        ShortUrl = item.GetProperty("short_url").GetString() ?? string.Empty
                    };

                    if (item.TryGetProperty("tags", out var tagsProp) && tagsProp.ValueKind == JsonValueKind.Array)
                    {
                        foreach (var t in tagsProp.EnumerateArray()) wp.Tags.Add(t.GetProperty("name").GetString() ?? "");
                    }
                    list.Add(wp);
                }
            }

            int lastPage = 1;
            if (root.TryGetProperty("meta", out var metaObj) && metaObj.TryGetProperty("last_page", out var lpProp))
            {
                lastPage = lpProp.GetInt32();
            }

            return Tuple.Create<IEnumerable<Wallpaper>, int>(list, lastPage);
        }

        public async Task<Wallpaper> GetWallpaperDetailsAsync(string id, CancellationToken cancellationToken)
        {
            // // AkonDeV 06/2026
            var client = _clientFactory.CreateClient("WallhavenClient");
            HttpResponseMessage response = await client.GetAsync($"w/{id}", cancellationToken);
            response.EnsureSuccessStatusCode();

            string jsonString = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(jsonString);
            var data = doc.RootElement.GetProperty("data");

            var wp = new Wallpaper
            {
                Id = data.GetProperty("id").GetString() ?? string.Empty,
                Url = data.GetProperty("url").GetString() ?? string.Empty,
                Path = data.GetProperty("path").GetString() ?? string.Empty,
                Resolution = data.GetProperty("resolution").GetString() ?? string.Empty,
                Category = data.GetProperty("category").GetString() ?? string.Empty,
                ShortUrl = data.GetProperty("short_url").GetString() ?? string.Empty
            };
            return wp;
        }

        public async Task DownloadFileAsync(string url, string destinationPath, IProgress<double> progress, CancellationToken cancellationToken)
        {
            // // AkonDeV 06/2026
            var client = _clientFactory.CreateClient("WallhavenClient");
            using var response = await client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            response.EnsureSuccessStatusCode();

            long? totalBytes = response.Content.Headers.ContentLength;

            using var contentStream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var fileStream = new FileStream(destinationPath, FileMode.Create, FileAccess.Write, FileShare.None, 8192, true);

            var buffer = new byte[8192];
            long totalReadBytes = 0;
            int readBytes;

            while ((readBytes = await contentStream.ReadAsync(buffer, 0, buffer.Length, cancellationToken)) > 0)
            {
                await fileStream.WriteAsync(buffer.AsMemory(0, readBytes), cancellationToken);
                totalReadBytes += readBytes;

                if (totalBytes.HasValue)
                {
                    progress.Report((double)totalReadBytes / totalBytes.Value * 100);
                }
            }
        }
    }
}
