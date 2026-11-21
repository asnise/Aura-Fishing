# Captures the Roblox Studio window (Windows only) for the capture_ui tool.
#   -Mode find : grab the window, locate the solid #FF00FF calibration marker, print JSON
#                { hwnd, method, window:{x,y,w,h}, marker:{x,y,w,h,count} }
#   -Mode crop : grab the window again (same -Hwnd/-Method) and save the -X/-Y/-W/-H crop (bitmap pixels) to -Out
# Method "print" = PrintWindow(PW_RENDERFULLCONTENT) (works when Studio is covered), "screen" = bring to front + CopyFromScreen.
param(
  [ValidateSet("find", "crop")] [string]$Mode = "find",
  [string]$Title = "",
  [Int64]$Hwnd = 0,
  [string]$Method = "auto",
  [int]$X = 0, [int]$Y = 0, [int]$W = 0, [int]$H = 0,
  [string]$Out = "",
  [string]$Debug = ""
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

if (-not ("StudioCap" -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;

public static class StudioCap {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] static extern IntPtr SetProcessDpiAwarenessContext(IntPtr ctx);
  [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);

  public static void DpiAware() { try { SetProcessDpiAwarenessContext(new IntPtr(-4)); } catch {} }

  public static string Title(IntPtr h) { var sb = new StringBuilder(512); GetWindowText(h, sb, 512); return sb.ToString(); }

  // Visible top-level windows of RobloxStudioBeta; prefer one whose title contains `want`, else the largest.
  public static IntPtr Find(string want) {
    var pids = new HashSet<uint>();
    foreach (var p in Process.GetProcessesByName("RobloxStudioBeta")) pids.Add((uint)p.Id);
    IntPtr best = IntPtr.Zero; long bestArea = -1; IntPtr titled = IntPtr.Zero;
    EnumWindows((h, l) => {
      uint pid; GetWindowThreadProcessId(h, out pid);
      if (!pids.Contains(pid) || !IsWindowVisible(h)) return true;
      var t = Title(h);
      if (t.Length == 0) return true;
      RECT r = Rect(h);
      long area = (long)(r.Right - r.Left) * (r.Bottom - r.Top);
      if (!string.IsNullOrEmpty(want) && t.IndexOf(want, StringComparison.OrdinalIgnoreCase) >= 0 && titled == IntPtr.Zero) titled = h;
      if (area > bestArea) { bestArea = area; best = h; }
      return true;
    }, IntPtr.Zero);
    return titled != IntPtr.Zero ? titled : best;
  }

  public static RECT Rect(IntPtr h) {
    RECT r;
    if (DwmGetWindowAttribute(h, 9 /*DWMWA_EXTENDED_FRAME_BOUNDS*/, out r, Marshal.SizeOf(typeof(RECT))) != 0) GetWindowRect(h, out r);
    return r;
  }

  public static Bitmap Print(IntPtr h) {
    RECT r; GetWindowRect(h, out r);
    var bmp = new Bitmap(r.Right - r.Left, r.Bottom - r.Top, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(bmp)) {
      IntPtr hdc = g.GetHdc();
      PrintWindow(h, hdc, 2 /*PW_RENDERFULLCONTENT*/);
      g.ReleaseHdc(hdc);
    }
    // PrintWindow draws the full window rect; trim to the visible frame so coords match Rect().
    RECT f = Rect(h);
    int dx = f.Left - r.Left, dy = f.Top - r.Top, fw = f.Right - f.Left, fh = f.Bottom - f.Top;
    if (dx == 0 && dy == 0 && fw == bmp.Width && fh == bmp.Height) return bmp;
    var trimmed = bmp.Clone(new Rectangle(dx, dy, Math.Min(fw, bmp.Width - dx), Math.Min(fh, bmp.Height - dy)), PixelFormat.Format32bppArgb);
    bmp.Dispose();
    return trimmed;
  }

  public static void Front(IntPtr h) {
    if (IsIconic(h)) ShowWindow(h, 9 /*SW_RESTORE*/);
    keybd_event(0x12, 0, 0, UIntPtr.Zero); keybd_event(0x12, 0, 2, UIntPtr.Zero); // ALT tap lets us take focus
    SetForegroundWindow(h);
  }

  public static Bitmap Screen(IntPtr h) {
    RECT r = Rect(h);
    var bmp = new Bitmap(r.Right - r.Left, r.Bottom - r.Top, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(bmp)) g.CopyFromScreen(r.Left, r.Top, 0, 0, bmp.Size);
    return bmp;
  }

  // Bounding box of near-#FF00FF pixels: {minX, minY, maxX, maxY, count} or null.
  public static int[] Marker(Bitmap b) {
    var data = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int stride = data.Stride; var px = new byte[stride * b.Height];
    Marshal.Copy(data.Scan0, px, 0, px.Length); b.UnlockBits(data);
    int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1, count = 0;
    for (int y = 0; y < b.Height; y++) {
      int row = y * stride;
      for (int x = 0; x < b.Width; x++) {
        int i = row + x * 4; // BGRA
        if (px[i + 2] >= 245 && px[i] >= 245 && px[i + 1] <= 10) {
          count++;
          if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y;
        }
      }
    }
    return count == 0 ? null : new int[] { minX, minY, maxX, maxY, count };
  }
}
"@
}

[StudioCap]::DpiAware()

function Grab([IntPtr]$hw, [string]$m) {
  if ($m -eq "screen") {
    [StudioCap]::Front($hw)
    Start-Sleep -Milliseconds 350
    return [StudioCap]::Screen($hw)
  }
  return [StudioCap]::Print($hw)
}

function Json($o) { $o | ConvertTo-Json -Compress -Depth 5 }

if ($Mode -eq "find") {
  $win = [StudioCap]::Find($Title)
  if ($win -eq [IntPtr]::Zero) { throw "Roblox Studio window not found" }
  if ([StudioCap]::IsIconic($win)) { [StudioCap]::Front($win); Start-Sleep -Milliseconds 400 }
  $r = [StudioCap]::Rect($win)
  $methods = if ($Method -eq "auto") { @("print", "screen") } else { @($Method) }
  foreach ($m in $methods) {
    $bmp = Grab $win $m
    if ($Debug) { $bmp.Save("$Debug.$m.png", [System.Drawing.Imaging.ImageFormat]::Png) }
    $mk = [StudioCap]::Marker($bmp)
    $bmp.Dispose()
    if ($mk) {
      Json @{ hwnd = [Int64]$win; method = $m; title = [StudioCap]::Title($win)
        window = @{ x = $r.Left; y = $r.Top; w = $r.Right - $r.Left; h = $r.Bottom - $r.Top }
        marker = @{ x = $mk[0]; y = $mk[1]; w = $mk[2] - $mk[0] + 1; h = $mk[3] - $mk[1] + 1; count = $mk[4] } }
      exit 0
    }
  }
  throw "Calibration marker not visible in the Studio window. Show the 3D viewport (not a script tab) and make sure Studio is not minimized."
}

# crop
$win = [IntPtr]$Hwnd
$bmp = Grab $win $Method
$x0 = [Math]::Max(0, $X); $y0 = [Math]::Max(0, $Y)
$x1 = [Math]::Min($bmp.Width, $X + $W); $y1 = [Math]::Min($bmp.Height, $Y + $H)
if ($x1 -le $x0 -or $y1 -le $y0) { throw "Target is outside the Studio window ($X,$Y ${W}x$H vs window $($bmp.Width)x$($bmp.Height))" }
$crop = $bmp.Clone((New-Object System.Drawing.Rectangle $x0, $y0, ($x1 - $x0), ($y1 - $y0)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
$crop.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
Json @{ out = (Resolve-Path $Out).Path; x = $x0; y = $y0; w = $x1 - $x0; h = $y1 - $y0; clipped = ($x0 -ne $X -or $y0 -ne $Y -or ($x1 - $x0) -ne $W -or ($y1 - $y0) -ne $H); bitmap = @{ w = $bmp.Width; h = $bmp.Height } }
$crop.Dispose(); $bmp.Dispose()
