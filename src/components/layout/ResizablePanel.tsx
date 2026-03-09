import type { FC, ReactNode, MouseEvent as ReactMouseEvent, TouchEvent as ReactTouchEvent } from 'react';
import { useCallback, useEffect, useRef, useState } from 'react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Utility to merge tailwind classes
 */
function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

export interface ResizablePanelProps {
  /** Minimum width in pixels */
  minWidth?: number;
  /** Maximum width in pixels */
  maxWidth?: number;
  /** Initial width in pixels */
  defaultWidth?: number;
  /** Current width (controlled mode) */
  width?: number;
  /** Callback when width changes */
  onWidthChange?: (width: number) => void;
  /** Callback when resizing starts */
  onResizeStart?: () => void;
  /** Callback when resizing ends */
  onResizeEnd?: (width: number) => void;
  /** Panel content */
  children: ReactNode;
  /** Additional CSS classes */
  className?: string;
  /** Resizer position */
  resizerPosition?: 'left' | 'right';
  /** Storage key for persisting width */
  storageKey?: string;
}

/**
 * ResizablePanel component
 *
 * A panel that can be resized by dragging its edge.
 * Supports min/max constraints and optional persistence.
 *
 * @example
 * ```tsx
 * <ResizablePanel
 *   minWidth={200}
 *   maxWidth={400}
 *   defaultWidth={260}
 *   storageKey="sidebar-width"
 * >
 *   <SidebarContent />
 * </ResizablePanel>
 * ```
 */
export const ResizablePanel: FC<ResizablePanelProps> = ({
  minWidth = 200,
  maxWidth = 400,
  defaultWidth = 260,
  width: controlledWidth,
  onWidthChange,
  onResizeStart,
  onResizeEnd,
  children,
  className,
  resizerPosition = 'right',
  storageKey,
}) => {
  const panelRef = useRef<HTMLDivElement>(null);
  const [isResizing, setIsResizing] = useState(false);
  const [internalWidth, setInternalWidth] = useState(() => {
    if (storageKey) {
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        const parsed = parseInt(saved, 10);
        if (!isNaN(parsed) && parsed >= minWidth && parsed <= maxWidth) {
          return parsed;
        }
      }
    }
    return defaultWidth;
  });

  const width = controlledWidth ?? internalWidth;

  const handleMouseDown = useCallback(
    (e: ReactMouseEvent) => {
      e.preventDefault();
      setIsResizing(true);
      onResizeStart?.();

      const startX = e.clientX;
      const startWidth = width;

      const handleMouseMove = (moveEvent: MouseEvent) => {
        const delta = resizerPosition === 'right'
          ? moveEvent.clientX - startX
          : startX - moveEvent.clientX;
        const newWidth = Math.max(minWidth, Math.min(maxWidth, startWidth + delta));

        if (controlledWidth === undefined) {
          setInternalWidth(newWidth);
        }
        onWidthChange?.(newWidth);
      };

      const handleMouseUp = (upEvent: MouseEvent) => {
        setIsResizing(false);
        const delta = resizerPosition === 'right'
          ? upEvent.clientX - startX
          : startX - upEvent.clientX;
        const finalWidth = Math.max(minWidth, Math.min(maxWidth, startWidth + delta));

        if (storageKey) {
          localStorage.setItem(storageKey, String(finalWidth));
        }
        onResizeEnd?.(finalWidth);

        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
        document.body.style.cursor = '';
        document.body.style.userSelect = '';
      };

      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);
      document.body.style.cursor = 'col-resize';
      document.body.style.userSelect = 'none';
    },
    [width, minWidth, maxWidth, controlledWidth, resizerPosition, storageKey, onWidthChange, onResizeStart, onResizeEnd]
  );

  // Handle touch events for mobile
  const handleTouchStart = useCallback(
    (e: ReactTouchEvent) => {
      const touch = e.touches[0];
      setIsResizing(true);
      onResizeStart?.();

      const startX = touch.clientX;
      const startWidth = width;

      const handleTouchMove = (moveEvent: TouchEvent) => {
        const moveTouch = moveEvent.touches[0];
        const delta = resizerPosition === 'right'
          ? moveTouch.clientX - startX
          : startX - moveTouch.clientX;
        const newWidth = Math.max(minWidth, Math.min(maxWidth, startWidth + delta));

        if (controlledWidth === undefined) {
          setInternalWidth(newWidth);
        }
        onWidthChange?.(newWidth);
      };

      const handleTouchEnd = (endEvent: TouchEvent) => {
        setIsResizing(false);
        const endTouch = endEvent.changedTouches[0];
        const delta = resizerPosition === 'right'
          ? endTouch.clientX - startX
          : startX - endTouch.clientX;
        const finalWidth = Math.max(minWidth, Math.min(maxWidth, startWidth + delta));

        if (storageKey) {
          localStorage.setItem(storageKey, String(finalWidth));
        }
        onResizeEnd?.(finalWidth);

        document.removeEventListener('touchmove', handleTouchMove);
        document.removeEventListener('touchend', handleTouchEnd);
      };

      document.addEventListener('touchmove', handleTouchMove);
      document.addEventListener('touchend', handleTouchEnd);
    },
    [width, minWidth, maxWidth, controlledWidth, resizerPosition, storageKey, onWidthChange, onResizeStart, onResizeEnd]
  );

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    };
  }, []);

  return (
    <div
      ref={panelRef}
      className={cn(
        'flex h-full relative',
        isResizing && 'select-none',
        className
      )}
      style={{ width: `${width}px`, minWidth: `${width}px` }}
    >
      {resizerPosition === 'left' && (
        <div
          className={cn(
            'absolute left-0 top-0 bottom-0 w-1 cursor-col-resize z-10',
            'bg-transparent hover:bg-primary transition-colors',
            isResizing && 'bg-primary'
          )}
          onMouseDown={handleMouseDown}
          onTouchStart={handleTouchStart}
          role="separator"
          aria-orientation="vertical"
          aria-label="Resize panel"
        />
      )}

      <div className="flex-1 overflow-hidden">
        {children}
      </div>

      {resizerPosition === 'right' && (
        <div
          className={cn(
            'absolute right-0 top-0 bottom-0 w-1 cursor-col-resize z-10',
            'bg-transparent hover:bg-primary transition-colors',
            isResizing && 'bg-primary'
          )}
          onMouseDown={handleMouseDown}
          onTouchStart={handleTouchStart}
          role="separator"
          aria-orientation="vertical"
          aria-label="Resize panel"
        />
      )}
    </div>
  );
};

export default ResizablePanel;
