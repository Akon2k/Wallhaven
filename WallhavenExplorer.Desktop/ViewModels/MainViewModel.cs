using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
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
        private CancellationTokenSource? _searchCts;

        [ObservableProperty] private string _title = "Wallhaven Explorer";
        [ObservableProperty] private string _searchQuery = string.Empty;
        [ObservableProperty] private ObservableCollection<Wallpaper> _wallpapers = new();
        [ObservableProperty] private Wallpaper? _selectedWallpaper;
        [ObservableProperty] private int _currentPage = 1;
        [ObservableProperty] private int _maxPages = 1;
        [ObservableProperty] private double _downloadProgress;
        [ObservableProperty] private bool _isLoading;
        [ObservableProperty] private string _statusMessage = "Listo";

        public MainViewModel(IWallhavenService whService, IImageProcessorService imgService, IDatabaseService dbService)
        {
            // // AkonDeV 06/2026
            _wallhavenService = whService;
            _imageProcessorService = imgService;
            _databaseService = dbService;
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
                var filters = new SearchFilters { Categories = "111", Purity = "100", Sorting = "relevance" };
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
        public async Task DownloadOriginalAsync()
        {
            // // AkonDeV 06/2026
            if (SelectedWallpaper == null) return;

            string targetFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "WallhavenDownloads");
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
                StatusMessage = $"Descarga finalizada con éxito en Pictures/WallhavenDownloads.";
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
    }
}
