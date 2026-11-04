import React from 'react';
import { X, CheckCircle, AlertTriangle, Ruler, Shield, MousePointer, Layers } from 'lucide-react';

export function DesignCritiqueModal({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  if (!isOpen) return null;

  const critiqueItems = [
    {
      category: 'Touch Targets & Ergonomics',
      icon: <MousePointer className="w-4 h-4 text-black" />,
      issue: 'Sub-44px Touch Targets in Filter Pills & Grids',
      original:
        'In the original mid-fi wireframes (especially in 01D language chips, 04B keyboard keys, and 07A calendar dates), touch targets measured under 32px height, violating standard Apple Human Interface Guidelines and WCAG touch target minimums (44×44px).',
      correction:
        'All interactive buttons, chips, and keyboard keys now enforce min-h-[44px] (or key touch hitboxes with generous tap bounds) with clear 8px spacing to eliminate thumb miss-taps.',
    },
    {
      category: 'Header & Navigation Alignment',
      icon: <Ruler className="w-4 h-4 text-black" />,
      issue: 'Jumping Headers & Disjointed Progress Bars',
      original:
        'Onboarding screens 1D–1G had inconsistent top bar heights (varying between 44px and 68px). In some screens, the back arrow sat inline with the percentage text; in others, it was placed above or lacked symmetric right padding.',
      correction:
        'Standardized a unified 52px sticky Top Bar across all 8 flows. Back hitboxes are fixed at 44×44px, and the step progress bar is docked flush beneath the header border as an integrated 4px indicator.',
    },
    {
      category: 'Layout Clutter & Bottom Tab Collision',
      icon: <Layers className="w-4 h-4 text-black" />,
      issue: 'Bottom Tab Bar Competing with Game Action Bars',
      original:
        'During active game sessions (Connections submit row, Word Guess virtual keyboard, Crossword clue bar), the mid-fi wireframe either retained the bottom navigation bar or crammed dual action bars into the lower thumb zone.',
      correction:
        'Implemented contextual navigation: active game runs and onboarding flows hide the global bottom tab bar entirely, giving full thumb-zone focus to gameplay controls and avoiding stacked sticky bars exceeding the 15% mobile viewport cap.',
    },
    {
      category: 'Grid Proportions & Tile Sizing',
      icon: <Ruler className="w-4 h-4 text-black" />,
      issue: 'Irregular Aspect Ratios & Text Wrapping in 4×4 Grid',
      original:
        'The 16 tiles in Flow 03 Connections had uneven line wraps on longer terms, and the "Deselect All / Submit" action bar sat too close to the bottom tiles without adequate clearance.',
      correction:
        'Adopted a uniform CSS grid (h-16 tiles with min-w-0 truncation escape) with standardized 8px gutters and a dedicated 16px bottom action zone with disabled state affordances.',
    },
    {
      category: 'Modal Dialog Ergonomics',
      icon: <AlertTriangle className="w-4 h-4 text-black" />,
      issue: 'Arbitrary Floating Popups Without Scrim Hierarchy',
      original:
        'Confirmation patterns in Flow 08 (Leave game, Change language, Sign out) floated with varying corner radii and lacked backdrop dimming, creating visual ambiguity against background list items.',
      correction:
        'Standardized modal patterns into two distinct mobile archetypes: Bottom Sheets with grab handles for assisted actions (Reveal clue, Share card) and centered Dialogs with bg-black/40 blur scrim for destructive confirmations.',
    },
    {
      category: 'Lo-Fi Aesthetic Discipline',
      icon: <Shield className="w-4 h-4 text-black" />,
      issue: 'Reliance on Color for Game State & Category Meaning',
      original:
        'The original mid-fi wireframes used color fills (yellow, green, blue, purple) to indicate category groupings and feedback states, which breaks lo-fi clarity.',
      correction:
        'Replaced all color fills with a disciplined grayscale hierarchy (white, 5% neutral, 15% neutral, 25% neutral, 90% black) paired with explicit typographic identifiers, ensuring accessibility for color-blind learners.',
    },
  ];

  return (
    <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl border border-neutral-300 max-w-2xl w-full max-h-[85vh] flex flex-col shadow-2xl overflow-hidden">
        {/* Modal Header */}
        <div className="px-5 py-4 border-b border-neutral-200 flex items-center justify-between bg-neutral-50">
          <div>
            <h2 className="text-base font-bold text-neutral-900">
              UX Critique & Spacing Corrections
            </h2>
            <p className="text-xs text-neutral-500">
              Analysis of spacing, placement, and ergonomic violations corrected from the original mid-fi design
            </p>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg border border-neutral-300 hover:bg-neutral-200 flex items-center justify-center text-neutral-700 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-5 overflow-y-auto space-y-4">
          <div className="p-3 bg-neutral-100 rounded-xl border border-neutral-200 text-xs text-neutral-700 flex items-start gap-2.5">
            <CheckCircle className="w-4 h-4 text-black shrink-0 mt-0.5" />
            <p>
              In accordance with your instructions, all screens have been converted to strict <strong>lo-fi wireframe structure</strong> using filler copy, light grayscale tints (no real colors or images), and corrected standard mobile UX spacing rules.
            </p>
          </div>

          <div className="space-y-3">
            {critiqueItems.map((item, idx) => (
              <div
                key={idx}
                className="p-4 rounded-xl border border-neutral-200 bg-white space-y-2 shadow-2xs"
              >
                <div className="flex items-center gap-2">
                  <div className="w-6 h-6 rounded bg-neutral-100 flex items-center justify-center shrink-0">
                    {item.icon}
                  </div>
                  <div>
                    <span className="text-[10px] font-mono uppercase text-neutral-400 font-semibold block">
                      {item.category}
                    </span>
                    <h3 className="text-sm font-bold text-neutral-900">{item.issue}</h3>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-xs pt-1">
                  <div className="p-2.5 rounded-lg bg-neutral-50 border border-neutral-200 space-y-1">
                    <span className="font-mono text-[10px] text-neutral-500 uppercase font-semibold block">
                      Mid-Fi Issue
                    </span>
                    <p className="text-neutral-600 leading-relaxed">{item.original}</p>
                  </div>
                  <div className="p-2.5 rounded-lg bg-neutral-100 border border-neutral-300 space-y-1">
                    <span className="font-mono text-[10px] text-neutral-900 uppercase font-semibold block">
                      Lo-Fi Standard Fix
                    </span>
                    <p className="text-neutral-800 leading-relaxed font-medium">
                      {item.correction}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Modal Footer */}
        <div className="px-5 py-3 border-t border-neutral-200 bg-neutral-50 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-black text-white rounded-lg text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          >
            Close Critique
          </button>
        </div>
      </div>
    </div>
  );
}
