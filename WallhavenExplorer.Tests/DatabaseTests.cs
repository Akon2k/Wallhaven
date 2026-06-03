using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Desktop.Repositories;
using Xunit;

namespace WallhavenExplorer.Tests
{
    public class DatabaseTests : IDisposable
    {
        // AkonDeV 06/2026
        private readonly string _tempDbPath;
        private readonly DatabaseService _dbService;

        public DatabaseTests()
        {
            // Generar ruta única temporal para no colisionar con la base de datos de producción
            string tempDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
            Directory.CreateDirectory(tempDir);
            _tempDbPath = Path.Combine(tempDir, "test_localdata.db");
            _dbService = new DatabaseService(_tempDbPath);
            _dbService.InitializeDatabaseAsync().GetAwaiter().GetResult();
        }

        public void Dispose()
        {
            // Limpieza de recursos
            try
            {
                if (File.Exists(_tempDbPath))
                {
                    File.Delete(_tempDbPath);
                }
                string? dir = Path.GetDirectoryName(_tempDbPath);
                if (dir != null && Directory.Exists(dir))
                {
                    Directory.Delete(dir, true);
                }
            }
            catch
            {
                // Ignorar errores de borrado de archivos temporales bloqueados
            }
        }

        [Fact]
        public async Task SaveFavorite_And_IsFavorite_WorksCorrectly()
        {
            // // AkonDeV 06/2026
            var wp = new Wallpaper
            {
                Id = "test1",
                Url = "https://wallhaven.cc/w/test1",
                Path = "https://w.wallhaven.cc/full/te/wallhaven-test1.jpg",
                Resolution = "1920x1080",
                Category = "general",
                Tags = new() { "anime", "girl" },
                Uploader = "AkonDeV",
                ShortUrl = "https://whvn.cc/test1"
            };

            Assert.False(await _dbService.IsFavoriteAsync(wp.Id));

            await _dbService.SaveFavoriteAsync(wp);

            Assert.True(await _dbService.IsFavoriteAsync(wp.Id));
        }

        [Fact]
        public async Task GetFavorites_RetrievesSavedItemsOrdered()
        {
            // // AkonDeV 06/2026
            var wp1 = new Wallpaper { Id = "test1", Url = "url1", Path = "path1", Resolution = "1920x1080" };
            var wp2 = new Wallpaper { Id = "test2", Url = "url2", Path = "path2", Resolution = "2560x1440" };

            await _dbService.SaveFavoriteAsync(wp1);
            await Task.Delay(100); // Pequeña demora para asegurar ordenación SavedAt DESC
            await _dbService.SaveFavoriteAsync(wp2);

            var list = (await _dbService.GetFavoritesAsync()).ToList();

            Assert.Equal(2, list.Count);
            Assert.Equal("test2", list[0].Id); // El último insertado aparece primero por DESC
            Assert.Equal("test1", list[1].Id);
        }

        [Fact]
        public async Task RemoveFavorite_DeletesItemCorrectly()
        {
            // // AkonDeV 06/2026
            var wp = new Wallpaper { Id = "test1", Url = "url1", Path = "path1", Resolution = "1920x1080" };

            await _dbService.SaveFavoriteAsync(wp);
            Assert.True(await _dbService.IsFavoriteAsync(wp.Id));

            await _dbService.RemoveFavoriteAsync(wp.Id);
            Assert.False(await _dbService.IsFavoriteAsync(wp.Id));
        }

        [Fact]
        public async Task SearchHistory_SavesAndRetrievesCorrectly()
        {
            // // AkonDeV 06/2026
            await _dbService.SaveSearchHistoryAsync("cats", "{}");
            await Task.Delay(50);
            await _dbService.SaveSearchHistoryAsync("nature", "{}");

            var history = (await _dbService.GetSearchHistoryAsync(5)).ToList();

            Assert.True(history.Count >= 2);
            Assert.Equal("nature", history[0].Item1);
            Assert.Equal("cats", history[1].Item1);
        }
    }
}
