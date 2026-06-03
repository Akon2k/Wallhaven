using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Core.Services;

namespace WallhavenExplorer.Desktop.Repositories
{
    public class DatabaseService : IDatabaseService
    {
        // AkonDeV 06/2026
        public Task InitializeDatabaseAsync()
        {
            // Will set up SQLite Tables in Phase 2
            return Task.CompletedTask;
        }

        public Task SaveFavoriteAsync(Wallpaper wallpaper)
        {
            return Task.CompletedTask;
        }

        public Task RemoveFavoriteAsync(string id)
        {
            return Task.CompletedTask;
        }

        public Task<IEnumerable<Wallpaper>> GetFavoritesAsync()
        {
            IEnumerable<Wallpaper> favorites = new List<Wallpaper>();
            return Task.FromResult(favorites);
        }

        public Task<bool> IsFavoriteAsync(string id)
        {
            return Task.FromResult(false);
        }

        public Task SaveSearchHistoryAsync(string queryText, string filterJson)
        {
            return Task.CompletedTask;
        }

        public Task<IEnumerable<Tuple<string, string, DateTime>>> GetSearchHistoryAsync(int limit)
        {
            IEnumerable<Tuple<string, string, DateTime>> history = new List<Tuple<string, string, DateTime>>();
            return Task.FromResult(history);
        }
    }
}
