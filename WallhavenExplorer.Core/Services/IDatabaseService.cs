using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;

namespace WallhavenExplorer.Core.Services
{
    public interface IDatabaseService
    {
        // AkonDeV 06/2026
        Task InitializeDatabaseAsync();
        
        // Favoritos
        Task SaveFavoriteAsync(Wallpaper wallpaper);
        Task RemoveFavoriteAsync(string id);
        Task<IEnumerable<Wallpaper>> GetFavoritesAsync();
        Task<bool> IsFavoriteAsync(string id);

        // Historial
        Task SaveSearchHistoryAsync(string queryText, string filterJson);
        Task<IEnumerable<Tuple<string, string, DateTime>>> GetSearchHistoryAsync(int limit);
    }
}
