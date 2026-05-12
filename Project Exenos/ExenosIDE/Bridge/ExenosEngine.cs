using System.Runtime.InteropServices;

namespace ExenosIDE.Bridge;

public class ExenosEngine : IDisposable
{
    private IntPtr _vmHandle;
    private IntPtr _metalHandle;
    private IntPtr _reloadHandle;
    private bool _disposed;

    public IntPtr VmHandle => _vmHandle;
    public IntPtr MetalHandle => _metalHandle;
    public IntPtr ReloadHandle => _reloadHandle;
    public uint Version => _vmHandle != IntPtr.Zero ? ExenosNativeBridge.exenos_vm_get_version(_vmHandle) : 0;

    public static ExenosEngine Create()
    {
        var engine = new ExenosEngine();
        engine.Initialize();
        return engine;
    }

    private void Initialize()
    {
        _vmHandle = ExenosNativeBridge.exenos_vm_create();
        if (_vmHandle == IntPtr.Zero)
        {
            throw new InvalidOperationException("Failed to create Exenos VM");
        }
    }

    public void AttachMetalView(IntPtr nativeViewHandle)
    {
        if (_metalHandle != IntPtr.Zero)
        {
            ExenosNativeBridge.exenos_metal_destroy(_metalHandle);
        }

        _metalHandle = ExenosNativeBridge.exenos_metal_create(nativeViewHandle);
        if (_metalHandle == IntPtr.Zero)
        {
            throw new InvalidOperationException("Failed to create Metal context");
        }
    }

    public void InitializeHotReload()
    {
        if (_reloadHandle != IntPtr.Zero)
        {
            ExenosNativeBridge.exenos_reload_destroy(_reloadHandle);
        }

        _reloadHandle = ExenosNativeBridge.exenos_reload_create(_vmHandle);
        if (_reloadHandle == IntPtr.Zero)
        {
            throw new InvalidOperationException("Failed to create hot reload context");
        }

        var result = ExenosNativeBridge.exenos_reload_start_monitor(_reloadHandle);
        if (result != 0)
        {
            throw new InvalidOperationException($"Failed to start hot reload monitor: {result}");
        }
    }

    public void LoadBytecode(byte[] bytecode)
    {
        if (_vmHandle == IntPtr.Zero)
        {
            throw new InvalidOperationException("VM not initialized");
        }

        var result = ExenosNativeBridge.exenos_vm_load_bytecode(_vmHandle, bytecode, (nuint)bytecode.Length);
        if (result != 0)
        {
            throw new InvalidOperationException($"Failed to load bytecode: {result}");
        }
    }

    public void HotReload(byte[] bytecode)
    {
        if (_reloadHandle == IntPtr.Zero)
        {
            throw new InvalidOperationException("Hot reload not initialized");
        }

        var result = ExenosNativeBridge.exenos_reload_push_bytecode(_reloadHandle, bytecode, (nuint)bytecode.Length);
        if (result != 0)
        {
            throw new InvalidOperationException($"Failed to push bytecode: {result}");
        }
    }

    public void Render()
    {
        if (_metalHandle == IntPtr.Zero || _vmHandle == IntPtr.Zero)
        {
            return;
        }

        ExenosNativeBridge.exenos_metal_render(_metalHandle, _vmHandle);
    }

    public void Dispose()
    {
        if (_disposed) return;

        if (_reloadHandle != IntPtr.Zero)
        {
            ExenosNativeBridge.exenos_reload_stop_monitor(_reloadHandle);
            ExenosNativeBridge.exenos_reload_destroy(_reloadHandle);
            _reloadHandle = IntPtr.Zero;
        }

        if (_metalHandle != IntPtr.Zero)
        {
            ExenosNativeBridge.exenos_metal_destroy(_metalHandle);
            _metalHandle = IntPtr.Zero;
        }

        if (_vmHandle != IntPtr.Zero)
        {
            ExenosNativeBridge.exenos_vm_destroy(_vmHandle);
            _vmHandle = IntPtr.Zero;
        }

        _disposed = true;
        GC.SuppressFinalize(this);
    }

    ~ExenosEngine()
    {
        Dispose();
    }
}
