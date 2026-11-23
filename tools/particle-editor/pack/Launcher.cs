using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: System.Reflection.AssemblyTitle("Aura Particle Editor")]

internal static class Launcher
{
    private const string Title = "Aura Particle Editor";
    private const string UrlPrefix = "VFX_EDITOR_URL=";

    [STAThread]
    private static void Main(string[] arguments)
    {
        try
        {
            Launch(arguments);
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, Title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private static void Launch(string[] arguments)
    {
        if (arguments.Length > 1) throw new ArgumentException("Pass a single particle project JSON file.");

        string install = AppDomain.CurrentDomain.BaseDirectory;
        string server = Path.Combine(install, "app", "server", "server.js");
        if (!File.Exists(server)) throw new FileNotFoundException("The editor's app folder must be beside AuraParticleEditor.exe.");

        string nodePath = FirstExisting(
            Path.Combine(install, "node.exe"),
            AppPath("node.exe"),
            NodeOnPath(),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "nodejs", "node.exe"));
        if (nodePath == null) throw new FileNotFoundException("Install Node.js 22 or place node.exe beside AuraParticleEditor.exe.");

        string workspace = FindWorkspace(install) ?? FindWorkspace(Environment.CurrentDirectory) ?? Environment.CurrentDirectory;
        string command = Quote(server) + " --desktop --workspace " + Quote(workspace);
        if (arguments.Length == 1) command += " --file " + Quote(Path.GetFullPath(arguments[0]));

        using (var ready = new ManualResetEventSlim())
        using (var node = new Process())
        {
            string url = null;
            var errors = new StringBuilder();
            node.StartInfo = new ProcessStartInfo(nodePath, command) {
                WorkingDirectory = workspace,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            node.EnableRaisingEvents = true;
            node.Exited += delegate { ready.Set(); };
            node.OutputDataReceived += delegate(object sender, DataReceivedEventArgs data) {
                if (data.Data == null || !data.Data.StartsWith(UrlPrefix, StringComparison.Ordinal)) return;
                string value = data.Data.Substring(UrlPrefix.Length);
                Uri address;
                if (Uri.TryCreate(value, UriKind.Absolute, out address) && address.Scheme == "http" && address.Host == "127.0.0.1")
                {
                    url = value;
                    ready.Set();
                }
            };
            node.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs data) {
                if (data.Data == null) return;
                lock (errors) {
                    if (errors.Length < 1200) errors.AppendLine(data.Data);
                }
            };

            node.Start();
            node.BeginOutputReadLine();
            node.BeginErrorReadLine();
            try
            {
                if (!ready.Wait(TimeSpan.FromSeconds(15)) || url == null || node.HasExited)
                {
                    if (node.HasExited) node.WaitForExit();
                    lock (errors) throw new InvalidOperationException("The Node.js editor server could not start.\n\n" + errors.ToString().Trim());
                }
                OpenBrowser(url);
                node.WaitForExit();
            }
            finally
            {
                if (!node.HasExited) {
                    node.Kill();
                    node.WaitForExit();
                }
            }
        }
    }

    private static void OpenBrowser(string url)
    {
        string localApps = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string programs = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        string programs32 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
        string edge = FirstExisting(
            AppPath("msedge.exe"),
            Path.Combine(programs32, "Microsoft", "Edge", "Application", "msedge.exe"),
            Path.Combine(programs, "Microsoft", "Edge", "Application", "msedge.exe"));
        string chrome = FirstExisting(
            AppPath("chrome.exe"),
            Path.Combine(programs, "Google", "Chrome", "Application", "chrome.exe"),
            Path.Combine(programs32, "Google", "Chrome", "Application", "chrome.exe"),
            Path.Combine(localApps, "Google", "Chrome", "Application", "chrome.exe"));
        string profile = Environment.GetEnvironmentVariable("AURA_PARTICLE_EDITOR_BROWSER_PROFILE");
        if (String.IsNullOrWhiteSpace(profile)) profile = Path.Combine(localApps, "AuraParticleEditor", "Browser");
        profile = Path.GetFullPath(profile);
        foreach (string browser in new[] { edge, chrome })
        {
            if (browser == null) continue;
            string command = "--app=" + Quote(url) + " --user-data-dir=" + Quote(profile)
                + " --no-first-run --no-default-browser-check --disable-background-networking --disable-sync";
            try
            {
                Process.Start(new ProcessStartInfo(browser, command) { UseShellExecute = false }).Dispose();
                return;
            }
            catch (System.ComponentModel.Win32Exception)
            {
                // Try another browser if Windows cannot start this one.
            }
        }
        Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
    }

    private static string FindWorkspace(string path)
    {
        for (var directory = new DirectoryInfo(path); directory != null; directory = directory.Parent)
        {
            if (File.Exists(Path.Combine(directory.FullName, "default.project.json"))) return directory.FullName;
        }
        return null;
    }

    private static string AppPath(string executable)
    {
        string key = @"Software\Microsoft\Windows\CurrentVersion\App Paths\" + executable;
        foreach (RegistryKey root in new[] { Registry.CurrentUser, Registry.LocalMachine })
        {
            using (RegistryKey app = root.OpenSubKey(key))
            {
                string path = app == null ? null : app.GetValue(null) as string;
                if (!String.IsNullOrWhiteSpace(path) && File.Exists(path.Trim('"'))) return path.Trim('"');
            }
        }
        return null;
    }

    private static string NodeOnPath()
    {
        foreach (string entry in (Environment.GetEnvironmentVariable("PATH") ?? "").Split(';'))
        {
            string directory = entry.Trim().Trim('"');
            if (!Path.IsPathRooted(directory)) continue;
            string node = Path.Combine(directory, "node.exe");
            if (File.Exists(node)) return node;
        }
        return null;
    }

    private static string FirstExisting(params string[] paths)
    {
        foreach (string path in paths) if (File.Exists(path)) return path;
        return null;
    }

    private static string Quote(string argument)
    {
        var quoted = new StringBuilder("\"");
        int slashes = 0;
        foreach (char character in argument)
        {
            if (character == '\\') {
                slashes++;
                continue;
            }
            quoted.Append('\\', character == '"' ? slashes * 2 + 1 : slashes);
            quoted.Append(character);
            slashes = 0;
        }
        return quoted.Append('\\', slashes * 2).Append('"').ToString();
    }
}
