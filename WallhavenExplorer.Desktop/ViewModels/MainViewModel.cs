using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.DependencyInjection;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Core.Services;
using Serilog;

namespace WallhavenExplorer.Desktop.ViewModels
{
    public partial class MainViewModel : ObservableObject
    {
        private readonly IWallhavenService _wallhavenService;
        private readonly IImageProcessorService _imageProcessorService;
        private readonly IDatabaseService _databaseService;
        private readonly IConfigurationService _configService;
        private readonly IImageCacheService _imageCacheService;
        private readonly IServiceProvider _serviceProvider;
        private CancellationTokenSource? _searchCts;
        private CancellationTokenSource? _slideshowCts;

        [ObservableProperty] private string _title = "Wallhaven Explorer";
        [ObservableProperty] private string _searchQuery = string.Empty;
        [ObservableProperty] private ObservableCollection<Wallpaper> _wallpapers = new();
        [ObservableProperty] private Wallpaper? _selectedWallpaper;
        [ObservableProperty] private string _displayedImagePath = string.Empty;
        [ObservableProperty] private ObservableCollection<Wallpaper> _favoriteWallpapers = new();
        [ObservableProperty] private ObservableCollection<string> _searchHistory = new();
        [ObservableProperty] private bool _isFavorite;
        [ObservableProperty] private bool _isSlideshowActive;
        [ObservableProperty] private bool _isFullScreen;
        
        // Paginación
        [ObservableProperty] private int _currentPage = 1;
        [ObservableProperty] private int _maxPages = 1;
        
        // Filtros observables
        [ObservableProperty] private bool _categoriesGeneral = true;
        [ObservableProperty] private bool _categoriesAnime = true;
        [ObservableProperty] private bool _categoriesPeople = true;
        [ObservableProperty] private bool _puritySfw = true;
        [ObservableProperty] private bool _puritySketchy = false;
        [ObservableProperty] private bool _purityNsfw = false;
        [ObservableProperty] private string _selectedSorting = "relevance";
        [ObservableProperty] private string _selectedOrder = "desc";

        // Redimensionamiento móvil
        [ObservableProperty] private string _selectedResizeResolution = "1080x1920";
        [ObservableProperty] private string _selectedResizeMode = "SmartCropCentred";

        [ObservableProperty] private double _downloadProgress;
        [ObservableProperty] private bool _isLoading;
        [ObservableProperty] private string _statusMessage = "Listo";

        public string ImagePositionText
        {
            get
            {
                // // AkonDeV 06/2026
                if (Wallpapers.Count == 0 || SelectedWallpaper == null) return "Sin imágenes";
                int index = Wallpapers.IndexOf(SelectedWallpaper) + 1;
                return $"Imagen {index} de {Wallpapers.Count}";
            }
        }

        public MainViewModel(
            IWallhavenService whService, 
            IImageProcessorService imgService, 
            IDatabaseService dbService,
            IConfigurationService configService,
            IImageCacheService imageCacheService,
            IServiceProvider serviceProvider)
        {
            // // AkonDeV 06/2026
            _wallhavenService = whService;
            _imageProcessorService = imgService;
            _databaseService = dbService;
            _configService = configService;
            _imageCacheService = imageCacheService;
            _serviceProvider = serviceProvider;
            
            // Búsqueda automática inicial al cargar la aplicación
            _ = GetRandomWallpaperAsync();
            _ = LoadFavoritesAsync();
            _ = LoadHistoryAsync();
        }

        partial void OnSelectedWallpaperChanged(Wallpaper? value)
        {
            // // AkonDeV 06/2026
            _ = UpdateDisplayedImageAsync(value);
            OnPropertyChanged(nameof(ImagePositionText));
        }

        private async Task UpdateDisplayedImageAsync(Wallpaper? wp)
        {
            // // AkonDeV 06/2026
            if (wp == null)
            {
                DisplayedImagePath = string.Empty;
                IsFavorite = false;
                return;
            }

            IsLoading = true;
            StatusMessage = "Cargando imagen...";
            try
            {
                string localPath = await _imageCacheService.GetCachedImagePathAsync(wp.Id, wp.Path);
                DisplayedImagePath = localPath;
                IsFavorite = await _databaseService.IsFavoriteAsync(wp.Id);
                StatusMessage = $"Mostrando wallpaper ID: {wp.Id}";
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error al cargar el wallpaper a la vista.");
                DisplayedImagePath = wp.Path; // Fallback a URL original
                IsFavorite = await _databaseService.IsFavoriteAsync(wp.Id);
                StatusMessage = "Error al cachear; mostrando imagen de forma remota.";
            }
            finally
            {
                IsLoading = false;
            }
        }

        [RelayCommand]
        public async Task SearchNewQueryAsync()
        {
            // // AkonDeV 06/2026
            CurrentPage = 1;
            await ExecuteSearchAsync();
        }

        [RelayCommand]
        public async Task ExecuteSearchAsync()
        {
            // // AkonDeV 06/2026
            _searchCts?.Cancel();
            _searchCts = new CancellationTokenSource();

            IsLoading = true;
            StatusMessage = "Buscando wallpapers...";
            DownloadProgress = 0;

            try
            {
                var config = await _configService.LoadConfigAsync();
                
                // Formatear categorías y pureza en cadenas binarias de 3 bits
                string categories = $"{(CategoriesGeneral ? 1 : 0)}{(CategoriesAnime ? 1 : 0)}{(CategoriesPeople ? 1 : 0)}";
                string purity = $"{(PuritySfw ? 1 : 0)}{(PuritySketchy ? 1 : 0)}{(PurityNsfw ? 1 : 0)}";

                var filters = new SearchFilters 
                { 
                    Categories = categories, 
                    Purity = purity, 
                    Sorting = SelectedSorting,
                    Order = SelectedOrder,
                    ApiKey = config.ApiKey 
                };
                
                var result = await _wallhavenService.SearchWallpapersAsync(SearchQuery, filters, CurrentPage, _searchCts.Token);

                Wallpapers.Clear();
                foreach (var wp in result.Item1)
                {
                    Wallpapers.Add(wp);
                }
                MaxPages = result.Item2;

                if (Wallpapers.Count > 0)
                {
                    SelectedWallpaper = Wallpapers[0];
                    StatusMessage = $"Encontrados {Wallpapers.Count} elementos. Página {CurrentPage} de {MaxPages}";
                }
                else
                {
                    StatusMessage = "No se encontraron resultados.";
                }

                await _databaseService.SaveSearchHistoryAsync(SearchQuery, "{}");
                await LoadHistoryAsync();
            }
            catch (OperationCanceledException)
            {
                StatusMessage = "Búsqueda cancelada.";
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error durante la ejecución de búsqueda.");
                StatusMessage = "Error al conectar con Wallhaven.";
            }
            finally
            {
                IsLoading = false;
            }
        }

        [RelayCommand]
        public async Task GoToNextPageAsync()
        {
            // // AkonDeV 06/2026
            if (CurrentPage < MaxPages)
            {
                CurrentPage++;
                await ExecuteSearchAsync();
            }
        }

        [RelayCommand]
        public async Task GoToPreviousPageAsync()
        {
            // // AkonDeV 06/2026
            if (CurrentPage > 1)
            {
                CurrentPage--;
                await ExecuteSearchAsync();
            }
        }

        [RelayCommand]
        public void NavigateNext()
        {
            // // AkonDeV 06/2026
            if (Wallpapers.Count == 0 || SelectedWallpaper == null) return;
            int currentIndex = Wallpapers.IndexOf(SelectedWallpaper);
            if (currentIndex < Wallpapers.Count - 1)
            {
                SelectedWallpaper = Wallpapers[currentIndex + 1];
            }
        }

        [RelayCommand]
        public void NavigatePrevious()
        {
            // // AkonDeV 06/2026
            if (Wallpapers.Count == 0 || SelectedWallpaper == null) return;
            int currentIndex = Wallpapers.IndexOf(SelectedWallpaper);
            if (currentIndex > 0)
            {
                SelectedWallpaper = Wallpapers[currentIndex - 1];
            }
        }

        [RelayCommand]
        public void NavigateFirst()
        {
            // // AkonDeV 06/2026
            if (Wallpapers.Count > 0)
            {
                SelectedWallpaper = Wallpapers[0];
            }
        }

        [RelayCommand]
        public void NavigateLast()
        {
            // // AkonDeV 06/2026
            if (Wallpapers.Count > 0)
            {
                SelectedWallpaper = Wallpapers[Wallpapers.Count - 1];
            }
        }

        [RelayCommand]
        public async Task DownloadOriginalAsync()
        {
            // // AkonDeV 06/2026
            if (SelectedWallpaper == null) return;

            var config = await _configService.LoadConfigAsync();
            string targetFolder = !string.IsNullOrWhiteSpace(config.DownloadDirectory)
                ? config.DownloadDirectory
                : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "WallhavenDownloads");

            if (!Directory.Exists(targetFolder)) Directory.CreateDirectory(targetFolder);

            string extension = Path.GetExtension(SelectedWallpaper.Path) ?? ".jpg";
            string targetPath = Path.Combine(targetFolder, $"{SelectedWallpaper.Id}{extension}");

            if (File.Exists(targetPath))
            {
                StatusMessage = "El archivo ya existe localmente.";
                return;
            }

            IsLoading = true;
            StatusMessage = "Descargando imagen original...";
            var progressReporter = new Progress<double>(val => DownloadProgress = val);

            try
            {
                await _wallhavenService.DownloadFileAsync(SelectedWallpaper.Path, targetPath, progressReporter, CancellationToken.None);
                StatusMessage = $"Descarga finalizada con éxito en: {targetPath}";
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Fallo al descargar wallpaper id {Id}", SelectedWallpaper.Id);
                StatusMessage = "Fallo en la descarga de archivos.";
            }
            finally
            {
                IsLoading = false;
            }
        }

        [RelayCommand]
        public async Task CreateMobileVersionAsync()
        {
            // // AkonDeV 06/2026
            if (SelectedWallpaper == null) return;

            IsLoading = true;
            StatusMessage = "Iniciando procesamiento móvil...";
            DownloadProgress = 0;

            try
            {
                var config = await _configService.LoadConfigAsync();
                
                // 1. Obtener imagen origen local (desde la caché local)
                string sourcePath = await _imageCacheService.GetCachedImagePathAsync(SelectedWallpaper.Id, SelectedWallpaper.Path);
                
                if (!File.Exists(sourcePath))
                {
                    StatusMessage = "No se pudo obtener la imagen origen local.";
                    return;
                }

                // 2. Determinar la resolución destino
                int width = 1080;
                int height = 1920;
                string res = SelectedResizeResolution ?? config.DefaultResizeSize ?? "1080x1920";
                var parts = res.Split('x');
                if (parts.Length == 2 && int.TryParse(parts[0], out int w) && int.TryParse(parts[1], out int h))
                {
                    width = w;
                    height = h;
                }

                // 3. Determinar el modo de redimensionamiento
                Core.Services.ResizeMode mode = Core.Services.ResizeMode.SmartCropCentred;
                if (Enum.TryParse<Core.Services.ResizeMode>(SelectedResizeMode, out var parsedMode))
                {
                    mode = parsedMode;
                }

                // 4. Determinar la carpeta de destino
                string targetFolder = !string.IsNullOrWhiteSpace(config.MobileDirectory)
                    ? config.MobileDirectory
                    : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "WallhavenMobile");

                if (!Directory.Exists(targetFolder)) Directory.CreateDirectory(targetFolder);

                string extension = Path.GetExtension(SelectedWallpaper.Path) ?? ".jpg";
                string targetPath = Path.Combine(targetFolder, $"{SelectedWallpaper.Id}_{width}x{height}_{mode}{extension}");

                // 5. Procesar imagen
                StatusMessage = "Procesando y redimensionando imagen...";
                await _imageProcessorService.ProcessMobileResizeAsync(sourcePath, targetPath, width, height, mode);

                StatusMessage = $"Versión móvil guardada con éxito en: {targetPath}";
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error al crear la versión móvil para el wallpaper ID {Id}", SelectedWallpaper.Id);
                StatusMessage = "Fallo al procesar la imagen móvil.";
            }
            finally
            {
                IsLoading = false;
            }
        }

        [RelayCommand]
        public async Task ToggleFavoriteAsync()
        {
            // // AkonDeV 06/2026
            if (SelectedWallpaper == null) return;

            try
            {
                if (IsFavorite)
                {
                    await _databaseService.RemoveFavoriteAsync(SelectedWallpaper.Id);
                    IsFavorite = false;
                    StatusMessage = "Eliminado de favoritos.";
                }
                else
                {
                    await _databaseService.SaveFavoriteAsync(SelectedWallpaper);
                    IsFavorite = true;
                    StatusMessage = "Añadido a favoritos.";
                }
                await LoadFavoritesAsync();
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error al alternar favorito para {Id}", SelectedWallpaper.Id);
                StatusMessage = "Error al actualizar favoritos.";
            }
        }

        [RelayCommand]
        public async Task LoadFavoritesAsync()
        {
            // // AkonDeV 06/2026
            try
            {
                var favorites = await _databaseService.GetFavoritesAsync();
                FavoriteWallpapers.Clear();
                foreach (var fav in favorites)
                {
                    FavoriteWallpapers.Add(fav);
                }
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error al cargar favoritos.");
            }
        }

        [RelayCommand]
        public async Task LoadHistoryAsync()
        {
            // // AkonDeV 06/2026
            try
            {
                var history = await _databaseService.GetSearchHistoryAsync(20);
                SearchHistory.Clear();
                var added = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (var item in history)
                {
                    if (!string.IsNullOrWhiteSpace(item.Item1) && added.Add(item.Item1))
                    {
                        SearchHistory.Add(item.Item1);
                    }
                }
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error al cargar historial.");
            }
        }

        [RelayCommand]
        public async Task SearchQueryFromHistoryAsync(string query)
        {
            // // AkonDeV 06/2026
            if (string.IsNullOrWhiteSpace(query)) return;
            SearchQuery = query;
            CurrentPage = 1;
            await ExecuteSearchAsync();
        }

        [RelayCommand]
        public async Task ToggleSlideshowAsync()
        {
            // // AkonDeV 06/2026
            if (IsSlideshowActive)
            {
                IsSlideshowActive = false;
                _slideshowCts?.Cancel();
                StatusMessage = "Slideshow pausado.";
            }
            else
            {
                IsSlideshowActive = true;
                _slideshowCts = new CancellationTokenSource();
                StatusMessage = "Slideshow iniciado.";
                _ = RunSlideshowLoopAsync(_slideshowCts.Token);
            }
        }

        private async Task RunSlideshowLoopAsync(CancellationToken token)
        {
            // // AkonDeV 06/2026
            try
            {
                while (!token.IsCancellationRequested)
                {
                    await Task.Delay(TimeSpan.FromSeconds(5), token);

                    if (Wallpapers.Count == 0 || SelectedWallpaper == null) continue;

                    int currentIndex = Wallpapers.IndexOf(SelectedWallpaper);
                    if (currentIndex < Wallpapers.Count - 1)
                    {
                        SelectedWallpaper = Wallpapers[currentIndex + 1];
                    }
                    else
                    {
                        if (CurrentPage < MaxPages)
                        {
                            CurrentPage++;
                            await ExecuteSearchAsync();
                        }
                        else
                        {
                            SelectedWallpaper = Wallpapers[0];
                        }
                    }
                }
            }
            catch (OperationCanceledException)
            {
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error en el bucle del Slideshow.");
            }
            finally
            {
                IsSlideshowActive = false;
            }
        }

        [RelayCommand]
        public async Task GetRandomWallpaperAsync()
        {
            // // AkonDeV 06/2026
            SelectedSorting = "random";
            SearchQuery = string.Empty;
            CurrentPage = 1;
            await ExecuteSearchAsync();
        }

        [RelayCommand]
        public void CopyUrlToClipboard()
        {
            // // AkonDeV 06/2026
            if (SelectedWallpaper == null) return;
            try
            {
                Clipboard.SetText(SelectedWallpaper.Url);
                StatusMessage = "URL copiada al portapapeles.";
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error al copiar URL al portapapeles.");
                StatusMessage = "No se pudo copiar la URL.";
            }
        }

        [RelayCommand]
        public void OpenInBrowser()
        {
            // // AkonDeV 06/2026
            if (SelectedWallpaper == null || string.IsNullOrWhiteSpace(SelectedWallpaper.Url)) return;
            try
            {
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
                {
                    FileName = SelectedWallpaper.Url,
                    UseShellExecute = true
                });
                StatusMessage = "Abriendo en el navegador...";
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error al abrir la URL {Url} en el navegador.", SelectedWallpaper.Url);
                StatusMessage = "No se pudo abrir el navegador.";
            }
        }

        [RelayCommand]
        public void OpenSettings()
        {
            // // AkonDeV 06/2026
            var settingsWindow = _serviceProvider.GetRequiredService<Views.SettingsWindow>();
            if (Application.Current.MainWindow is Window mainWin)
            {
                settingsWindow.Owner = mainWin;
            }
            settingsWindow.ShowDialog();
        }
    }
}
