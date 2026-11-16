//go:build windows

// The Windows download for an XN app. Its window (window.ps1, drawn with Windows Forms through PowerShell, which every
// Windows has) asks first, with a box to tick for the dev version where the app has one; then this runs the app's own
// installer (the same command as its README) with no console window, writes what it says to a log, and the window
// shows the log as it grows and pops up when it is done. Name, commands and icon are set at build time (../build.sh).
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
	"time"
)

var (
	app        = "Flash"
	command    = ""
	devCommand = "" // the dev version's install command; empty when the app has no separate dev install
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
	choicePath := filepath.Join(dir, "choice")
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
	// no console for it (CREATE_NO_WINDOW), but not started hidden either: Windows applies a hidden start to the first
	// window the process opens, which would be the installer's own
	args := []string{"-NoProfile", "-ExecutionPolicy", "Bypass", "-STA",
		"-File", script, "-App", app, "-Log", logPath, "-Status", statusPath, "-Choice", choicePath, "-Icon", self}
	if devCommand != "" {
		args = append(args, "-CanDev")
	}
	gui := exec.Command("powershell.exe", args...)
	gui.SysProcAttr = &syscall.SysProcAttr{CreationFlags: noWindow}
	if err := gui.Start(); err != nil {
		os.Exit(1)
	}
	// wait for Install (or for the window to close without it)
	closed := make(chan struct{})
	go func() { gui.Wait(); close(closed) }()
	choice := ""
	for choice == "" {
		select {
		case <-closed:
			os.Exit(0)
		case <-time.After(200 * time.Millisecond):
			if b, err := os.ReadFile(choicePath); err == nil {
				choice = strings.TrimSpace(string(b))
			}
		}
	}
	if choice == "cancel" {
		<-closed
		os.Exit(0)
	}
	if choice == "dev" && devCommand != "" {
		command = devCommand
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
	<-closed
}
