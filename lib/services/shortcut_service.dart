import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 快捷键 Intent 定义

/// 新建请求 Intent
class NewRequestIntent extends Intent {
  const NewRequestIntent();
}

/// 发送请求 Intent
class SendRequestIntent extends Intent {
  const SendRequestIntent();
}

/// 保存请求 Intent
class SaveRequestIntent extends Intent {
  const SaveRequestIntent();
}

/// 关闭当前标签 Intent
class CloseTabIntent extends Intent {
  const CloseTabIntent();
}

/// 另存为 Intent
class SaveAsIntent extends Intent {
  const SaveAsIntent();
}

/// 切换到指定标签 Intent
class SwitchTabIntent extends Intent {
  final int index;
  const SwitchTabIntent(this.index);
}

/// 快捷键服务
/// 
/// 提供全局快捷键配置和管理
class ShortcutService {
  /// 获取所有快捷键配置
  static Map<ShortcutActivator, Intent> get shortcuts => {
    // Cmd+N: 新建请求
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
        const NewRequestIntent(),
    
    // Cmd+Enter: 发送请求
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.enter):
        const SendRequestIntent(),
    
    // Cmd+S: 保存请求
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
        const SaveRequestIntent(),
    
    // Cmd+W: 关闭标签
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyW):
        const CloseTabIntent(),
    
    // Cmd+Shift+S: 另存为
    LogicalKeySet(
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.keyS,
    ): const SaveAsIntent(),
    
    // Cmd+1-9: 切换标签
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit1):
        const SwitchTabIntent(0),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit2):
        const SwitchTabIntent(1),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit3):
        const SwitchTabIntent(2),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit4):
        const SwitchTabIntent(3),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit5):
        const SwitchTabIntent(4),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit6):
        const SwitchTabIntent(5),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit7):
        const SwitchTabIntent(6),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit8):
        const SwitchTabIntent(7),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit9):
        const SwitchTabIntent(8),
  };
  
  /// 获取快捷键说明文本
  static String getShortcutLabel(String action) {
    return switch (action) {
      'new' => '⌘N',
      'send' => '⌘↵',
      'save' => '⌘S',
      'close' => '⌘W',
      'saveAs' => '⌘⇧S',
      _ => '',
    };
  }
}
