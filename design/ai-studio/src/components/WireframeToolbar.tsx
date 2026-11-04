import React from 'react';
import {
  Smartphone,
  Monitor,
  FileText,
  Moon,
  Sun,
  RotateCcw,
} from 'lucide-react';
import { ActiveViewId, MainTabId } from '../types';
import { HiFiButton, useTheme } from './common/HiFiElements';

export function WireframeToolbar({
  activeView,
  onSelectView,
  isDeviceMode,
  onToggleDeviceMode,
  onOpenDesignDoc,
  onOpenRules,
  onResetAll,
}: {
  activeView: ActiveViewId;
  onSelectView: (view: ActiveViewId) => void;
  isDeviceMode: boolean;
  onToggleDeviceMode: () => void;
  onOpenDesignDoc: () => void;
  onOpenRules?: () => void;
  onResetAll: () => void;
}) {
  const { darkMode, setDarkMode } = useTheme();

  const mainNavPages: { id: MainTabId; label: string }[] = [
    { id: 'daily', label: 'Today' },
    { id: 'progress', label: 'Progress' },
    { id: 'friends', label: 'Friends' },
    { id: 'settings', label: 'Settings' },
  ];

  const activeMainTab: MainTabId =
    activeView === 'progress'
      ? 'progress'
      : activeView === 'friends'
      ? 'friends'
      : activeView === 'settings'
      ? 'settings'
      : 'daily';

  return (
    <header className="sticky top-0 z-40 bg-[#1F1B4D] text-[#FFF8EC] border-b border-white/10 shadow-sm">
      <div className="max-w-5xl mx-auto px-4 py-2.5 flex items-center justify-between gap-3">
        {/* Brand Title */}
        <a
          href="#daily"
          onClick={(e) => {
            e.preventDefault();
            onSelectView('daily');
          }}
          className="text-[17px] font-extrabold text-white tracking-tight flex items-center cursor-pointer select-none"
        >
          <span>Fluent</span>
          <span
            className="text-[#FF6B2C] font-black mx-0.5 leading-none inline-block"
            style={{ color: '#FF6B2C' }}
          >
            •
          </span>
          <span>ish</span>
        </a>

        {/* Main Navigation Links */}
        <nav className="hidden sm:flex items-center gap-1.5">
          <button
            type="button"
            onClick={() => onSelectView('onboarding')}
            aria-current={activeView === 'onboarding' ? 'page' : undefined}
            className={`text-[13px] px-3 py-1.5 rounded-xl transition-all cursor-pointer font-bold ${
              activeView === 'onboarding'
                ? 'text-white bg-[#FF6B2C] shadow-xs'
                : 'text-[#FFF8EC]/75 hover:text-white hover:bg-white/10'
            }`}
          >
            Onboarding
          </button>
          {mainNavPages.map((p) => {
            const isCurrent = activeView !== 'onboarding' && activeMainTab === p.id;
            return (
              <button
                key={p.id}
                type="button"
                onClick={() => onSelectView(p.id)}
                aria-current={isCurrent ? 'page' : undefined}
                className={`text-[13px] px-3 py-1.5 rounded-xl transition-all cursor-pointer font-bold ${
                  isCurrent
                    ? 'text-white bg-[#FF6B2C] shadow-xs'
                    : 'text-[#FFF8EC]/75 hover:text-white hover:bg-white/10'
                }`}
              >
                {p.label}
              </button>
            );
          })}
        </nav>

        {/* Compact Actions */}
        <div className="flex items-center gap-1.5">
          {onOpenRules && (
            <button
              type="button"
              onClick={onOpenRules}
              className="text-[12px] font-extrabold text-[#FFC93C] bg-white/10 hover:bg-white/15 px-3 py-1.5 rounded-xl border border-white/15 cursor-pointer transition-colors flex items-center gap-1"
              title="Game Rules"
            >
              <span>⚡ Rules</span>
            </button>
          )}

          <HiFiButton
            size="sm"
            variant="primary"
            onClick={onOpenDesignDoc}
            icon={<FileText className="w-3.5 h-3.5" />}
          >
            Design Doc
          </HiFiButton>

          <button
            type="button"
            onClick={() => setDarkMode(!darkMode)}
            className="w-9 h-9 rounded-xl bg-white/10 hover:bg-white/15 text-[#FFF8EC] flex items-center justify-center cursor-pointer transition-colors"
            title="Toggle Dark Mode"
            aria-label="Toggle Dark Mode"
          >
            {darkMode ? (
              <Sun className="w-4 h-4 text-[#FFC93C]" />
            ) : (
              <Moon className="w-4 h-4 text-[#7B5CFF]" />
            )}
          </button>

          <button
            type="button"
            onClick={onToggleDeviceMode}
            className="w-9 h-9 rounded-xl bg-white/10 hover:bg-white/15 text-[#FFF8EC] flex items-center justify-center cursor-pointer transition-colors"
            title="Toggle Device Frame"
            aria-label="Toggle Device Frame"
          >
            {isDeviceMode ? (
              <Monitor className="w-4 h-4" />
            ) : (
              <Smartphone className="w-4 h-4" />
            )}
          </button>

          <button
            type="button"
            onClick={onResetAll}
            className="w-9 h-9 rounded-xl bg-white/10 hover:bg-white/15 text-[#FFF8EC] flex items-center justify-center cursor-pointer transition-colors"
            title="Reset All Progress"
            aria-label="Reset All Progress"
          >
            <RotateCcw className="w-4 h-4" />
          </button>
        </div>
      </div>
    </header>
  );
}
