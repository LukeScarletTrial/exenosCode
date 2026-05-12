using ExenosIDE.Bridge;
using ExenosIDE.Models;
using ExenosIDE.Services;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace ExenosIDE.Views;

public partial class ManagerView : ContentPage, INotifyPropertyChanged
{
    private readonly ExenosEngine _engine;
    private readonly HotReloadService _hotReloadService;
    private readonly EngineMetrics _metrics;
    private double _cRendererProgress = 1.0;
    private double _cSharpEditorProgress = 1.0;
    private string _cRendererStatus = "Metal pipeline initialized";
    private string _cSharpEditorStatus = "MAUI PlatformView embedded";

    public EngineMetrics Metrics => _metrics;

    public double CRendererProgress
    {
        get => _cRendererProgress;
        set { _cRendererProgress = value; OnPropertyChanged(); }
    }

    public double CSharpEditorProgress
    {
        get => _cSharpEditorProgress;
        set { _cSharpEditorProgress = value; OnPropertyChanged(); }
    }

    public string CRendererStatus
    {
        get => _cRendererStatus;
        set { _cRendererStatus = value; OnPropertyChanged(); }
    }

    public string CSharpEditorStatus
    {
        get => _cSharpEditorStatus;
        set { _cSharpEditorStatus = value; OnPropertyChanged(); }
    }

    public ManagerView()
    {
        InitializeComponent();
        BindingContext = this;

        _engine = ExenosEngine.Create();
        _metrics = new EngineMetrics();
        _hotReloadService = new HotReloadService(_engine);

        _hotReloadService.FileChanged += OnFileChanged;
        _hotReloadService.BytecodeReady += OnBytecodeReady;

        InitializeMetrics();
        StartRenderLoop();
    }

    private void InitializeMetrics()
    {
        _metrics.VmVersion = _engine.Version;
        _metrics.IsMetalActive = true;
        _metrics.IsHotReloadActive = false;
        _metrics.FrameRate = 60;
        _metrics.RegisteredFiles = 0;
        _metrics.LastReloadPath = "No reloads yet";
    }

    private void StartRenderLoop()
    {
        Dispatcher.StartTimer(TimeSpan.FromMilliseconds(16), () =>
        {
            _engine.Render();
            return true;
        });
    }

    private void OnFileChanged(object? sender, string path)
    {
        Dispatcher.Dispatch(() =>
        {
            _metrics.LastReloadPath = path;
            _metrics.LastReloadTime = DateTime.Now;
            _metrics.RegisteredFiles = 1;
        });
    }

    private void OnBytecodeReady(object? sender, byte[] bytecode)
    {
        Dispatcher.Dispatch(() =>
        {
            _metrics.VmVersion = _engine.Version;
        });
    }

    private void OnStartWatchClicked(object sender, EventArgs e)
    {
        try
        {
            var documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            var exenosPath = Path.Combine(documentsPath, "ExenosScripts");

            if (!Directory.Exists(exenosPath))
            {
                Directory.CreateDirectory(exenosPath);
            }

            _hotReloadService.StartWatching(exenosPath);
            _metrics.IsHotReloadActive = true;
        }
        catch (Exception ex)
        {
            DisplayAlert("Error", $"Failed to start watcher: {ex.Message}", "OK");
        }
    }

    private void OnReloadNowClicked(object sender, EventArgs e)
    {
        try
        {
            var testBytecode = new byte[] { 0x5A, 0x41, 0x55, 0x4C, 0x00, 0x01, 0x00, 0x00 };
            _engine.LoadBytecode(testBytecode);
            _metrics.VmVersion = _engine.Version;
            _metrics.LastReloadTime = DateTime.Now;
        }
        catch (Exception ex)
        {
            DisplayAlert("Error", $"Reload failed: {ex.Message}", "OK");
        }
    }

    public new event PropertyChangedEventHandler? PropertyChanged;

    protected new virtual void OnPropertyChanged([CallerMemberName] string propertyName = "")
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        _hotReloadService.StopWatching();
        _engine.Dispose();
    }
}
