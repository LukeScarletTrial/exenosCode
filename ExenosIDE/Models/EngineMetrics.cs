using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace ExenosIDE.Models;

public class EngineMetrics : INotifyPropertyChanged
{
    private double _cpuUsage;
    private double _memoryUsage;
    private uint _vmVersion;
    private int _frameRate;
    private bool _isMetalActive;
    private bool _isHotReloadActive;
    private string _lastReloadPath = "";
    private DateTime _lastReloadTime;
    private int _registeredFiles;

    public double CpuUsage
    {
        get => _cpuUsage;
        set { _cpuUsage = value; OnPropertyChanged(); }
    }

    public double MemoryUsage
    {
        get => _memoryUsage;
        set { _memoryUsage = value; OnPropertyChanged(); }
    }

    public uint VmVersion
    {
        get => _vmVersion;
        set { _vmVersion = value; OnPropertyChanged(); }
    }

    public int FrameRate
    {
        get => _frameRate;
        set { _frameRate = value; OnPropertyChanged(); }
    }

    public bool IsMetalActive
    {
        get => _isMetalActive;
        set { _isMetalActive = value; OnPropertyChanged(); }
    }

    public bool IsHotReloadActive
    {
        get => _isHotReloadActive;
        set { _isHotReloadActive = value; OnPropertyChanged(); }
    }

    public string LastReloadPath
    {
        get => _lastReloadPath;
        set { _lastReloadPath = value; OnPropertyChanged(); }
    }

    public DateTime LastReloadTime
    {
        get => _lastReloadTime;
        set { _lastReloadTime = value; OnPropertyChanged(); }
    }

    public int RegisteredFiles
    {
        get => _registeredFiles;
        set { _registeredFiles = value; OnPropertyChanged(); }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = "")
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
