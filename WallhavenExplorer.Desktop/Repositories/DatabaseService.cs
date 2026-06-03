using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Data.Sqlite;
using Serilog;
using WallhavenExplorer.Core.Models;
using WallhavenExplorer.Core.Services;

namespace WallhavenExplorer.Desktop.Repositories
{
    public class DatabaseService : IDatabaseService
    {
        private readonly string _dbPath;
        private readonly string _connectionString;

        public DatabaseService()
        {
            // // AkonDeV 06/2026
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            _dbPath = Path.Combine(appData, "WallhavenExplorer", "localdata.db");
            _connectionString = $"Data Source={_dbPath};";
        }

        public async Task InitializeDatabaseAsync()
        {
            // // AkonDeV 06/2026
            try
            {
                string dir = Path.GetDirectoryName(_dbPath)!;
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

                using var connection = new SqliteConnection(_connectionString);
                await connection.OpenAsync();

                string createFavoritesTable = @"
                    CREATE TABLE IF NOT EXISTS Favorites (
                        Id TEXT PRIMARY KEY,
                        Url TEXT NOT NULL,
                        Path TEXT,
                        Resolution TEXT,
                        Category TEXT,
                        Tags TEXT,
                        Uploader TEXT,
                        ShortUrl TEXT,
                        SavedAt TEXT NOT NULL
                    );";

                string createHistoryTable = @"
                    CREATE TABLE IF NOT EXISTS SearchHistory (
                        Id INTEGER PRIMARY KEY AUTOINCREMENT,
                        QueryText TEXT NOT NULL,
                        FilterJson TEXT,
                        Timestamp TEXT NOT NULL
                    );";

                using var cmd1 = new SqliteCommand(createFavoritesTable, connection);
                await cmd1.ExecuteNonQueryAsync();

                using var cmd2 = new SqliteCommand(createHistoryTable, connection);
                await cmd2.ExecuteNonQueryAsync();
                
                Log.Information("Base de datos SQLite inicializada correctamente en: {Path}", _dbPath);
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error crítico al inicializar la base de datos local SQLite.");
                throw;
            }
        }

        public async Task SaveFavoriteAsync(Wallpaper wp)
        {
            // // AkonDeV 06/2026
            if (wp == null || string.IsNullOrWhiteSpace(wp.Id)) throw new ArgumentNullException(nameof(wp));

            try
            {
                using var connection = new SqliteConnection(_connectionString);
                await connection.OpenAsync();

                string query = @"
                    INSERT OR REPLACE INTO Favorites (Id, Url, Path, Resolution, Category, Tags, Uploader, ShortUrl, SavedAt)
                    VALUES (@Id, @Url, @Path, @Resolution, @Category, @Tags, @Uploader, @ShortUrl, @SavedAt);";

                using var cmd = new SqliteCommand(query, connection);
                cmd.Parameters.AddWithValue("@Id", wp.Id);
                cmd.Parameters.AddWithValue("@Url", wp.Url);
                cmd.Parameters.AddWithValue("@Path", wp.Path ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@Resolution", wp.Resolution ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@Category", wp.Category ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@Tags", string.Join(",", wp.Tags));
                cmd.Parameters.AddWithValue("@Uploader", wp.Uploader ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@ShortUrl", wp.ShortUrl ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@SavedAt", DateTime.UtcNow.ToString("o"));

                await cmd.ExecuteNonQueryAsync();
                Log.Debug("Wallpaper guardado en favoritos local: {Id}", wp.Id);
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error al guardar el favorito con ID: {Id}", wp.Id);
                throw;
            }
        }

        public async Task RemoveFavoriteAsync(string id)
        {
            // // AkonDeV 06/2026
            if (string.IsNullOrWhiteSpace(id)) return;

            using var connection = new SqliteConnection(_connectionString);
            await connection.OpenAsync();

            string query = "DELETE FROM Favorites WHERE Id = @Id;";
            using var cmd = new SqliteCommand(query, connection);
            cmd.Parameters.AddWithValue("@Id", id);

            await cmd.ExecuteNonQueryAsync();
        }

        public async Task<IEnumerable<Wallpaper>> GetFavoritesAsync()
        {
            // // AkonDeV 06/2026
            var list = new List<Wallpaper>();
            using var connection = new SqliteConnection(_connectionString);
            await connection.OpenAsync();

            string query = "SELECT Id, Url, Path, Resolution, Category, Tags, Uploader, ShortUrl FROM Favorites ORDER BY SavedAt DESC;";
            using var cmd = new SqliteCommand(query, connection);
            using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                list.Add(new Wallpaper
                {
                    Id = reader.GetString(0),
                    Url = reader.GetString(1),
                    Path = reader.IsDBNull(2) ? string.Empty : reader.GetString(2),
                    Resolution = reader.IsDBNull(3) ? string.Empty : reader.GetString(3),
                    Category = reader.IsDBNull(4) ? string.Empty : reader.GetString(4),
                    Tags = reader.IsDBNull(5) ? new List<string>() : new List<string>(reader.GetString(5).Split(',')),
                    Uploader = reader.IsDBNull(6) ? string.Empty : reader.GetString(6),
                    ShortUrl = reader.IsDBNull(7) ? string.Empty : reader.GetString(7)
                });
            }
            return list;
        }

        public async Task<bool> IsFavoriteAsync(string id)
        {
            // // AkonDeV 06/2026
            if (string.IsNullOrWhiteSpace(id)) return false;

            using var connection = new SqliteConnection(_connectionString);
            await connection.OpenAsync();

            string query = "SELECT COUNT(1) FROM Favorites WHERE Id = @Id;";
            using var cmd = new SqliteCommand(query, connection);
            cmd.Parameters.AddWithValue("@Id", id);

            var result = await cmd.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
        }

        public async Task SaveSearchHistoryAsync(string queryText, string filterJson)
        {
            // // AkonDeV 06/2026
            using var connection = new SqliteConnection(_connectionString);
            await connection.OpenAsync();

            string query = "INSERT INTO SearchHistory (QueryText, FilterJson, Timestamp) VALUES (@QueryText, @FilterJson, @Timestamp);";
            using var cmd = new SqliteCommand(query, connection);
            cmd.Parameters.AddWithValue("@QueryText", queryText ?? string.Empty);
            cmd.Parameters.AddWithValue("@FilterJson", filterJson ?? string.Empty);
            cmd.Parameters.AddWithValue("@Timestamp", DateTime.UtcNow.ToString("o"));

            await cmd.ExecuteNonQueryAsync();
        }

        public async Task<IEnumerable<Tuple<string, string, DateTime>>> GetSearchHistoryAsync(int limit)
        {
            // // AkonDeV 06/2026
            var history = new List<Tuple<string, string, DateTime>>();
            using var connection = new SqliteConnection(_connectionString);
            await connection.OpenAsync();

            string query = "SELECT QueryText, FilterJson, Timestamp FROM SearchHistory ORDER BY Id DESC LIMIT @Limit;";
            using var cmd = new SqliteCommand(query, connection);
            cmd.Parameters.AddWithValue("@Limit", limit);

            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                history.Add(Tuple.Create(
                    reader.GetString(0),
                    reader.GetString(1),
                    DateTime.Parse(reader.GetString(2))
                ));
            }
            return history;
        }
    }
}
