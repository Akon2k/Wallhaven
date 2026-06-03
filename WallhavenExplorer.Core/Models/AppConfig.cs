namespace WallhavenExplorer.Core.Models
{
    public class AppConfig
    {
        // AkonDeV 06/2026
        public string ApiKey { get; set; } = string.Empty;
        public string DownloadDirectory { get; set; } = string.Empty;
        public string MobileDirectory { get; set; } = string.Empty;
        public string DefaultResizeSize { get; set; } = "1080x1920";
        public string Theme { get; set; } = "Dark";
    }
}
