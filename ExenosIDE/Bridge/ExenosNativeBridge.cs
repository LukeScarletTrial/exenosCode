using System.Runtime.InteropServices;

namespace ExenosIDE.Bridge;

public static class ExenosNativeBridge
{
    private const string DllName = "libexenos.dylib";

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr exenos_vm_create();

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void exenos_vm_destroy(IntPtr handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int exenos_vm_load_bytecode(IntPtr handle, byte[] data, nuint len);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int exenos_vm_hot_reload(IntPtr handle, byte[] data, nuint len);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void exenos_vm_execute(IntPtr handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint exenos_vm_get_version(IntPtr handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr exenos_metal_create(IntPtr nativeView);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void exenos_metal_destroy(IntPtr handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int exenos_metal_render(IntPtr handle, IntPtr vm);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int exenos_metal_create_buffer(IntPtr handle, nuint size, uint flags, out IntPtr outBuffer);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void exenos_metal_destroy_buffer(IntPtr buffer);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int exenos_metal_create_texture(IntPtr handle, uint width, uint height, out IntPtr outTexture);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void exenos_metal_destroy_texture(IntPtr texture);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void exenos_metal_present(IntPtr handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr exenos_reload_create(IntPtr vm);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void exenos_reload_destroy(IntPtr handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int exenos_reload_push_bytecode(IntPtr handle, byte[] data, nuint len);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int exenos_reload_start_monitor(IntPtr handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void exenos_reload_stop_monitor(IntPtr handle);
}
