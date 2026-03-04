---
name: dotnet-desktop
version: 1.0
description: .NET desktop applications (WPF, WinForms, MAUI)
requires: []
winget:
  - id: Microsoft.DotNet.SDK.9
    check: dotnet
vscode-extensions:
  - ms-dotnettools.csdevkit
  - ms-dotnettools.csharp
claude-skills:
  - windows-development
---

# .NET Desktop Profile

Use this profile for .NET desktop applications targeting Windows. This includes WPF, WinForms, and MAUI projects.

## When to Use This

- WPF applications (XAML + C#)
- WinForms applications
- .NET MAUI desktop apps
- Any .NET project with a Windows desktop UI

## Project Structure

A typical .NET desktop project with solution structure:

```text
MyApp/
├── src/
│   ├── MyApp/                   # Main WPF/WinForms project
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── App.xaml
│   │   └── MyApp.csproj
│   └── MyApp.Core/              # Cross-platform core library
│       └── MyApp.Core.csproj
├── tests/
│   └── MyApp.Core.Tests/        # Cross-platform test project
│       └── MyApp.Core.Tests.csproj
├── MyApp.sln
├── VERSION
└── CHANGELOG.md
```

## CI Limitation: WPF on Linux Runners

WPF and WinForms projects target `net9.0-windows` and cannot build on Linux CI runners. The `dotnet restore` step fails with `NETSDK1100: To build a project targeting Windows on this operating system, set EnableWindowsTargeting to true`.

**Solution**: Scope CI `dotnet restore`, `dotnet build`, and `dotnet test` to cross-platform `.csproj` files only (see known-gotchas KG#88):

```yaml
# Scope to cross-platform test projects
- run: dotnet restore tests/MyApp.Core.Tests/MyApp.Core.Tests.csproj
- run: dotnet test tests/MyApp.Core.Tests/MyApp.Core.Tests.csproj --no-restore
```

Use `project-templates/ci-dotnet.yml` which implements this pattern. Replace `{{PROJECT_NAME}}` with your project name.

## Architecture Recommendation

Separate platform-dependent UI code from cross-platform business logic:

- **MyApp.Core** (cross-platform) -- models, services, business logic, interfaces
- **MyApp** (Windows-only) -- WPF views, XAML, platform-specific implementations

This lets you test all business logic in CI on Linux runners while the WPF project only builds locally on Windows.

## Code Analysis

### StyleCop

Add StyleCop for code style enforcement:

```xml
<!-- In .csproj -->
<ItemGroup>
  <PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.435" PrivateAssets="all" />
</ItemGroup>
```

Configure rules in `.editorconfig` or `stylecop.json`.

### Built-in Analyzers

Enable strict analysis in the project file:

```xml
<PropertyGroup>
  <AnalysisLevel>latest-all</AnalysisLevel>
  <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  <Nullable>enable</Nullable>
</PropertyGroup>
```

## Building

WPF projects only build on Windows:

```bash
# Local (Windows only)
dotnet build
dotnet run --project src/MyApp/MyApp.csproj

# Cross-platform core
dotnet build src/MyApp.Core/MyApp.Core.csproj
dotnet test tests/MyApp.Core.Tests/MyApp.Core.Tests.csproj
```

## Testing

```bash
# Cross-platform tests (works everywhere)
dotnet test tests/MyApp.Core.Tests/MyApp.Core.Tests.csproj

# All tests (Windows only)
dotnet test
```

Use xUnit or NUnit for test projects. Keep UI tests (if any) in a separate Windows-only test project.

## VS Code Extensions

- **ms-dotnettools.csdevkit** -- C# Dev Kit with solution explorer, test runner
- **ms-dotnettools.csharp** -- C# language support, OmniSharp

For full WPF designer support, Visual Studio (not VS Code) is recommended.

## Related Profiles

- **react-frontend** -- if you need a web frontend alongside the desktop app
