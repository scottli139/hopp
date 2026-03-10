import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';


import { Header } from '../Header';

describe('Header', () => {
  it('renders with default title', () => {
    render(<Header />);
    expect(screen.getByText('Untitled Request')).toBeInTheDocument();
  });

  it('renders with custom title', () => {
    render(<Header title="GET https://api.example.com" />);
    expect(screen.getByText('GET https://api.example.com')).toBeInTheDocument();
  });

  it('renders save button', () => {
    render(<Header />);
    expect(screen.getByText('Save')).toBeInTheDocument();
  });

  it('calls onSave when save button clicked', () => {
    const onSave = vi.fn();
    render(<Header onSave={onSave} />);
    
    const saveButton = screen.getByText('Save');
    fireEvent.click(saveButton);
    expect(onSave).toHaveBeenCalled();
  });

  it('calls onClose when close button clicked', () => {
    const onClose = vi.fn();
    render(<Header onClose={onClose} />);
    
    const closeButton = screen.getByTitle('Close');
    fireEvent.click(closeButton);
    expect(onClose).toHaveBeenCalled();
  });

  it('renders method badge', () => {
    render(<Header />);
    expect(screen.getByText('GET')).toBeInTheDocument();
  });

  it('applies custom className', () => {
    const { container } = render(<Header className="custom-class" />);
    const header = container.querySelector('header');
    expect(header?.classList.contains('custom-class')).toBe(true);
  });
});
