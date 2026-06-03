using System.Collections.Generic;

namespace WallhavenExplorer.Core.Models
{
    public class Wallpaper
    {
        // AkonDeV 06/2026
        public string Id { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public string Resolution { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public List<string> Tags { get; set; } = new();
        public string Uploader { get; set; } = string.Empty;
        public string ShortUrl { get; set; } = string.Empty;
    }
}
