# Exenos Code

Professional-grade iOS game engine and IDE with hybrid C/C# architecture.

## Architecture

- **Engine Core (C)**: High-performance luaZ scripting runtime with Metal rendering
- **IDE Frontend (C#/.NET MAUI)**: Glassmorphic interface with hot-reload integration
- **P/Invoke Bridge**: Seamless C# to C interop for real-time engine control

## luaZ Runtime

Performance-optimized Lua variant with:
- Static-typing annotations at bytecode level
- ARM64 register-optimized memory pool (X0-X28 allocation)
- Zero-copy hot-reloading via POSIX shared memory
- Metal FFI bindings for GPU compute

## Build Requirements

- Xcode 15.2+
- .NET 8.0 SDK
- iOS 15.0+ deployment target
- ARM64 hardware (iPhone 11 or later, iPad Pro)

## Quick Start

```bash
cd ExenosEngine
make
cd ../ExenosIDE
dotnet build -f net8.0-ios -c Release
```

## GitHub Actions

ARM64 CI pipeline at `.github/workflows/ios-arm64.yml`:
- Compiles C binaries
- Binds MAUI assets
- Outputs signed .ipa

Configure signing secrets:
- `EXENOS_CERTIFICATE_BASE64`
- `EXENOS_CERTIFICATE_PASSWORD`
- `EXENOS_PROVISIONING_PROFILE`

## UI Theme: Antigravity

Deep translucency, heavy blur glassmorphism, weightless borderless aesthetic with neon accent highlights:
- Background: `#0A0A0F`
- Surface: `#161622` with `#2A2A3A` borders
- Neon Cyan: `#00F0FF`
- Neon Magenta: `#FF5A8C`
- Neon Violet: `#8C5AFF`

## License

Copyright (c) 2024 Exenos Inc.
