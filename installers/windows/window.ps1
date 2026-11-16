# The installer's window. First it asks: Install, with a box to tick for the dev version where the app has one.
# Then it shows what the installer says, as it says it, and a popup when it is done. Run by the Windows download
# (main.go), which waits for the choice file this writes ("stable", "dev" or "cancel"), then runs the installer,
# writing its log and, when it finishes, its exit code to the status file. Plain ASCII on purpose.
param([string]$App, [string]$Log, [string]$Status, [string]$Choice, [string]$Icon, [switch]$CanDev)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$paper = [System.Drawing.Color]::FromArgb(244, 241, 234)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Install $App"
$form.Width = 780
$form.Height = 500
$form.StartPosition = 'CenterScreen'
$form.BackColor = $paper
try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon) } catch {}

# ----- first: what to install -----
$ask = New-Object System.Windows.Forms.Panel
$ask.Dock = 'Fill'
$ask.Padding = New-Object System.Windows.Forms.Padding(28, 28, 28, 20)

$title = New-Object System.Windows.Forms.Label
$title.Text = "Install $App"
$title.Font = New-Object System.Drawing.Font('Segoe UI', 20, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(28, 28)
$ask.Controls.Add($title)

$what = New-Object System.Windows.Forms.Label
$what.Text = "This downloads $App and installs it for you. It can take a few minutes, and this window shows each step."
$what.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$what.MaximumSize = New-Object System.Drawing.Size(700, 0)
$what.AutoSize = $true
$what.Location = New-Object System.Drawing.Point(30, 82)
$ask.Controls.Add($what)

$dev = New-Object System.Windows.Forms.CheckBox
$dev.Text = "Install the dev version: the newest changes, before they are released, so less tested."
$dev.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$dev.AutoSize = $true
$dev.Location = New-Object System.Drawing.Point(30, 140)
$dev.Visible = [bool]$CanDev
$ask.Controls.Add($dev)

$go = New-Object System.Windows.Forms.Button
$go.Text = "Install"
$go.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$go.Size = New-Object System.Drawing.Size(120, 36)
$go.Anchor = 'Bottom, Right'
$go.Location = New-Object System.Drawing.Point(610, 390)
$ask.Controls.Add($go)
$form.AcceptButton = $go

$no = New-Object System.Windows.Forms.Button
$no.Text = "Cancel"
$no.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$no.Size = New-Object System.Drawing.Size(100, 36)
$no.Anchor = 'Bottom, Right'
$no.Location = New-Object System.Drawing.Point(498, 390)
$ask.Controls.Add($no)

# ----- then: the log -----
$head = New-Object System.Windows.Forms.Label
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
$pad.Visible = $false
$head.Visible = $false
$form.Controls.Add($pad)
$form.Controls.Add($head)
$form.Controls.Add($ask)

$script:chosen = $false
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

$go.Add_Click({
  $which = 'stable'
  if ($CanDev -and $dev.Checked) { $which = 'dev' }
  Set-Content -LiteralPath $Choice -Value $which -Encoding Ascii
  $script:chosen = $true
  $form.Text = "Installing $App"
  if ($which -eq 'dev') { $head.Text = "Installing the dev version of $App. This shows what the installer is doing." }
  else { $head.Text = "Installing $App. This shows what the installer is doing." }
  $ask.Visible = $false
  $head.Visible = $true
  $pad.Visible = $true
  $timer.Start()
})
$no.Add_Click({ $form.Close() })
$form.Add_FormClosing({ if (-not $script:chosen) { try { Set-Content -LiteralPath $Choice -Value 'cancel' -Encoding Ascii } catch {} } })
$form.Add_Shown({ $form.Activate(); $go.Focus() })
[void]$form.ShowDialog()
