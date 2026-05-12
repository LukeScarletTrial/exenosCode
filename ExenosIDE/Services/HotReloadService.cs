namespace ExenosIDE.Services;

public class HotReloadService
{
    private readonly ExenosEngine _engine;
    private FileSystemWatcher? _watcher;
    private string? _watchPath;
    private readonly DebounceTimer _debouncer;

    public event EventHandler<string>? FileChanged;
    public event EventHandler<byte[]>? BytecodeReady;

    public bool IsWatching => _watcher?.EnableRaisingEvents ?? false;

    public HotReloadService(ExenosEngine engine)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));
        _debouncer = new DebounceTimer(TimeSpan.FromMilliseconds(100), OnDebounceElapsed);
    }

    public void StartWatching(string path, string filter = "*.luaz")
    {
        if (!Directory.Exists(path))
        {
            throw new DirectoryNotFoundException($"Path not found: {path}");
        }

        StopWatching();

        _watchPath = path;
        _watcher = new FileSystemWatcher(path, filter)
        {
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.CreationTime,
            IncludeSubdirectories = true,
            EnableRaisingEvents = true
        };

        _watcher.Changed += OnFileChanged;
        _watcher.Created += OnFileChanged;
        _watcher.Renamed += OnFileRenamed;

        _engine.InitializeHotReload();
    }

    public void StopWatching()
    {
        if (_watcher != null)
        {
            _watcher.EnableRaisingEvents = false;
            _watcher.Changed -= OnFileChanged;
            _watcher.Created -= OnFileChanged;
            _watcher.Renamed -= OnFileRenamed;
            _watcher.Dispose();
            _watcher = null;
        }

        _debouncer.Stop();
    }

    private void OnFileChanged(object sender, FileSystemEventArgs e)
    {
        if (e.FullPath.EndsWith(".luaz"))
        {
            _debouncer.Trigger(e.FullPath);
        }
    }

    private void OnFileRenamed(object sender, RenamedEventArgs e)
    {
        if (e.FullPath.EndsWith(".luaz"))
        {
            _debouncer.Trigger(e.FullPath);
        }
    }

    private void OnDebounceElapsed(string path)
    {
        try
        {
            FileChanged?.Invoke(this, path);

            var bytes = File.ReadAllBytes(path);
            BytecodeReady?.Invoke(this, bytes);

            _engine.HotReload(bytes);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Hot reload error: {ex}");
        }
    }
}

public class DebounceTimer
{
    private readonly TimeSpan _delay;
    private readonly Action<string> _callback;
    private CancellationTokenSource? _cts;

    public DebounceTimer(TimeSpan delay, Action<string> callback)
    {
        _delay = delay;
        _callback = callback;
    }

    public void Trigger(string data)
    {
        _cts?.Cancel();
        _cts = new CancellationTokenSource();

        var token = _cts.Token;
        Task.Run(async () =>
        {
            await Task.Delay(_delay, token);
            if (!token.IsCancellationRequested)
            {
                _callback(data);
            }
        }, token);
    }

    public void Stop()
    {
        _cts?.Cancel();
        _cts = null;
    }
}
