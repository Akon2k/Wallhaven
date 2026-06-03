using System;
using System.Windows;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using WallhavenExplorer.Core.Services;

namespace WallhavenExplorer.Desktop
{
    public partial class App : Application
    {
        // AkonDeV 06/2026
        public static IHost? AppHost { get; private set; }

        public App()
        {
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Debug()
                .WriteTo.File("logs/runtime_log.txt", rollingInterval: RollingInterval.Day)
                .CreateLogger();

            AppHost = Host.CreateDefaultBuilder()
                .ConfigureServices((context, services) =>
                {
                    // Infraestructura de Red
                    services.AddHttpClient("WallhavenClient", client =>
                    {
                        client.BaseAddress = new Uri("https://wallhaven.cc/api/v1/");
                        client.DefaultRequestHeaders.Add("User-Agent", "WallhavenExplorer-AkonDeV-06-2026");
                    });

                    // Servicios Core
                    services.AddSingleton<IDatabaseService, Repositories.DatabaseService>();
                    services.AddSingleton<IImageProcessorService, Services.ImageProcessorService>();
                    services.AddSingleton<IWallhavenService, Services.WallhavenService>();

                    // UI / MVVM
                    services.AddSingleton<ViewModels.MainViewModel>();
                    services.AddSingleton<ViewModels.SettingsViewModel>();
                    services.AddSingleton<Views.MainWindow>();
                    services.AddTransient<Views.SettingsWindow>();
                })
                .UseSerilog()
                .Build();
        }

        protected override async void OnStartup(StartupEventArgs e)
        {
            await AppHost!.StartAsync();
            
            var dbService = AppHost.Services.GetRequiredService<IDatabaseService>();
            await dbService.InitializeDatabaseAsync();

            var mainWindow = AppHost.Services.GetRequiredService<Views.MainWindow>();
            mainWindow.Show();

            base.OnStartup(e);
        }

        protected override async void OnExit(ExitEventArgs e)
        {
            await AppHost!.StopAsync();
            Log.CloseAndFlush();
            base.OnExit(e);
        }
    }
}
