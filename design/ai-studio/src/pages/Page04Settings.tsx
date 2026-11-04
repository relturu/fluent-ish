import React, { useState } from 'react';
import {
  AlertTriangle,
  Moon,
  Sun,
  Check,
  Flame,
} from 'lucide-react';
import { ActiveViewId, UserStats } from '../types';
import {
  HiFiButton,
  PageTopBar,
  StreakIndicator,
  useTheme,
} from '../components/common/HiFiElements';

export function Page04Settings({
  onResetProgress,
  userStats,
  onNavigate,
  onOpenRules,
}: {
  onResetProgress: () => void;
  userStats?: UserStats;
  onNavigate?: (view: ActiveViewId) => void;
  onOpenRules?: () => void;
}) {
  const { darkMode, setDarkMode } = useTheme();
  const [dailyGoalMinutes, setDailyGoalMinutes] = useState<number>(10);
  const [activeLanguage, setActiveLanguage] = useState<string>('Spanish');
  const [pendingLanguage, setPendingLanguage] = useState<string | null>(null);
  const [remindersEnabled, setRemindersEnabled] = useState<boolean>(true);
  const [autoAudio, setAutoAudio] = useState<boolean>(true);
  const [savedNotice, setSavedNotice] = useState<string | null>(null);

  const stats = userStats || {
    totalXP: 1420,
    totalScore: 850,
    streakCount: 14,
    streakCountedToday: false,
    lastActiveDate: '',
  };

  const currentLevel = Math.floor(stats.totalXP / 1500) + 1;

  const availableLanguages = [
    { name: 'Spanish', code: 'ES' },
    { name: 'French', code: 'FR' },
    { name: 'Italian', code: 'IT' },
    { name: 'Portuguese', code: 'PT' },
  ];

  const handleConfirmLanguageSwitch = () => {
    if (!pendingLanguage) return;
    setActiveLanguage(pendingLanguage);
    setPendingLanguage(null);
    onResetProgress();
    setSavedNotice(`Switched to ${pendingLanguage}. Progress reset.`);
    setTimeout(() => setSavedNotice(null), 2500);
  };

  return (
    <div className="flex flex-col flex-1">
      <PageTopBar
        title="Settings"
        rightAction={
          <div className="flex items-center gap-2 select-none">
            <StreakIndicator
              streakCount={stats.streakCount}
              streakCountedToday={stats.streakCountedToday}
              onClick={onOpenRules}
            />
          </div>
        }
      />

      <div className="px-4 py-5 space-y-6">
        {savedNotice && (
          <div className="p-3 rounded-2xl bg-[#FF6B2C] text-white text-[12px] font-bold flex items-center justify-between shadow-xs">
            <span>{savedNotice}</span>
            <Check className="w-4 h-4 stroke-[3]" />
          </div>
        )}

        {/* Player Profile Header */}
        <section
          className={`p-4 rounded-[24px] border shadow-xs flex items-center justify-between gap-3 ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-[#FF6B2C] text-white flex items-center justify-center text-[15px] font-extrabold shadow-sm">
              SM
            </div>
            <div>
              <h2 className="text-[16px] font-extrabold">Sofía Martínez</h2>
              <span className="text-[12px] opacity-65 font-medium">
                {activeLanguage} · {stats.streakCount}d streak ({stats.streakCountedToday ? 'Counted Today ✓' : 'Pending'})
              </span>
            </div>
          </div>

          <span className="px-3 py-1 rounded-full text-[11px] font-extrabold uppercase tracking-wide bg-[#7B5CFF]/15 text-[#7B5CFF] border border-[#7B5CFF]/30">
            Level {currentLevel}
          </span>
        </section>

        {/* Daily Goal */}
        <section
          className={`p-4 rounded-[22px] border space-y-3 shadow-xs ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <div className="flex items-baseline justify-between">
            <h3 className="type-h2">Daily Goal</h3>
            <span className="text-[12px] font-extrabold text-[#FF6B2C]">
              {dailyGoalMinutes} min
            </span>
          </div>

          <div className="grid grid-cols-4 gap-2">
            {[5, 10, 15, 20].map((mins) => {
              const isSelected = dailyGoalMinutes === mins;
              return (
                <button
                  key={mins}
                  type="button"
                  onClick={() => setDailyGoalMinutes(mins)}
                  className={`h-11 rounded-xl text-[13px] font-extrabold transition-all cursor-pointer min-h-[44px] ${
                    isSelected
                      ? 'btn-3d-primary'
                      : 'border border-current/15 opacity-70 hover:opacity-100'
                  }`}
                >
                  {mins}m
                </button>
              );
            })}
          </div>
        </section>

        {/* Language Selection */}
        <section
          className={`p-4 rounded-[22px] border space-y-3 shadow-xs ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <h3 className="type-h2">Language</h3>
          <div className="grid grid-cols-2 gap-2">
            {availableLanguages.map((lang) => {
              const isCurrent = activeLanguage === lang.name;
              return (
                <button
                  key={lang.name}
                  type="button"
                  onClick={() => {
                    if (!isCurrent) setPendingLanguage(lang.name);
                  }}
                  className={`p-3.5 rounded-xl border flex items-center justify-between text-left cursor-pointer transition-colors min-h-[44px] ${
                    isCurrent
                      ? 'border-[#FF6B2C] bg-[#FF6B2C]/10 font-extrabold'
                      : 'border-current/15 opacity-75 hover:opacity-100'
                  }`}
                >
                  <span className="text-[14px] font-bold">{lang.name}</span>
                  <span className="text-[11px] font-extrabold text-[#FF6B2C]">
                    {isCurrent ? 'Active' : lang.code}
                  </span>
                </button>
              );
            })}
          </div>
        </section>

        {/* Preferences Rows */}
        <section
          className={`p-4 rounded-[22px] border space-y-3 shadow-xs pb-2 ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <h3 className="type-h2">Preferences</h3>

          <div className="divide-y divide-current/10">
            <div className="py-3 flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                {darkMode ? (
                  <Moon className="w-4 h-4 text-[#7B5CFF]" />
                ) : (
                  <Sun className="w-4 h-4 text-[#FF6B2C]" />
                )}
                <span className="text-[14px] font-bold">Dark Mode</span>
              </div>
              <HiFiButton
                size="sm"
                variant={darkMode ? 'primary' : 'outline'}
                onClick={() => setDarkMode(!darkMode)}
              >
                {darkMode ? 'On' : 'Off'}
              </HiFiButton>
            </div>

            <div className="py-3 flex items-center justify-between">
              <span className="text-[14px] font-bold">Spanish Audio</span>
              <HiFiButton
                size="sm"
                variant={autoAudio ? 'aqua' : 'outline'}
                onClick={() => setAutoAudio(!autoAudio)}
              >
                {autoAudio ? 'On' : 'Off'}
              </HiFiButton>
            </div>

            <div className="py-3 flex items-center justify-between">
              <span className="text-[14px] font-bold">Daily Reminder</span>
              <HiFiButton
                size="sm"
                variant={remindersEnabled ? 'aqua' : 'outline'}
                onClick={() => setRemindersEnabled(!remindersEnabled)}
              >
                {remindersEnabled ? 'On' : 'Off'}
              </HiFiButton>
            </div>

            {onNavigate && (
              <div className="py-3 flex items-center justify-between">
                <div>
                  <span className="text-[14px] font-bold block">Onboarding Tour</span>
                  <span className="text-[11px] opacity-65 font-medium">Revisit setup questions & mascot welcome</span>
                </div>
                <HiFiButton
                  size="sm"
                  variant="outline"
                  onClick={() => onNavigate('onboarding')}
                >
                  Replay
                </HiFiButton>
              </div>
            )}
          </div>
        </section>
      </div>

      {/* Warning Modal on Language Change */}
      {pendingLanguage && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div
            className={`w-full max-w-xs rounded-[24px] p-5 space-y-4 border shadow-2xl ${
              darkMode
                ? 'bg-[#221E52] border-[#FF6B2C] text-[#FFF8EC]'
                : 'bg-white border-[#FF6B2C] text-[#1F1B4D]'
            }`}
          >
            <div className="flex items-center gap-2 text-[#FF6B2C]">
              <AlertTriangle className="w-5 h-5 shrink-0" />
              <h3 className="text-[15px] font-extrabold">
                Switch to {pendingLanguage}?
              </h3>
            </div>

            <p className="text-[13px] leading-relaxed opacity-85">
              Changing your language will reset your current Spanish progress and 14-day streak.
            </p>

            <div className="space-y-2 pt-1">
              <HiFiButton
                fullWidth
                size="sm"
                variant="outline"
                onClick={() => setPendingLanguage(null)}
              >
                Keep {activeLanguage}
              </HiFiButton>
              <HiFiButton
                fullWidth
                size="sm"
                variant="primary"
                onClick={handleConfirmLanguageSwitch}
              >
                Switch & Reset
              </HiFiButton>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
