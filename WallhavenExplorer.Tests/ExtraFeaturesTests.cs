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

        [Fact]
        public void NavigateFirstLastNextPrevious_InSearchResultsList_WorksCorrectly()
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

            vm.Wallpapers.Clear();
            vm.FavoriteWallpapers.Clear();

            var wp1 = new Wallpaper { Id = "w1", Path = "url1" };
            var wp2 = new Wallpaper { Id = "w2", Path = "url2" };
            var wp3 = new Wallpaper { Id = "w3", Path = "url3" };

            vm.Wallpapers.Add(wp1);
            vm.Wallpapers.Add(wp2);
            vm.Wallpapers.Add(wp3);

            vm.SelectedTabIndex = 0; // Búsqueda activa
            vm.SelectedWallpaper = wp1;

            // Avanzar
            Assert.True(vm.NavigateNextCommand.CanExecute(null));
            vm.NavigateNextCommand.Execute(null);
            Assert.Equal(wp2, vm.SelectedWallpaper);

            // Ir al último
            Assert.True(vm.NavigateLastCommand.CanExecute(null));
            vm.NavigateLastCommand.Execute(null);
            Assert.Equal(wp3, vm.SelectedWallpaper);
            Assert.False(vm.NavigateNextCommand.CanExecute(null));

            // Retroceder
            Assert.True(vm.NavigatePreviousCommand.CanExecute(null));
            vm.NavigatePreviousCommand.Execute(null);
            Assert.Equal(wp2, vm.SelectedWallpaper);

            // Ir al primero
            Assert.True(vm.NavigateFirstCommand.CanExecute(null));
            vm.NavigateFirstCommand.Execute(null);
            Assert.Equal(wp1, vm.SelectedWallpaper);
            Assert.False(vm.NavigatePreviousCommand.CanExecute(null));
        }

        [Fact]
        public void NavigateFirstLastNextPrevious_InFavoritesList_WorksCorrectly()
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

            vm.Wallpapers.Clear();
            vm.FavoriteWallpapers.Clear();

            var fav1 = new Wallpaper { Id = "f1", Path = "url1" };
            var fav2 = new Wallpaper { Id = "f2", Path = "url2" };

            vm.FavoriteWallpapers.Add(fav1);
            vm.FavoriteWallpapers.Add(fav2);

            // Importante: pestaña de Favoritos = 1
            vm.SelectedTabIndex = 1; 
            vm.SelectedWallpaper = fav1;

            Assert.True(vm.NavigateNextCommand.CanExecute(null));
            vm.NavigateNextCommand.Execute(null);
            Assert.Equal(fav2, vm.SelectedWallpaper);

            Assert.False(vm.NavigateNextCommand.CanExecute(null));
            Assert.True(vm.NavigatePreviousCommand.CanExecute(null));
        }

        [Fact]
        public void CanExecute_ReflectsRelativePosition_InCollections()
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

            vm.Wallpapers.Clear();
            vm.FavoriteWallpapers.Clear();

            // Si está vacío, nada puede ejecutarse
            Assert.False(vm.NavigateNextCommand.CanExecute(null));
            Assert.False(vm.NavigatePreviousCommand.CanExecute(null));

            var wp = new Wallpaper { Id = "w1" };
            vm.Wallpapers.Add(wp);
            vm.SelectedWallpaper = wp;

            // Con un solo elemento, no hay siguiente ni anterior
            Assert.False(vm.NavigateNextCommand.CanExecute(null));
            Assert.False(vm.NavigatePreviousCommand.CanExecute(null));
            Assert.False(vm.NavigateFirstCommand.CanExecute(null));
            Assert.False(vm.NavigateLastCommand.CanExecute(null));
        }

        [Fact]
        public void ToggleGridView_ChangesStateCorrectly()
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

            Assert.True(vm.IsGridViewActive);
            vm.ToggleGridViewCommand.Execute(null);
            Assert.False(vm.IsGridViewActive);
        }

        [Fact]
        public void ToggleDetailsPanel_ChangesStateCorrectly()
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

            Assert.True(vm.IsDetailsPanelOpen);
            vm.ToggleDetailsPanelCommand.Execute(null);
            Assert.False(vm.IsDetailsPanelOpen);
        }
    }
}
