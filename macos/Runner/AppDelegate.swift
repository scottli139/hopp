import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // 设置应用程序菜单
    setupApplicationMenu()
    super.applicationDidFinishLaunching(notification)
  }
  
  /// 设置应用程序菜单
  private func setupApplicationMenu() {
    guard let mainMenu = NSApp.mainMenu else { return }
    
    // 创建 File 菜单
    let fileMenuItem = NSMenuItem()
    fileMenuItem.title = "File"
    
    let fileMenu = NSMenu(title: "File")
    
    // New Request (Cmd+N)
    let newRequestItem = NSMenuItem(
      title: "New Request",
      action: #selector(handleNewRequest(_:)),
      keyEquivalent: "n"
    )
    newRequestItem.keyEquivalentModifierMask = .command
    fileMenu.addItem(newRequestItem)
    
    // New Collection (Cmd+Shift+N)
    let newCollectionItem = NSMenuItem(
      title: "New Collection",
      action: #selector(handleNewCollection(_:)),
      keyEquivalent: "n"
    )
    newCollectionItem.keyEquivalentModifierMask = [.command, .shift]
    fileMenu.addItem(newCollectionItem)
    
    fileMenu.addItem(NSMenuItem.separator())
    
    // Save (Cmd+S)
    let saveItem = NSMenuItem(
      title: "Save",
      action: #selector(handleSave(_:)),
      keyEquivalent: "s"
    )
    saveItem.keyEquivalentModifierMask = .command
    fileMenu.addItem(saveItem)
    
    // Save As... (Cmd+Shift+S)
    let saveAsItem = NSMenuItem(
      title: "Save As...",
      action: #selector(handleSaveAs(_:)),
      keyEquivalent: "s"
    )
    saveAsItem.keyEquivalentModifierMask = [.command, .shift]
    fileMenu.addItem(saveAsItem)
    
    fileMenu.addItem(NSMenuItem.separator())
    
    // Close Tab (Cmd+W)
    let closeTabItem = NSMenuItem(
      title: "Close Tab",
      action: #selector(handleCloseTab(_:)),
      keyEquivalent: "w"
    )
    closeTabItem.keyEquivalentModifierMask = .command
    fileMenu.addItem(closeTabItem)
    
    fileMenuItem.submenu = fileMenu
    
    // 插入到 Application 菜单之后 (索引 1)
    if mainMenu.numberOfItems > 1 {
      mainMenu.insertItem(fileMenuItem, at: 1)
    } else {
      mainMenu.addItem(fileMenuItem)
    }
    
    // 设置 Send Request 菜单项到 Edit 菜单
    setupEditMenu()
  }
  
  /// 设置 Edit 菜单（添加 Send Request）
  private func setupEditMenu() {
    guard let mainMenu = NSApp.mainMenu else { return }
    
    // 查找 Edit 菜单
    for item in mainMenu.items {
      if item.title == "Edit", let editMenu = item.submenu {
        editMenu.addItem(NSMenuItem.separator())
        
        // Send Request (Cmd+Enter)
        let sendRequestItem = NSMenuItem(
          title: "Send Request",
          action: #selector(handleSendRequest(_:)),
          keyEquivalent: "\r"  // Return key
        )
        sendRequestItem.keyEquivalentModifierMask = .command
        editMenu.addItem(sendRequestItem)
        break
      }
    }
  }
  
  // MARK: - Menu Actions
  
  @objc private func handleNewRequest(_ sender: Any?) {
    sendMessageToFlutter("new_request")
  }
  
  @objc private func handleNewCollection(_ sender: Any?) {
    sendMessageToFlutter("new_collection")
  }
  
  @objc private func handleSave(_ sender: Any?) {
    sendMessageToFlutter("save_request")
  }
  
  @objc private func handleSaveAs(_ sender: Any?) {
    sendMessageToFlutter("save_as")
  }
  
  @objc private func handleCloseTab(_ sender: Any?) {
    sendMessageToFlutter("close_tab")
  }
  
  @objc private func handleSendRequest(_ sender: Any?) {
    sendMessageToFlutter("send_request")
  }
  
  /// 发送消息到 Flutter
  private func sendMessageToFlutter(_ method: String) {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else { return }
    
    let channel = FlutterMethodChannel(
      name: "com.example.hopp/menu",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    channel.invokeMethod(method, arguments: nil)
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
