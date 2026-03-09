import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';


import { StatusBar } from '../StatusBar';

describe('StatusBar', () => {
  it('renders with idle status', () => {
    render(<StatusBar connectionStatus="idle" />);
    expect(screen.getByText('Idle')).toBeInTheDocument();
  });

  it('renders with connecting status', () => {
    render(<StatusBar connectionStatus="connecting" />);
    expect(screen.getByText('Connecting...')).toBeInTheDocument();
  });

  it('renders with connected status', () => {
    render(<StatusBar connectionStatus="connected" />);
    expect(screen.getByText('Ready')).toBeInTheDocument();
  });

  it('renders with error status', () => {
    render(<StatusBar connectionStatus="error" />);
    expect(screen.getByText('Error')).toBeInTheDocument();
  });

  it('renders response metrics when connected', () => {
    render(
      <StatusBar
        connectionStatus="connected"
        statusCode={200}
        responseTime={245}
        responseSize={1024}
      />
    );
    
    expect(screen.getByText('200')).toBeInTheDocument();
    expect(screen.getByText('245 ms')).toBeInTheDocument();
    expect(screen.getByText('1 KB')).toBeInTheDocument();
  });

  it('renders version info', () => {
    render(<StatusBar />);
    expect(screen.getByText('Hopp v0.1.0')).toBeInTheDocument();
    expect(screen.getByText('Tauri 2.x')).toBeInTheDocument();
    expect(screen.getByText('React 18')).toBeInTheDocument();
  });

  it('applies custom className', () => {
    const { container } = render(<StatusBar className="custom-class" />);
    const footer = container.querySelector('footer');
    expect(footer?.classList.contains('custom-class')).toBe(true);
  });

  it('formats bytes correctly', () => {
    const { rerender } = render(
      <StatusBar connectionStatus="connected" responseSize={0} />
    );
    expect(screen.getByText('0 B')).toBeInTheDocument();

    rerender(<StatusBar connectionStatus="connected" responseSize={1024} />);
    expect(screen.getByText('1 KB')).toBeInTheDocument();

    rerender(<StatusBar connectionStatus="connected" responseSize={1024 * 1024} />);
    expect(screen.getByText('1 MB')).toBeInTheDocument();
  });
});
