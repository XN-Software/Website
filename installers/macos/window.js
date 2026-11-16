// The installer's window on a Mac. First it asks: Install, with a box to tick for the dev version where the app has
// one. Then it shows what the installer says, as it says it, and a popup when it is done. Run with
// osascript -l JavaScript by the app's launcher (install), given the app's name, the log the installer writes, the
// file its exit code goes in when it finishes, the file to write the choice to ("stable", "dev" or "cancel"), and
// "1" when there is a dev version. Cocoa's constants are written as their numbers, as not every one is defined here.
ObjC.import('Cocoa');

function run(argv) {
  const [name, logPath, statusPath, choicePath, canDev] = argv;
  const app = $.NSApplication.sharedApplication;
  app.setActivationPolicy(0);   // a regular app: in the Dock, able to come to the front

  const W = 760, H = 480;
  const win = $.NSWindow.alloc.initWithContentRectStyleMaskBackingDefer($.NSMakeRect(0, 0, W, H), 1 | 2 | 4 | 8, 2, false);
  win.title = 'Install ' + name;
  win.releasedWhenClosed = false;
  win.center;
  const view = win.contentView;
  const write = (path, s) => $(s).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);

  // ----- first: what to install -----
  const title = $.NSTextField.labelWithString('Install ' + name);
  title.font = $.NSFont.boldSystemFontOfSize(26);
  title.frame = $.NSMakeRect(28, H - 70, W - 56, 36);
  const what = $.NSTextField.wrappingLabelWithString('This downloads ' + name + ' and installs it for you. It can take a few minutes, and this window shows each step.');
  what.frame = $.NSMakeRect(30, H - 130, W - 60, 44);
  const dev = $.NSButton.checkboxWithTitleTargetAction('Install the dev version: the newest changes, before they are released, so less tested.', null, null);
  dev.frame = $.NSMakeRect(28, H - 180, W - 56, 24);
  dev.hidden = canDev !== '1';

  // ----- then: the log -----
  const head = $.NSTextField.labelWithString('');
  head.frame = $.NSMakeRect(16, H - 36, W - 32, 20);
  head.autoresizingMask = 2 | 8;
  const scroll = $.NSScrollView.alloc.initWithFrame($.NSMakeRect(16, 16, W - 32, H - 60));
  scroll.hasVerticalScroller = true;
  scroll.borderType = 2;
  scroll.autoresizingMask = 2 | 16;
  const size = scroll.contentSize;
  const text = $.NSTextView.alloc.initWithFrame($.NSMakeRect(0, 0, size.width, size.height));
  text.editable = false;
  text.richText = false;
  text.verticallyResizable = true;
  text.autoresizingMask = 2;
  text.textContainer.widthTracksTextView = true;
  text.font = $.NSFont.userFixedPitchFontOfSize(12);
  scroll.documentView = text;
  head.hidden = true;
  scroll.hidden = true;

  const fm = $.NSFileManager.defaultManager;
  let shown = 0, finished = false, chosen = false, ticker = null;
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
  const popup = (titleText, body, style) => {
    const a = $.NSAlert.alloc.init;
    a.messageText = titleText;
    a.informativeText = body;
    a.alertStyle = style;
    a.addButtonWithTitle('OK');
    app.activateIgnoringOtherApps(true);
    a.runModal;
  };

  ObjC.registerSubclass({
    name: 'XNInstaller',
    methods: {
      'install:': {
        types: ['void', ['id']],
        implementation: function () {
          if (chosen) return;
          chosen = true;
          const which = canDev === '1' && dev.state === 1 ? 'dev' : 'stable';
          write(choicePath, which);
          win.title = 'Installing ' + name;
          head.stringValue = (which === 'dev' ? 'Installing the dev version of ' : 'Installing ') + name + '. This shows what the installer is doing.';
          for (const v of [title, what, dev, go, no]) v.hidden = true;
          head.hidden = false;
          scroll.hidden = false;
          $.NSTimer.scheduledTimerWithTimeIntervalTargetSelectorUserInfoRepeats(0.3, ticker, 'tick:', null, true);
        },
      },
      'cancel:': {
        types: ['void', ['id']],
        implementation: function () { write(choicePath, 'cancel'); app.terminate(null); },
      },
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
            popup('Done', name + ' is installed. Open it from Applications or Launchpad.', 1);
            app.terminate(null);
          } else {
            win.title = name + ' did not install';
            head.stringValue = 'The installer stopped (code ' + code + '). What it said is below.';
            popup('Not installed', 'The installer stopped before ' + name + ' was installed. What it said is in the window.', 0);
          }
        },
      },
    },
  });
  ticker = $.XNInstaller.alloc.init;
  const go = $.NSButton.buttonWithTitleTargetAction('Install', ticker, 'install:');
  go.frame = $.NSMakeRect(W - 148, 20, 120, 32);
  go.keyEquivalent = '\r';
  const no = $.NSButton.buttonWithTitleTargetAction('Cancel', ticker, 'cancel:');
  no.frame = $.NSMakeRect(W - 268, 20, 110, 32);
  for (const v of [title, what, dev, go, no, head, scroll]) view.addSubview(v);

  win.makeKeyAndOrderFront(null);
  app.activateIgnoringOtherApps(true);
  app.run;
}
