//go:build windows

// The Windows download for an XN app. It runs the app's own installer (the same command as its README) with no
// console window, writes what the installer says to a log, and shows that log as it grows in a window of its own
// (window.ps1, drawn with Windows Forms through PowerShell, which every Windows has). When the installer finishes
// the window says so in a popup. The app's name, command and icon are set at build time (see ../build.sh).
package main

import (
	_ "embed"
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"syscall"
)

var (
	app     = "Flash"
	command = ""
)

//go:embed window.ps1
var window string

const noWindow = 0x08000000 // CREATE_NO_WINDOW

var ansi = regexp.MustCompile(`\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07]*\x07`)

func hidden(c *exec.Cmd) { c.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: noWindow} }

func main() {
	dir, err := os.MkdirTemp("", "xn-install-")
	if err != nil {
		os.Exit(1)
	}
	logPath, statusPath, script := filepath.Join(dir, "install.log"), filepath.Join(dir, "status"), filepath.Join(dir, "window.ps1")
	logFile, err := os.Create(logPath)
	if err != nil {
		os.Exit(1)
	}
	// Windows PowerShell reads a script without a byte order mark as the local code page: keep it plain ASCII
	if err := os.WriteFile(script, []byte(window), 0o644); err != nil {
		os.Exit(1)
	}
	self, _ := os.Executable()

	// the window first, so it is up before the installer has said anything
	gui := exec.Command("powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-STA", "-WindowStyle", "Hidden",
		"-File", script, "-App", app, "-Log", logPath, "-Status", statusPath, "-Icon", self)
	hidden(gui)
	if err := gui.Start(); err != nil {
		fmt.Fprintf(logFile, "Could not open the window: %v\n", err)
	}

	fmt.Fprintf(logFile, "Installing %s. Running its installer:\r\n  %s\r\n\r\n", app, command)
	run := exec.Command("powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
		"$ProgressPreference = 'SilentlyContinue'; try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}; "+command)
	hidden(run)
	out, _ := run.StdoutPipe()
	run.Stderr = run.Stdout
	code := 0
	if err := run.Start(); err != nil {
		fmt.Fprintf(logFile, "Could not start PowerShell: %v\r\n", err)
		code = 1
	} else {
		// line by line, without the colour codes, and only the last of what a progress line overwrote
		sc := bufio.NewScanner(out)
		sc.Buffer(make([]byte, 64*1024), 1024*1024)
		for sc.Scan() {
			line := ansi.ReplaceAllString(sc.Text(), "")
			if i := strings.LastIndex(strings.TrimRight(line, "\r"), "\r"); i >= 0 {
				line = line[i+1:]
			}
			fmt.Fprintf(logFile, "%s\r\n", strings.TrimRight(line, "\r"))
		}
		if err := run.Wait(); err != nil {
			code = 1
			if ee, ok := err.(*exec.ExitError); ok {
				code = ee.ExitCode()
			}
		}
	}
	logFile.Close()
	os.WriteFile(statusPath, []byte(fmt.Sprint(code)), 0o644)
	if gui.Process != nil {
		gui.Wait()
	}
}
