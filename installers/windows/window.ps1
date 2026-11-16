# The installer's window: what the installer says, as it says it, then a popup when it is done.
# Run by the Windows download (main.go) with the app's name, the log it writes and the file it writes the
# installer's exit code to when the installer finishes. Plain ASCII on purpose.
param([string]$App, [string]$Log, [string]$Status, [string]$Icon)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Installing $App"
$form.Width = 780
$form.Height = 500
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(244, 241, 234)
try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon) } catch {}

$head = New-Object System.Windows.Forms.Label
$head.Text = "Installing $App. This shows what the installer is doing; it can take a few minutes."
$head.Dock = 'Top'
$head.Height = 40
$head.Padding = New-Object System.Windows.Forms.Padding(12, 12, 12, 0)
$head.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$box = New-Object System.Windows.Forms.TextBox
$box.Multiline = $true
$box.ReadOnly = $true
$box.ScrollBars = 'Vertical'
$box.WordWrap = $true
$box.Dock = 'Fill'
$box.BorderStyle = 'None'
$box.BackColor = [System.Drawing.Color]::White
$box.Font = New-Object System.Drawing.Font('Consolas', 10)

$pad = New-Object System.Windows.Forms.Panel
$pad.Dock = 'Fill'
$pad.Padding = New-Object System.Windows.Forms.Padding(12, 6, 12, 12)
$pad.Controls.Add($box)
$form.Controls.Add($pad)
$form.Controls.Add($head)

$script:at = 0
function Read-More {
  if (-not (Test-Path -LiteralPath $Log)) { return }
  try {
    $fs = [System.IO.File]::Open($Log, 'Open', 'Read', 'ReadWrite')
    try {
      if ($fs.Length -le $script:at) { return }
      [void]$fs.Seek($script:at, 'Begin')
      $buf = New-Object byte[] ($fs.Length - $script:at)
      $n = $fs.Read($buf, 0, $buf.Length)
      $script:at += $n
      $text = [System.Text.Encoding]::UTF8.GetString($buf, 0, $n)
      $box.AppendText(($text -replace "(?<!`r)`n", "`r`n"))
    } finally { $fs.Close() }
  } catch {}
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300
$timer.Add_Tick({
  Read-More
  if (Test-Path -LiteralPath $Status) {
    $timer.Stop()
    Start-Sleep -Milliseconds 200
    Read-More
    $code = (Get-Content -LiteralPath $Status -Raw).Trim()
    if ($code -eq '0') {
      $form.Text = "$App is installed"
      $head.Text = "Done. $App is installed."
      [void][System.Windows.Forms.MessageBox]::Show($form, "$App is installed. Open it from the Start menu.", 'Done', 'OK', 'Information')
      $form.Close()
    } else {
      $form.Text = "$App did not install"
      $head.Text = "The installer stopped (code $code). What it said is below."
      [void][System.Windows.Forms.MessageBox]::Show($form, "The installer stopped before $App was installed. What it said is in the window.", 'Not installed', 'OK', 'Warning')
    }
  }
})
$form.Add_Shown({ $form.Activate(); $timer.Start() })
[void]$form.ShowDialog()
