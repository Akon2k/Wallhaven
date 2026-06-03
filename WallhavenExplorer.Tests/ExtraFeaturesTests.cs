using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Core.Services;
using WallhavenExplorer.Desktop.ViewModels;
using Xunit;

namespace WallhavenExplorer.Tests
{
    public class ExtraFeaturesTests
    {
        // AkonDeV 06/2026
        private class MockWallhavenService : IWallhavenService
        {
            public string ApiKey { get; set; } = string.Empty;
            public Task<Tuple<IEnumerable<Wallpaper>, int>> SearchWallpapersAsync(string query, SearchFilters filters, int page, CancellationToken cancellationToken)
            {
                var list = new List<Wallpaper>
                {
                    new Wallpaper { Id = "1", Path = "http://example.com/1.jpg" }
                };
                return Task.FromResult(Tuple.Create((IEnumerable<Wallpaper>)list, 1));
            }
            public Task<Wallpaper> GetWallpaperDetailsAsync(string id, CancellationToken cancellationToken)
            {
                return Task.FromResult(new Wallpaper { Id = id });
            }
            public Task DownloadFileAsync(string url, string destinationPath, IProgress<double> progress, CancellationToken token)
            {
                return Task.CompletedTask;
            }
        }

        private class MockImageProcessorService : IImageProcessorService
        {
            public Task ProcessMobileResizeAsync(string sourcePath, string targetPath, int width, int height, ResizeMode mode)
            {
                return Task.CompletedTask;
            }
        }

        private class MockDatabaseService : IDatabaseService
        {
            public Task InitializeDatabaseAsync() => Task.CompletedTask;
            public Task SaveFavoriteAsync(Wallpaper wallpaper) => Task.CompletedTask;
            public Task RemoveFavoriteAsync(string id) => Task.CompletedTask;
            public Task<IEnumerable<Wallpaper>> GetFavoritesAsync() => Task.FromResult((IEnumerable<Wallpaper>)new List<Wallpaper>());
            public Task<bool> IsFavoriteAsync(string id) => Task.FromResult(false);
            public Task SaveSearchHistoryAsync(string queryText, string filterJson) => Task.CompletedTask;
            public Task<IEnumerable<Tuple<string, string, DateTime>>> GetSearchHistoryAsync(int limit) =>
                Task.FromResult((IEnumerable<Tuple<string, string, DateTime>>)new List<Tuple<string, string, DateTime>>());
        }

        private class MockConfigurationService : IConfigurationService
        {
            public Task<AppConfig> LoadConfigAsync() => Task.FromResult(new AppConfig());
            public Task SaveConfigAsync(AppConfig config) => Task.CompletedTask;
        }

        private class MockImageCacheService : IImageCacheService
        {
            public Task<string> GetCachedImagePathAsync(string id, string url) => Task.FromResult("cached_path.jpg");
            public void ClearCache() { }
        }

        private class MockServiceProvider : IServiceProvider
        {
            public object? GetService(Type serviceType) => null;
        }

        [Fact]
        public async Task ToggleSlideshow_StartsAndStopsLoopCorrectly()
        {
            // // AkonDeV 06/2026
            var vm = new MainViewModel(
                new MockWallhavenService(),
                new MockImageProcessorService(),
                new MockDatabaseService(),
                new MockConfigurationService(),
                new MockImageCacheService(),
                new MockServiceProvider()
            );

            Assert.False(vm.IsSlideshowActive);

            // Activar
            await vm.ToggleSlideshowCommand.ExecuteAsync(null);
            Assert.True(vm.IsSlideshowActive);

            // Desactivar
            await vm.ToggleSlideshowCommand.ExecuteAsync(null);
            Assert.False(vm.IsSlideshowActive);
        }

        [Fact]
        public async Task GetRandomWallpaper_SetsSearchParametersCorrectly()
        {
            // // AkonDeV 06/2026
            var vm = new MainViewModel(
                new MockWallhavenService(),
                new MockImageProcessorService(),
                new MockDatabaseService(),
                new MockConfigurationService(),
                new MockImageCacheService(),
                new MockServiceProvider()
            );

            vm.SearchQuery = "original query";
            vm.SelectedSorting = "relevance";

            await vm.GetRandomWallpaperCommand.ExecuteAsync(null);

            Assert.Equal("random", vm.SelectedSorting);
            Assert.Empty(vm.SearchQuery);
            Assert.Equal(1, vm.CurrentPage);
        }
    }
}
