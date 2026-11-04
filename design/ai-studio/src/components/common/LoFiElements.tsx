import React from 'react';
import { ArrowLeft, ChevronRight, Check } from 'lucide-react';
import { TextMode } from '../../types';

interface LoFiContextType {
  textMode: TextMode;
  showSpecs: boolean;
}

export const LoFiContext = React.createContext<LoFiContextType>({
  textMode: 'hybrid-more-text',
  showSpecs: false,
});

export const useLoFi = () => React.useContext(LoFiContext);

export type TextTier = 'primary' | 'secondary' | 'tertiary';

// Wireframe Filler Text with In-Between Hybrid Modes
export function FillerText({
  semantic,
  lorem = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
  skeletonWidth = 'w-3/4',
  className = '',
  tier = 'secondary',
  as: Component = 'span',
}: {
  semantic: string;
  lorem?: string;
  skeletonWidth?: string;
  className?: string;
  tier?: TextTier;
  as?: React.ElementType;
}) {
  const { textMode } = useLoFi();

  let shouldShowSkeleton = false;

  switch (textMode) {
    case 'skeleton-only':
      shouldShowSkeleton = true;
      break;

    case 'hybrid-less-text':
      // Minimal text: only primary headings & key CTAs keep text; secondary & tertiary are skeleton
      shouldShowSkeleton = tier !== 'primary';
      break;

    case 'hybrid-balanced':
      // Balanced: primary headers & buttons keep text, secondary labels get partial text, tertiary descriptions skeleton
      shouldShowSkeleton = tier === 'tertiary' || (tier === 'secondary' && semantic.length > 28);
      break;

    case 'hybrid-more-text':
      // In-between default: overwhelmingly text (primary + secondary + short descriptions), only verbose tertiary paragraphs skeleton
      shouldShowSkeleton = tier === 'tertiary' && semantic.length > 45;
      break;

    case 'text-only':
    default:
      shouldShowSkeleton = false;
      break;
  }

  if (shouldShowSkeleton) {
    return (
      <Component className={`inline-block ${className}`}>
        <span
          className={`inline-block h-3 bg-neutral-300/90 rounded-xs animate-pulse ${skeletonWidth}`}
          aria-hidden="true"
        />
      </Component>
    );
  }

  return <Component className={className}>{semantic}</Component>;
}

// Wireframe Button (Strictly Monochrome Black, Gray, White)
export function LoFiButton({
  children,
  variant = 'primary',
  size = 'md',
  fullWidth = false,
  disabled = false,
  onClick,
  className = '',
  type = 'button',
  icon,
}: {
  children?: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'shaded';
  size?: 'sm' | 'md' | 'lg';
  fullWidth?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  className?: string;
  type?: 'button' | 'submit' | 'reset';
  icon?: React.ReactNode;
}) {
  const base =
    'relative inline-flex items-center justify-center font-medium transition-all select-none focus-visible:outline-2 focus-visible:outline-black cursor-pointer disabled:cursor-not-allowed disabled:opacity-40';

  // Standard touch target minimum is 44px for primary/regular buttons
  const sizeStyles = {
    sm: 'h-9 px-3 text-xs rounded-md min-w-[36px]',
    md: 'min-h-[44px] px-4 py-2.5 text-sm rounded-lg min-w-[44px]',
    lg: 'min-h-[48px] px-5 py-3 text-base rounded-xl min-w-[48px]',
  };

  const variants = {
    primary: 'bg-black text-white hover:bg-neutral-800 active:scale-[0.98]',
    secondary: 'bg-neutral-200 text-black hover:bg-neutral-300 active:scale-[0.98]',
    outline: 'border border-neutral-400 bg-white text-neutral-900 hover:bg-neutral-100 hover:border-neutral-600 active:scale-[0.98]',
    shaded: 'bg-neutral-100 border border-neutral-300 text-neutral-900 hover:bg-neutral-200 active:scale-[0.98]',
    ghost: 'bg-transparent text-neutral-700 hover:bg-neutral-100 active:bg-neutral-200',
  };

  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      className={`${base} ${sizeStyles[size]} ${variants[variant]} ${fullWidth ? 'w-full' : ''} ${className}`}
    >
      {icon && <span className="mr-2 shrink-0">{icon}</span>}
      {children}
    </button>
  );
}

// Wireframe Input Field (Strictly Monochrome)
export function LoFiInput({
  label,
  placeholder,
  helperText,
  value,
  onChange,
  type = 'text',
  disabled = false,
  error,
}: {
  label?: string;
  placeholder?: string;
  helperText?: string;
  value?: string;
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
  type?: string;
  disabled?: boolean;
  error?: string;
}) {
  const { textMode } = useLoFi();
  const isSkeleton = textMode === 'skeleton-only';

  return (
    <div className="w-full space-y-1.5 text-left">
      {label && (
        <label className="block text-xs font-semibold tracking-wider text-neutral-700 uppercase">
          {isSkeleton ? (
            <span className="inline-block w-24 h-3 bg-neutral-300 rounded-xs" />
          ) : (
            label
          )}
        </label>
      )}
      <div className="relative">
        <input
          type={type}
          disabled={disabled}
          value={value}
          onChange={onChange}
          placeholder={placeholder || 'Enter placeholder text...'}
          className={`w-full min-h-[44px] px-3.5 py-2.5 text-sm bg-white border rounded-lg text-black placeholder:text-neutral-400 focus:outline-none focus:ring-2 focus:ring-black transition-colors ${
            error ? 'border-neutral-900 ring-1 ring-neutral-900' : 'border-neutral-300 hover:border-neutral-500'
          } ${disabled ? 'bg-neutral-100 opacity-60' : ''}`}
        />
      </div>
      {error ? (
        <p className="text-xs text-neutral-900 font-mono font-medium">[!] {error}</p>
      ) : helperText ? (
        <p className="text-xs text-neutral-500">
          <FillerText
            semantic={helperText}
            tier="tertiary"
            skeletonWidth="w-1/2"
          />
        </p>
      ) : null}
    </div>
  );
}

// Wireframe Card (Strictly Grayscale)
export function LoFiCard({
  children,
  className = '',
  shaded = false,
  bordered = true,
  onClick,
  interactive = false,
}: {
  children: React.ReactNode;
  className?: string;
  shaded?: boolean | 'light' | 'medium' | 'dark';
  bordered?: boolean;
  onClick?: () => void;
  interactive?: boolean;
}) {
  const shadeClasses =
    shaded === true || shaded === 'light'
      ? 'bg-neutral-50'
      : shaded === 'medium'
      ? 'bg-neutral-100'
      : shaded === 'dark'
      ? 'bg-neutral-200'
      : 'bg-white';

  return (
    <div
      onClick={onClick}
      className={`rounded-xl p-4 transition-all ${shadeClasses} ${
        bordered ? 'border border-neutral-300' : ''
      } ${
        interactive
          ? 'cursor-pointer hover:border-neutral-600 hover:shadow-xs active:scale-[0.99]'
          : ''
      } ${className}`}
    >
      {children}
    </div>
  );
}

// Wireframe Image / Media Placeholder Box (Strictly Grayscale)
export function LoFiImagePlaceholder({
  label = 'Media Asset Placeholder',
  aspectRatio = 'aspect-video',
  className = '',
}: {
  label?: string;
  aspectRatio?: string;
  className?: string;
}) {
  const { textMode } = useLoFi();
  return (
    <div
      className={`relative w-full ${aspectRatio} rounded-lg border-2 border-dashed border-neutral-300 bg-neutral-100/70 flex flex-col items-center justify-center p-3 text-center overflow-hidden ${className}`}
    >
      <svg
        className="absolute inset-0 w-full h-full text-neutral-300/80 pointer-events-none"
        preserveAspectRatio="none"
        viewBox="0 0 100 100"
      >
        <line x1="0" y1="0" x2="100" y2="100" stroke="currentColor" strokeWidth="1" />
        <line x1="100" y1="0" x2="0" y2="100" stroke="currentColor" strokeWidth="1" />
      </svg>
      <div className="relative z-10 px-2 py-1 bg-white/90 border border-neutral-300 rounded text-[11px] font-mono font-medium text-neutral-700 shadow-2xs">
        {textMode === 'skeleton-only' ? (
          <span className="inline-block w-20 h-2.5 bg-neutral-300 rounded" />
        ) : (
          `[ ${label} ]`
        )}
      </div>
    </div>
  );
}

// Wireframe Header Bar
export function LoFiTopBar({
  title,
  subtitle,
  onBack,
  rightAction,
  progress,
}: {
  title?: string;
  subtitle?: string;
  onBack?: () => void;
  rightAction?: React.ReactNode;
  progress?: number; // 0 - 100
}) {
  return (
    <header className="sticky top-0 z-30 bg-white/95 backdrop-blur-xs border-b border-neutral-200">
      <div className="h-13 px-3 flex items-center justify-between gap-2">
        {/* Left Back Hitbox - min 44x44 */}
        <div className="w-11 h-11 flex items-center justify-center shrink-0">
          {onBack ? (
            <button
              onClick={onBack}
              aria-label="Back"
              className="w-10 h-10 rounded-lg flex items-center justify-center text-neutral-800 hover:bg-neutral-100 active:bg-neutral-200 cursor-pointer transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
          ) : (
            <div className="w-6 h-6 border border-neutral-300 rounded bg-neutral-100 flex items-center justify-center text-[10px] font-mono text-neutral-600">
              #
            </div>
          )}
        </div>

        {/* Center Title */}
        <div className="flex-1 text-center min-w-0 px-1">
          {title && (
            <h1 className="text-sm font-semibold text-neutral-900 truncate">
              <FillerText semantic={title} tier="primary" skeletonWidth="w-28" />
            </h1>
          )}
          {subtitle && (
            <p className="text-[11px] text-neutral-500 truncate">
              <FillerText semantic={subtitle} tier="tertiary" skeletonWidth="w-20" />
            </p>
          )}
        </div>

        {/* Right Action */}
        <div className="min-w-11 h-11 flex items-center justify-end shrink-0">
          {rightAction || (
            <div className="w-7 h-7 rounded-full border border-neutral-300 bg-neutral-100 flex items-center justify-center text-[10px] font-mono text-neutral-600">
              ···
            </div>
          )}
        </div>
      </div>

      {/* Integrated Linear Progress Bar in Grayscale */}
      {typeof progress === 'number' && (
        <div className="h-1 w-full bg-neutral-200">
          <div
            className="h-full bg-black transition-all duration-300"
            style={{ width: `${Math.min(100, Math.max(0, progress))}%` }}
          />
        </div>
      )}
    </header>
  );
}

// Wireframe Toggle Switch (Strictly Grayscale)
export function LoFiToggle({
  checked,
  onChange,
  label,
  description,
}: {
  checked: boolean;
  onChange: (val: boolean) => void;
  label: string;
  description?: string;
}) {
  return (
    <div
      onClick={() => onChange(!checked)}
      className="flex items-center justify-between p-3 rounded-lg hover:bg-neutral-50 cursor-pointer min-h-[44px] transition-colors"
    >
      <div className="flex-1 pr-3">
        <p className="text-sm font-medium text-neutral-900">
          <FillerText semantic={label} tier="secondary" skeletonWidth="w-32" />
        </p>
        {description && (
          <p className="text-xs text-neutral-500 mt-0.5">
            <FillerText semantic={description} tier="tertiary" skeletonWidth="w-48" />
          </p>
        )}
      </div>
      <div
        className={`w-12 h-6.5 flex items-center rounded-full p-0.5 transition-colors cursor-pointer border ${
          checked ? 'bg-black border-black' : 'bg-neutral-200 border-neutral-300'
        }`}
      >
        <div
          className={`bg-white w-5 h-5 rounded-full shadow-xs transform transition-transform ${
            checked ? 'translate-x-5.5' : 'translate-x-0'
          }`}
        />
      </div>
    </div>
  );
}

// Bottom Tab Bar (Strictly Grayscale)
export function LoFiTabBar({
  activeTab,
  onSelectTab,
}: {
  activeTab: 'home' | 'practice' | 'progress' | 'profile';
  onSelectTab: (tab: 'home' | 'practice' | 'progress' | 'profile') => void;
}) {
  const tabs = [
    { id: 'home', label: 'Home', glyph: '⌂' },
    { id: 'practice', label: 'Practice', glyph: '▦' },
    { id: 'progress', label: 'Stats', glyph: '◷' },
    { id: 'profile', label: 'Profile', glyph: '○' },
  ] as const;

  return (
    <nav className="sticky bottom-0 z-40 bg-white border-t border-neutral-200 py-1.5 px-2">
      <div className="grid grid-cols-4 gap-1">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onSelectTab(tab.id)}
              className={`min-h-[46px] flex flex-col items-center justify-center rounded-lg transition-colors cursor-pointer ${
                isActive ? 'bg-neutral-100 text-black font-semibold' : 'text-neutral-500 hover:text-black'
              }`}
            >
              <span className={`text-base leading-none mb-1 font-mono ${isActive ? 'scale-110 font-bold' : ''}`}>
                {tab.glyph}
              </span>
              <span className="text-[10px] tracking-tight">
                <FillerText
                  semantic={tab.label.toUpperCase()}
                  tier="primary"
                  skeletonWidth="w-8"
                />
              </span>
              {isActive && <div className="w-1.5 h-1.5 bg-black rounded-full mt-0.5" />}
            </button>
          );
        })}
      </div>
    </nav>
  );
}
