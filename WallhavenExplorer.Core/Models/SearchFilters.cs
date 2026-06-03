using System.Collections.Generic;

namespace WallhavenExplorer.Core.Models
{
    public class SearchFilters
    {
        // AkonDeV 06/2026
        public string Categories { get; set; } = "111"; // General/Anime/People as "111" representation
        public string Purity { get; set; } = "100";     // SFW/Sketchy/NSFW as "100" representation
        public string Sorting { get; set; } = "date_added";
        public string Order { get; set; } = "desc";
        public List<string> Colors { get; set; } = new();
        public List<string> Resolutions { get; set; } = new();
    }
}
