import React from 'react';
import { Award, ArrowRight } from 'lucide-react';
import { HiFiButton, useTheme } from './common/HiFiElements';
import { ChurroMascot } from './common/Mascot';

export function LevelUpModal({
  isOpen,
  newLevel,
  totalXP,
  onClose,
}: {
  isOpen: boolean;
  newLevel: number;
  totalXP: number;
  onClose: () => void;
}) {
  const { darkMode } = useTheme();

  if (!isOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-fadeIn"
      onClick={onClose}
    >
      <div
        className={`w-full max-w-sm rounded-[32px] border-2 p-6 space-y-4 text-center shadow-2xl animate-scale-bounce transition-colors ${
          darkMode
            ? 'bg-[#1D1946] border-[#FFC93C] text-[#FFF8EC]'
            : 'bg-white border-[#FFC93C] text-[#1F1B4D]'
        }`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex justify-center -mt-3 mb-1">
          <ChurroMascot
            mood="celebrating"
            size="lg"
            speech="¡NIVEL SUPERADO! 🚀"
            speechPosition="top"
          />
        </div>

        <div className="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full bg-[#FFC93C]/20 text-[#D49C14] dark:text-[#FFC93C] border border-[#FFC93C]/40 text-[12px] font-extrabold uppercase tracking-wider">
          <Award className="w-4 h-4" />
          <span>Milestone Reached!</span>
        </div>

        <div>
          <h2 className="type-display text-[#FF6B2C]">¡Nivel {newLevel}!</h2>
          <p className="text-[14px] font-bold opacity-80 mt-1">
            You leveled up at 1,500 XP!
          </p>
          <p className="text-[12px] opacity-60 font-medium mt-0.5">
            Total XP: {totalXP.toLocaleString()} XP
          </p>
        </div>

        <div
          className={`p-3.5 rounded-2xl border text-left space-y-1 ${
            darkMode
              ? 'bg-[#252156] border-white/10'
              : 'bg-[#FFF8EC] border-[#1F1B4D]/10'
          }`}
        >
          <span className="text-[11px] font-extrabold uppercase tracking-wide text-[#7B5CFF] block">
            New Perks Unlocked
          </span>
          <p className="text-[12px] font-medium opacity-90 leading-snug">
            🌟 Level {newLevel} rank badge on leaderboards
          </p>
          <p className="text-[12px] font-medium opacity-90 leading-snug">
            🎯 Progress saved towards Level {newLevel + 1} (next at {newLevel * 1500} XP)
          </p>
        </div>

        <HiFiButton
          fullWidth
          size="lg"
          variant="primary"
          onClick={onClose}
          icon={<ArrowRight className="w-4 h-4" />}
        >
          Continue Playing
        </HiFiButton>
      </div>
    </div>
  );
}
