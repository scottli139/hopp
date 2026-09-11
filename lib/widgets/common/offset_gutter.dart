import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

/// offset 直绘行号栏：不放进滚动视图，固定视口高，只绘制当前可见行号
///（续行无行号）。
///
/// 超高行号层在 Windows 分数 DPI 下滚动重绘时会被引擎按过期偏移合成
/// （行号错乱/重影/冻结），视口高小层从根上避开该问题；行号位置由
/// [readOffset] 当帧读取，与内容天然同步。
///
/// [rowHeight] 必须是当前 textScaler 下的真实可视行高（用与内容同参的
/// TextPainter 实测；字体度量取整使 scale() 估算与真实渲染存在亚像素
/// 偏差并逐行累计）。行号文本使用与内容完全相同的字体/字号/height
/// （code12 + height 1.5）并放在 [rowHeight] 高盒内垂直居中——行盒与
/// 内容行盒一致，基线天然对齐，不引入另一套字体度量的墨迹偏差。
class OffsetGutter extends StatelessWidget {
  const OffsetGutter({
    super.key,
    required this.theme,
    required this.rowDocLines,
    required this.rowHeight,
    required this.topPadding,
    required this.listenable,
    required this.readOffset,
    required this.width,
    required this.rightPadding,
  });

  final ThemeData theme;

  /// 每个可视行对应的文档行号（1-based）；续行为 null
  final List<int?> rowDocLines;

  /// 可视行高（逻辑像素，为当前 textScaler 下的实测值，不含顶部 padding）
  final double rowHeight;

  /// 内容滚动区顶部 padding
  final double topPadding;

  /// 驱动重建的可监听对象（ScrollController 或 ValueNotifier<double>）
  final Listenable listenable;

  /// 当帧读取滚动 offset；多挂/未挂等瞬态由调用方兜底
  final double Function() readOffset;

  final double width;
  final double rightPadding;

  @override
  Widget build(BuildContext context) {
    final gutterStyle = AppTextStyles.code12.copyWith(
      inherit: false,
      height: 1.5,
      letterSpacing: 0,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );

    return Container(
      width: width,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: EdgeInsets.only(right: rightPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: listenable,
            builder: (context, _) {
              final rawOffset = readOffset();
              final viewportH = constraints.maxHeight;
              // 重建瞬间 offset 可能超过当前内容范围（如模式切换后残留的
              // 旧 ScrollPosition offset）；钳制到估算有效区间，保证行号
              // 始终落在真实内容上
              final estimatedMax =
                  (rowDocLines.length * rowHeight + topPadding * 2 - viewportH)
                      .clamp(0.0, double.infinity);
              final offset = rawOffset.clamp(0.0, estimatedMax);
              final children = <Widget>[];
              final first = ((offset - topPadding) / rowHeight)
                  .floor()
                  .clamp(0, rowDocLines.length);
              for (var r = first; r < rowDocLines.length; r++) {
                final y = topPadding + r * rowHeight - offset;
                if (y > viewportH) break;
                final n = rowDocLines[r];
                if (n == null) continue;
                children.add(
                  Positioned(
                    top: y,
                    right: 0,
                    height: rowHeight,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$n', style: gutterStyle),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: viewportH,
                child: Stack(children: children),
              );
            },
          );
        },
      ),
    );
  }
}
