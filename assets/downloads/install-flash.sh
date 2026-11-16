#!/usr/bin/env bash
# Installs Flash: runs its installer (the same command as its README) and shows what it says in a window of its own,
# then a popup when it is done. The window is zenity's or, without it, Python's Tk; with neither (or no screen) it
# shows in this terminal. Run it with: bash install-flash.sh
APP='Flash'
COMMAND='curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Flash/main/install.sh | bash'
dir="$(mktemp -d)"; log="$dir/install.log"; status="$dir/status"
printf 'Installing %s. Running its installer:\n  %s\n\n' "$APP" "$COMMAND" > "$log"
(
  bash -c "$COMMAND" < /dev/null 2>&1 | sed -u -e 's/\x1b\[[0-9;?]*[ -/]*[@-~]//g' -e 's/^.*\r\(.\)/\1/' >> "$log"
  echo "${PIPESTATUS[0]}" > "$status"
) &
worker=$!
code() { cat "$status" 2>/dev/null || echo 1; }
done_text="$APP is installed. Open it from your applications menu, or run: $(echo "$APP" | tr '[:upper:]' '[:lower:]')"
fail_text="The installer stopped before $APP was installed. What it said is in the window, and in $log"
screen=""; [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && screen=1

if [ -n "$screen" ] && command -v zenity >/dev/null 2>&1; then
  # the log as it grows, until the installer is done; then the popup
  ( tail -n +1 -f --pid="$worker" "$log" ) | zenity --text-info --auto-scroll --title="Installing $APP" --width=780 --height=480 --ok-label=Close 2>/dev/null &
  wait "$worker"
  if [ "$(code)" = 0 ]; then zenity --info --title="Done" --text="$done_text" --width=380 2>/dev/null
  else zenity --warning --title="Not installed" --text="$fail_text" --width=380 2>/dev/null; fi
elif [ -n "$screen" ] && command -v python3 >/dev/null 2>&1 && python3 -c 'import tkinter' 2>/dev/null; then
  python3 - "$APP" "$log" "$status" "$done_text" "$fail_text" <<'PY'
import os, sys, tkinter as tk
from tkinter import messagebox
app, log, status, done_text, fail_text = sys.argv[1:]
root = tk.Tk(); root.title(f"Installing {app}"); root.geometry("780x480")
tk.Label(root, text=f"Installing {app}. This shows what the installer is doing; it can take a few minutes.", anchor="w").pack(fill="x", padx=12, pady=(12, 4))
frame = tk.Frame(root); frame.pack(fill="both", expand=True, padx=12, pady=(0, 12))
bar = tk.Scrollbar(frame); bar.pack(side="right", fill="y")
text = tk.Text(frame, wrap="word", font=("monospace", 10), yscrollcommand=bar.set); text.pack(fill="both", expand=True); bar.config(command=text.yview)
at = 0
def tick():
    global at
    try:
        with open(log, "rb") as f:
            f.seek(at); more = f.read(); at += len(more)
        if more:
            text.insert("end", more.decode("utf-8", "replace")); text.see("end")
    except OSError:
        pass
    if os.path.exists(status):
        code = open(status).read().strip()
        if code == "0":
            root.title(f"{app} is installed"); messagebox.showinfo("Done", done_text, parent=root); root.destroy()
        else:
            root.title(f"{app} did not install"); messagebox.showwarning("Not installed", fail_text, parent=root)
        return
    root.after(300, tick)
root.after(100, tick); root.mainloop()
PY
  wait "$worker"
else
  # no window to draw in: the log here, then a notification if there is a desktop to show one
  tail -n +1 -f --pid="$worker" "$log"
  wait "$worker"
  if [ "$(code)" = 0 ]; then echo; echo "Done. $done_text"; command -v notify-send >/dev/null 2>&1 && notify-send "Done" "$done_text"
  else echo; echo "$fail_text"; command -v notify-send >/dev/null 2>&1 && notify-send "Not installed" "$fail_text"; fi
fi
[ "$(code)" = 0 ]
