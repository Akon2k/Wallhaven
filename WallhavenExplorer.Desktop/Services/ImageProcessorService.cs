using System;
using System.IO;
using System.Threading.Tasks;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using WallhavenExplorer.Core.Services;
using Serilog;

namespace WallhavenExplorer.Desktop.Services
{
    public class ImageProcessorService : IImageProcessorService
    {
        public async Task ProcessMobileResizeAsync(string sourcePath, string targetPath, int width, int height, Core.Services.ResizeMode mode)
        {
            // // AkonDeV 06/2026
            if (!File.Exists(sourcePath)) throw new FileNotFoundException("Imagen origen inexistente.", sourcePath);

            await Task.Run(() =>
            {
                using var image = Image.Load(sourcePath);

                switch (mode)
                {
                    case Core.Services.ResizeMode.SmartCropCentred:
                        image.Mutate(x => x.Resize(new ResizeOptions
                        {
                            Size = new Size(width, height),
                            Mode = SixLabors.ImageSharp.Processing.ResizeMode.Crop,
                            Position = AnchorPositionMode.Center
                        }));
                        break;

                    case Core.Services.ResizeMode.LetterboxBlack:
                        image.Mutate(x => x.Resize(new ResizeOptions
                        {
                            Size = new Size(width, height),
                            Mode = SixLabors.ImageSharp.Processing.ResizeMode.Pad,
                            PadColor = Color.Black
                        }));
                        break;

                    case Core.Services.ResizeMode.ScaleMaintainAspect:
                        image.Mutate(x => x.Resize(new ResizeOptions
                        {
                            Size = new Size(width, height),
                            Mode = SixLabors.ImageSharp.Processing.ResizeMode.Max
                        }));
                        break;

                    default:
                        throw new ArgumentOutOfRangeException(nameof(mode), "Modo de redimensionamiento no soportado.");
                }

                string? directory = Path.GetDirectoryName(targetPath);
                if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                image.Save(targetPath);
                Log.Information("Imagen redimensionada con éxito en modo {Mode} hacia {Target}", mode, targetPath);
            });
        }
    }
}
