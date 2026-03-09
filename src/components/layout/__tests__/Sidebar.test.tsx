import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';


import { Sidebar } from '../Sidebar';

describe('Sidebar', () => {
  it('renders with app name', () => {
    render(<Sidebar />);
    expect(screen.getByText('Hopp')).toBeInTheDocument();
  });

  it('renders version number', () => {
    render(<Sidebar />);
    expect(screen.getByText('v0.1.0')).toBeInTheDocument();
  });

  it('renders collections section', () => {
    render(<Sidebar />);
    expect(screen.getByText('Collections')).toBeInTheDocument();
  });

  it('renders history section', () => {
    render(<Sidebar />);
    expect(screen.getByText('History')).toBeInTheDocument();
  });

  it('renders favorites section', () => {
    render(<Sidebar />);
    expect(screen.getByText('Favorites')).toBeInTheDocument();
  });

  it('renders settings button', () => {
    render(<Sidebar />);
    expect(screen.getByText('Settings')).toBeInTheDocument();
  });

  it('renders help button', () => {
    render(<Sidebar />);
    expect(screen.getByText('Help')).toBeInTheDocument();
  });

  it('applies custom className', () => {
    const { container } = render(<Sidebar className="custom-class" />);
    const sidebar = container.querySelector('aside');
    expect(sidebar?.classList.contains('custom-class')).toBe(true);
  });

  it('renders with custom width', () => {
    const { container } = render(<Sidebar width={300} />);
    const sidebar = container.querySelector('aside');
    expect(sidebar?.style.width).toBe('300px');
  });
});
