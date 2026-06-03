using System;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Services;

namespace WallhavenExplorer.Desktop.Services
{
    public class ImageCacheService : IImageCacheService
    {
        private readonly string _cacheFolder;
        private readonly IHttpClientFactory _clientFactory;

        public ImageCacheService(IHttpClientFactory clientFactory)
        {
            // // AkonDeV 06/2026
            _clientFactory = clientFactory;
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            _cacheFolder = Path.Combine(appData, "WallhavenExplorer", "Cache");
            if (!Directory.Exists(_cacheFolder)) Directory.CreateDirectory(_cacheFolder);
        }

        public async Task<string> GetCachedImagePathAsync(string id, string url)
        {
            // // AkonDeV 06/2026
            string extension = Path.GetExtension(url);
            if (string.IsNullOrEmpty(extension)) extension = ".jpg";
            string cachedPath = Path.Combine(_cacheFolder, $"{id}{extension}");

            if (File.Exists(cachedPath))
            {
                return cachedPath;
            }

            try
            {
                var client = _clientFactory.CreateClient("WallhavenClient");
                byte[] data = await client.GetByteArrayAsync(url);
                await File.WriteAllBytesAsync(cachedPath, data);
                return cachedPath;
            }
            catch (Exception ex)
            {
                Serilog.Log.Error(ex, "Error al descargar imagen a la caché local: {Url}", url);
                return url; // Retorna la URL original como respaldo
            }
        }

        public void ClearCache()
        {
            // // AkonDeV 06/2026
            try
            {
                if (Directory.Exists(_cacheFolder))
                {
                    foreach (var file in Directory.GetFiles(_cacheFolder))
                    {
                        File.Delete(file);
                    }
                }
            }
            catch (Exception ex)
            {
                Serilog.Log.Error(ex, "Error al vaciar la caché.");
            }
        }
    }
}
