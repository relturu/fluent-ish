import React from 'react';
import { X, Flame, Award, Zap, Trophy, CheckCircle2 } from 'lucide-react';
import { HiFiButton, useTheme } from './common/HiFiElements';

export function RulesModal({
  isOpen,
  onClose,
  totalXP,
  streakCount,
  streakCountedToday,
  level,
}: {
  isOpen: boolean;
  onClose: () => void;
  totalXP: number;
  streakCount: number;
  streakCountedToday: boolean;
  level: number;
}) {
  const { darkMode } = useTheme();

  if (!isOpen) return null;

  const currentLevelXP = totalXP % 1500;
  const xpNeeded = 1500 - currentLevelXP;
  const progressPercent = Math.min(100, Math.round((currentLevelXP / 1500) * 100));

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-fadeIn"
      onClick={onClose}
    >
      <div
        className={`w-full max-w-sm rounded-[28px] border p-5 space-y-4 shadow-2xl animate-scale-bounce transition-colors ${
          darkMode
            ? 'bg-[#1D1946] border-white/15 text-[#FFF8EC]'
            : 'bg-white border-[#1F1B4D]/15 text-[#1F1B4D]'
        }`}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between pb-2 border-b border-current/10">
          <div className="flex items-center gap-2">
            <span className="p-1.5 rounded-xl bg-[#FF6B2C]/15 text-[#FF6B2C]">
              <Trophy className="w-5 h-5" />
            </span>
            <div>
              <h3 className="text-[17px] font-extrabold tracking-tight">
                Streak, Level & Score Rules
              </h3>
              <p className="text-[11px] opacity-60 font-semibold">
                Official Fluent•ish game guidelines
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full flex items-center justify-center opacity-60 hover:opacity-100 hover:bg-current/10 cursor-pointer transition-colors"
            aria-label="Close rules"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* 3 Core Rules in Crisp, Airy Cards */}
        <div className="space-y-2.5">
          {/* Rule 1: Streak */}
          <div
            className={`p-3.5 rounded-2xl border transition-colors ${
              darkMode
                ? 'bg-[#252156] border-[#FF6B2C]/30'
                : 'bg-[#FFF4ED] border-[#FF6B2C]/25'
            }`}
          >
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <span className="w-7 h-7 rounded-lg bg-[#FF6B2C] text-white flex items-center justify-center shrink-0">
                  <Flame className="w-4 h-4 fill-current" />
                </span>
                <span className="text-[13px] font-extrabold text-[#FF6B2C]">
                  Daily Streak Rule
                </span>
              </div>
              <span className="text-[11px] font-extrabold px-2 py-0.5 rounded-full bg-[#FF6B2C]/20 text-[#FF6B2C]">
                {streakCountedToday ? 'Today Counted ✓' : 'Pending Today'}
              </span>
            </div>
            <p className="text-[12px] leading-snug mt-2 font-medium opacity-90">
              A day counts when <strong>a game or lesson is finished</strong>. Complete any daily puzzle or vocab lesson to keep your fire burning!
            </p>
          </div>

          {/* Rule 2: Level Up at 1500 XP */}
          <div
            className={`p-3.5 rounded-2xl border transition-colors ${
              darkMode
                ? 'bg-[#252156] border-[#7B5CFF]/30'
                : 'bg-[#F4F1FF] border-[#7B5CFF]/25'
            }`}
          >
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <span className="w-7 h-7 rounded-lg bg-[#7B5CFF] text-white flex items-center justify-center shrink-0">
                  <Award className="w-4 h-4" />
                </span>
                <span className="text-[13px] font-extrabold text-[#7B5CFF]">
                  Level Up at 1,500 XP
                </span>
              </div>
              <span className="text-[11px] font-extrabold px-2 py-0.5 rounded-full bg-[#7B5CFF]/20 text-[#7B5CFF]">
                Level {level}
              </span>
            </div>
            <p className="text-[12px] leading-snug mt-2 font-medium opacity-90">
              Users level up at <strong>1,500 XP</strong>. Every 1,500 XP unlocks the next proficiency rank!
            </p>
            {/* XP Bar */}
            <div className="mt-2.5 pt-2 border-t border-current/10 space-y-1">
              <div className="flex items-center justify-between text-[11px] font-bold">
                <span className="opacity-70">
                  {currentLevelXP.toLocaleString()} / 1,500 XP
                </span>
                <span className="text-[#7B5CFF] font-extrabold">
                  {xpNeeded} XP to Level {level + 1}
                </span>
              </div>
              <div className="h-2 w-full rounded-full bg-current/10 overflow-hidden">
                <div
                  className="h-full rounded-full bg-[#7B5CFF] transition-all duration-300"
                  style={{ width: `${progressPercent}%` }}
                />
              </div>
            </div>
          </div>

          {/* Rule 3: Score & XP per game */}
          <div
            className={`p-3.5 rounded-2xl border transition-colors ${
              darkMode
                ? 'bg-[#252156] border-[#19C3B1]/30'
                : 'bg-[#EBFBF9] border-[#19C3B1]/25'
            }`}
          >
            <div className="flex items-center gap-2">
              <span className="w-7 h-7 rounded-lg bg-[#19C3B1] text-[#1F1B4D] flex items-center justify-center shrink-0">
                <Zap className="w-4 h-4 fill-current" />
              </span>
              <span className="text-[13px] font-extrabold text-[#19C3B1]">
                Game Score & XP Rule
              </span>
            </div>
            <p className="text-[12px] leading-snug mt-2 font-medium opacity-90">
              <strong>Each game gives a score and XP</strong>. Both performance points (0–100) and XP rewards (25–40+ XP) are added to your profile immediately.
            </p>
            <div className="grid grid-cols-2 gap-1.5 mt-2.5 pt-2 border-t border-current/10 text-[11px] font-bold opacity-80">
              <div className="flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5 text-[#19C3B1]" />
                <span>Puzzles: +40 XP</span>
              </div>
              <div className="flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5 text-[#19C3B1]" />
                <span>Vocab Lesson: +30 XP</span>
              </div>
            </div>
          </div>
        </div>

        {/* Dismiss Button */}
        <div className="pt-1">
          <HiFiButton fullWidth size="lg" variant="primary" onClick={onClose}>
            Got It!
          </HiFiButton>
        </div>
      </div>
    </div>
  );
}
