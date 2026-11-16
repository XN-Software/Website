// The installer's window on a Mac: what the installer says, as it says it, then a popup when it is done.
// Run with osascript -l JavaScript by the app's launcher (install), given the app's name, the log the installer
// writes, and the file its exit code goes in when it finishes. Cocoa's constants are written as their numbers, as not
// every one is defined in this bridge.
ObjC.import('Cocoa');

function run(argv) {
  const [name, logPath, statusPath] = argv;
  const app = $.NSApplication.sharedApplication;
  app.setActivationPolicy(0);   // a regular app: in the Dock, able to come to the front

  const W = 760, H = 480;
  const win = $.NSWindow.alloc.initWithContentRectStyleMaskBackingDefer($.NSMakeRect(0, 0, W, H),
    1 | 2 | 4 | 8, 2, false);   // titled, closable, miniaturizable, resizable; buffered
  win.title = 'Installing ' + name;
  win.releasedWhenClosed = false;
  win.center;

  const head = $.NSTextField.labelWithString('Installing ' + name + '. This shows what the installer is doing; it can take a few minutes.');
  head.frame = $.NSMakeRect(16, H - 36, W - 32, 20);
  head.autoresizingMask = 2 | 8;   // width sizable, flexible bottom margin

  const scroll = $.NSScrollView.alloc.initWithFrame($.NSMakeRect(16, 16, W - 32, H - 60));
  scroll.hasVerticalScroller = true;
  scroll.borderType = 2;   // bezel
  scroll.autoresizingMask = 2 | 16;   // width and height sizable
  const size = scroll.contentSize;
  const text = $.NSTextView.alloc.initWithFrame($.NSMakeRect(0, 0, size.width, size.height));
  text.editable = false;
  text.richText = false;
  text.verticallyResizable = true;
  text.autoresizingMask = 2;
  text.textContainer.widthTracksTextView = true;
  text.font = $.NSFont.userFixedPitchFontOfSize(12);
  scroll.documentView = text;

  win.contentView.addSubview(head);
  win.contentView.addSubview(scroll);
  win.makeKeyAndOrderFront(null);
  app.activateIgnoringOtherApps(true);

  const fm = $.NSFileManager.defaultManager;
  let shown = 0, finished = false;
  const readLog = () => {
    const s = $.NSString.stringWithContentsOfFileEncodingError(logPath, $.NSUTF8StringEncoding, null);
    if (!s || s.isNil()) return;
    const all = s.js;
    if (all.length <= shown) return;
    text.textStorage.appendAttributedString($.NSAttributedString.alloc.initWithStringAttributes(all.slice(shown),
      $.NSDictionary.dictionaryWithObjectForKey(text.font, $.NSFontAttributeName)));
    shown = all.length;
    text.scrollToEndOfDocument(null);
  };
  const popup = (title, body, style) => {
    const a = $.NSAlert.alloc.init;
    a.messageText = title;
    a.informativeText = body;
    a.alertStyle = style;
    a.addButtonWithTitle('OK');
    app.activateIgnoringOtherApps(true);
    a.runModal;
  };

  ObjC.registerSubclass({
    name: 'XNInstallTicker',
    methods: {
      'tick:': {
        types: ['void', ['id']],
        implementation: function (timer) {
          if (finished) return;
          readLog();
          if (!fm.fileExistsAtPath(statusPath)) return;
          finished = true;
          timer.invalidate;
          readLog();
          const st = $.NSString.stringWithContentsOfFileEncodingError(statusPath, $.NSUTF8StringEncoding, null);
          const code = st && !st.isNil() ? st.js.trim() : '1';
          if (code === '0') {
            win.title = name + ' is installed';
            head.stringValue = 'Done. ' + name + ' is installed.';
            popup('Done', name + ' is installed. Open it from Applications or Launchpad.', 1);   // informational
            app.terminate(null);
          } else {
            win.title = name + ' did not install';
            head.stringValue = 'The installer stopped (code ' + code + '). What it said is below.';
            popup('Not installed', 'The installer stopped before ' + name + ' was installed. What it said is in the window.', 0);   // warning
          }
        },
      },
    },
  });
  const ticker = $.XNInstallTicker.alloc.init;
  $.NSTimer.scheduledTimerWithTimeIntervalTargetSelectorUserInfoRepeats(0.3, ticker, 'tick:', null, true);
  app.run;
}
