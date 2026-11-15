// The Windows download for an XN app: a small program that opens PowerShell and runs the app's own installer, the
// same one its README gives, so there is one way to install it. Built once per app with the name, install command
// and icon baked in (see build.sh).
package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
)

// set at build time with -ldflags "-X main.app=... -X main.command=..."
var (
	app     = "Flash"
	command = ""
)

func main() {
	fmt.Printf("Installing %s. This opens PowerShell and runs %s's installer:\n\n  %s\n\n", app, app, command)
	ps := exec.Command("powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
		fmt.Sprintf("$Host.UI.RawUI.WindowTitle = 'Installing %s'; %s", app, command))
	ps.Stdin, ps.Stdout, ps.Stderr = os.Stdin, os.Stdout, os.Stderr
	err := ps.Run()
	if err != nil {
		fmt.Printf("\nThe installer stopped: %v\nYou can run it yourself in PowerShell:\n\n  %s\n", err, command)
	} else {
		fmt.Printf("\n%s is installed. Open it from the Start menu.\n", app)
	}
	fmt.Print("\nPress Enter to close this window.")
	bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil {
		os.Exit(1)
	}
}
