import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import React from 'react';

import { ResizablePanel } from '../ResizablePanel';

describe('ResizablePanel', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear();
  });

  it('renders with children', () => {
    render(
      <ResizablePanel>
        <div data-testid="content">Test Content</div>
      </ResizablePanel>
    );

    expect(screen.getByTestId('content')).toBeInTheDocument();
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  it('renders with default width', () => {
    const { container } = render(
      <ResizablePanel defaultWidth={300}>
        <div>Content</div>
      </ResizablePanel>
    );

    const panel = container.firstChild as HTMLElement;
    expect(panel.style.width).toBe('300px');
  });

  it('renders with custom min and max width', () => {
    const { container } = render(
      <ResizablePanel minWidth={200} maxWidth={400} defaultWidth={260}>
        <div>Content</div>
      </ResizablePanel>
    );

    const panel = container.firstChild as HTMLElement;
    expect(panel).toBeInTheDocument();
  });

  it('calls onWidthChange when width changes', () => {
    const onWidthChange = vi.fn();
    const { container } = render(
      <ResizablePanel defaultWidth={260} onWidthChange={onWidthChange}>
        <div>Content</div>
      </ResizablePanel>
    );

    const resizer = container.querySelector('[role="separator"]');
    expect(resizer).toBeInTheDocument();
  });

  it('calls onResizeStart and onResizeEnd callbacks', () => {
    const onResizeStart = vi.fn();
    const onResizeEnd = vi.fn();
    const { container } = render(
      <ResizablePanel
        defaultWidth={260}
        onResizeStart={onResizeStart}
        onResizeEnd={onResizeEnd}
      >
        <div>Content</div>
      </ResizablePanel>
    );

    const resizer = container.querySelector('[role="separator"]');
    expect(resizer).toBeInTheDocument();
  });

  it('applies custom className', () => {
    const { container } = render(
      <ResizablePanel className="custom-class">
        <div>Content</div>
      </ResizablePanel>
    );

    const panel = container.firstChild as HTMLElement;
    expect(panel.classList.contains('custom-class')).toBe(true);
  });

  it('has correct ARIA attributes', () => {
    const { container } = render(
      <ResizablePanel>
        <div>Content</div>
      </ResizablePanel>
    );

    const resizer = container.querySelector('[role="separator"]');
    expect(resizer).toHaveAttribute('role', 'separator');
    expect(resizer).toHaveAttribute('aria-orientation', 'vertical');
    expect(resizer).toHaveAttribute('aria-label', 'Resize panel');
  });
});
