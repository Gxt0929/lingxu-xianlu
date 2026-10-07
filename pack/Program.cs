using System;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

class Program
{
    static Form form;
    static WebView2 wv;
    static bool isFull = true;

    [DllImport("user32.dll")]
    private static extern bool SetProcessDPIAware();

    [STAThread]
    static void Main()
    {
        SetProcessDPIAware();
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        // 游戏文件释放目录（存档由 WebView2 UserData 持久保存，与此目录分离）
        string dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "LingXuXianLu");
        Directory.CreateDirectory(dir);
        string htmlPath = Path.Combine(dir, "index.html");
        using (Stream src = Assembly.GetExecutingAssembly()
            .GetManifestResourceStream("game.index.html"))
        using (FileStream fs = File.Create(htmlPath))
        {
            src.CopyTo(fs);
        }

        form = new Form();
        form.Text = "灵墟·修仙录";
        form.MinimumSize = new Size(380, 600);
        form.StartPosition = FormStartPosition.CenterScreen;
        try
        {
            using (Stream icoStream = Assembly.GetExecutingAssembly()
                .GetManifestResourceStream("game.app.ico"))
            {
                form.Icon = new Icon(icoStream);
            }
        }
        catch { }

        // 启动即全屏（无边框铺满整屏）；F11/ESC 由页面内监听后经 WebMessage 转发
        ApplyFullscreen(true);

        wv = new WebView2();
        wv.Dock = DockStyle.Fill;
        CoreWebView2CreationProperties props = new CoreWebView2CreationProperties();
        props.UserDataFolder = Path.Combine(dir, "UserData");
        wv.CreationProperties = props;
        wv.CoreWebView2InitializationCompleted += delegate(object sender,
            CoreWebView2InitializationCompletedEventArgs e)
        {
            wv.CoreWebView2.SetVirtualHostNameToFolderMapping(
                "app.local", dir, CoreWebView2HostResourceAccessKind.Allow);
            wv.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
            wv.CoreWebView2.Settings.IsZoomControlEnabled = false;
            wv.CoreWebView2.Settings.IsStatusBarEnabled = false;
            // 接收页面转发的「切换全屏」（F11/ESC/设置按钮统一走这里）
            wv.CoreWebView2.WebMessageReceived += delegate(object ws,
                CoreWebView2WebMessageReceivedEventArgs we)
            {
                string msg;
                try { msg = we.TryGetWebMessageAsString(); } catch { msg = ""; }
                if (msg == "fs:toggle") ToggleFull();
            };
            SyncFullFlag();
        };
        wv.Source = new Uri("https://app.local/index.html");
        form.Controls.Add(wv);

        Application.Run(form);
    }

    static void ToggleFull()
    {
        ApplyFullscreen(!isFull);
    }

    static void ApplyFullscreen(bool full)
    {
        isFull = full;
        if (full)
        {
            if (form.WindowState == FormWindowState.Maximized)
            {
                form.WindowState = FormWindowState.Normal; // 先还原才能改边框
            }
            form.FormBorderStyle = FormBorderStyle.None;
            form.WindowState = FormWindowState.Maximized;
        }
        else
        {
            form.WindowState = FormWindowState.Normal;
            form.FormBorderStyle = FormBorderStyle.Sizable;
            Rectangle wa = Screen.PrimaryScreen.WorkingArea;
            int w = Math.Min(540, wa.Width - 40);
            int h = Math.Min(880, wa.Height - 40);
            form.Size = new Size(w + 16, h + 39); // ClientSize + 边框/标题栏
            form.Location = new Point(
                wa.Left + (wa.Width - form.Width) / 2,
                wa.Top + (wa.Height - form.Height) / 2);
        }
        SyncFullFlag();
    }

    // 把当前全屏状态同步给页面（页面据此决定 ESC 行为）
    static void SyncFullFlag()
    {
        try
        {
            if (wv != null && wv.CoreWebView2 != null)
            {
                wv.CoreWebView2.ExecuteScriptAsync(
                    "window.__hostFull=" + (isFull ? "true" : "false") + ";void 0;");
            }
        }
        catch { }
    }
}
