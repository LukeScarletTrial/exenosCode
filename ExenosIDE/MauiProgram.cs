using Microsoft.Maui.Controls.Compatibility.Platform.iOS;

namespace ExenosIDE;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("SF-Pro.ttf", "SFPro");
                fonts.AddFont("SF-Mono.ttf", "SFMono");
            });

        return builder.Build();
    }
}
