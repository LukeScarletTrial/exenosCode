using Microsoft.Maui.Handlers;
using Microsoft.Maui.Platform;
using UIKit;
using CoreGraphics;

namespace ExenosIDE.Platforms.iOS;

public class ExenosMetalView : UIView
{
    public event EventHandler<CGRect>? FrameChanged;

    public override void LayoutSubviews()
    {
        base.LayoutSubviews();
        FrameChanged?.Invoke(this, Frame);
    }
}

public class ExenosMetalViewHandler : ViewHandler<ExenosIDE.Views.ManagerView, ExenosMetalView>
{
    public static IPropertyMapper<ExenosIDE.Views.ManagerView, ExenosMetalViewHandler> PropertyMapper = new PropertyMapper<ExenosIDE.Views.ManagerView, ExenosMetalViewHandler>(ViewHandler.ViewMapper);

    public ExenosMetalViewHandler() : base(PropertyMapper)
    {
    }

    protected override ExenosMetalView CreatePlatformView()
    {
        var view = new ExenosMetalView
        {
            BackgroundColor = UIColor.Clear,
            TranslatesAutoresizingMaskIntoConstraints = true
        };

        return view;
    }

    protected override void ConnectHandler(ExenosMetalView platformView)
    {
        base.ConnectHandler(platformView);
        platformView.FrameChanged += OnFrameChanged;
    }

    protected override void DisconnectHandler(ExenosMetalView platformView)
    {
        platformView.FrameChanged -= OnFrameChanged;
        base.DisconnectHandler(platformView);
    }

    private void OnFrameChanged(object? sender, CGRect frame)
    {
    }
}
