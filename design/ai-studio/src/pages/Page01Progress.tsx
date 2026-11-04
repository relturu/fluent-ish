import React, { useState } from 'react';
import { Search, Flame } from 'lucide-react';
import {
  ActiveViewId,
  DAILY_SPANISH_VOCAB,
  DifficultyLevel,
  UserStats,
  VocabWord,
} from '../types';
import {
  PageTopBar,
  AudioButton,
  StreakIndicator,
  ConfettiBurst,
  useTheme,
} from '../components/common/HiFiElements';
import { ChurroMascot } from '../components/common/Mascot';

export function Page01Progress({
  selectedDifficulty: _selectedDifficulty,
  onSelectDifficulty: _onSelectDifficulty,
  userStats,
  onOpenRules,
}: {
  onNavigate?: (view: ActiveViewId) => void;
  selectedDifficulty?: DifficultyLevel;
  onSelectDifficulty?: (diff: DifficultyLevel) => void;
  userStats?: UserStats;
  onOpenRules?: () => void;
}) {
  const { darkMode } = useTheme();
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const [celebrationData, setCelebrationData] = useState<{ message: string } | null>(null);

  // Fallback defaults if not supplied
  const stats = userStats || {
    totalXP: 1420,
    totalScore: 850,
    streakCount: 14,
    streakCountedToday: false,
    lastActiveDate: '',
  };

  const currentLevel = Math.floor(stats.totalXP / 1500) + 1;
  const currentLevelXP = stats.totalXP % 1500;
  const progressPercent = Math.min(100, Math.round((currentLevelXP / 1500) * 100));

  const categories = [
    'All',
    'Connector',
    'Café & Dining',
    'Daily Verb',
    'Culture & Idioms',
  ];

  const filteredWords: VocabWord[] = DAILY_SPANISH_VOCAB.filter((w) => {
    if (selectedCategory !== 'All' && w.partOfSpeech !== selectedCategory) {
      return false;
    }
    if (
      searchQuery.trim() !== '' &&
      !w.spanish.toLowerCase().includes(searchQuery.toLowerCase()) &&
      !w.english.toLowerCase().includes(searchQuery.toLowerCase())
    ) {
      return false;
    }
    return true;
  });

  // 28-day activity levels: 0 (none), 1 (light), 2 (medium), 3 (high)
  // Single-color heatmap values: darkness directly reflects activity amount
  const dayActivityLevels = [
    1, 2, 3, 2, 1, 2, 3,
    2, 3, 3, 1, 2, 3, 2,
    3, 3, 2, 3, 3, 2, 3,
    2, 3, 3, 2, 3, 3, stats.streakCountedToday ? 3 : 2,
  ];

  return (
    <div className="flex flex-col flex-1 relative">
      {celebrationData && (
        <ConfettiBurst
          message={celebrationData.message}
          onDone={() => setCelebrationData(null)}
        />
      )}

      <PageTopBar
        title="Progress"
        rightAction={
          <div className="flex items-center gap-2 select-none">
            {onOpenRules && (
              <button
                type="button"
                onClick={onOpenRules}
                className="text-[11px] font-extrabold text-[#7B5CFF] px-2 py-1 rounded-xl bg-[#7B5CFF]/10 hover:bg-[#7B5CFF]/20 border border-[#7B5CFF]/25 cursor-pointer transition-colors"
              >
                Rules
              </button>
            )}
            <StreakIndicator
              streakCount={stats.streakCount}
              streakCountedToday={stats.streakCountedToday}
              onClick={() => {
                setCelebrationData({
                  message: `¡${stats.streakCount} días en racha! · ${stats.streakCount}-day streak! 🔥`,
                });
              }}
            />
          </div>
        }
      />

      <div className="px-4 py-5 space-y-6">
        {/* 1. Player Stats */}
        <section className="space-y-3.5">
          <div className="flex items-center justify-between">
            <h2 className="type-h2">Player Stats</h2>
            <button
              type="button"
              onClick={onOpenRules}
              className="px-2.5 py-0.5 rounded-full text-[11px] font-extrabold uppercase tracking-wide bg-[#7B5CFF]/15 text-[#7B5CFF] border border-[#7B5CFF]/30 cursor-pointer hover:scale-105 active:scale-95 transition-transform"
              title="Level Rules"
            >
              Level {currentLevel}
            </button>
          </div>

          {/* XP Progress Bar */}
          <div
            onClick={onOpenRules}
            className="space-y-1.5 cursor-pointer hover:opacity-95 transition-opacity"
            title="Tap to view Level up rules"
          >
            <div className="flex items-center justify-between text-[11px] font-bold opacity-75">
              <span>XP</span>
              <span className="tabular-nums text-[#7B5CFF] font-extrabold">
                {currentLevelXP.toLocaleString()} / 1,500
              </span>
            </div>
            <div className="h-2.5 w-full rounded-full bg-current/10 overflow-hidden p-0.5">
              <div
                className="h-full rounded-full bg-[#FF6B2C] transition-all duration-300"
                style={{ width: `${progressPercent}%` }}
              />
            </div>
          </div>

          {/* 3 Core Stats Cards */}
          <div className="grid grid-cols-3 gap-2.5 pt-1">
            <div
              className={`p-3.5 rounded-[20px] border text-center transition-colors shadow-xs ${
                darkMode
                  ? 'bg-[#221E52] border-white/10'
                  : 'bg-white border-[#1F1B4D]/10'
              }`}
            >
              <span className="type-h2 text-[#FF6B2C] block tabular-nums">
                312
              </span>
              <span className="text-[11px] opacity-65 font-bold uppercase tracking-wider block mt-0.5">
                Words
              </span>
            </div>
            <div
              className={`p-3.5 rounded-[20px] border text-center transition-colors shadow-xs ${
                darkMode
                  ? 'bg-[#221E52] border-white/10'
                  : 'bg-white border-[#1F1B4D]/10'
              }`}
            >
              <span className="type-h2 text-[#19C3B1] block tabular-nums">
                89%
              </span>
              <span className="text-[11px] opacity-65 font-bold uppercase tracking-wider block mt-0.5">
                Recall
              </span>
            </div>
            <div
              onClick={() =>
                setCelebrationData({
                  message: '¡14 días invictos! · 14-day streak! 🔥',
                })
              }
              className={`p-3.5 rounded-[20px] border text-center transition-all shadow-xs cursor-pointer hover:scale-105 active:scale-95 ${
                darkMode
                  ? 'bg-[#221E52] border-white/10'
                  : 'bg-white border-[#1F1B4D]/10'
              }`}
              title="Celebrate 14-day streak!"
            >
              <span className="type-h2 text-[#FF6B2C] flex items-center justify-center gap-1 tabular-nums">
                <Flame className="w-4 h-4 fill-current animate-flame-glow shrink-0" />
                {stats.streakCount}
              </span>
              <span className="text-[11px] opacity-65 font-bold uppercase tracking-wider block mt-0.5">
                Streak
              </span>
            </div>
          </div>
        </section>

        {/* 2. Quest Path (Single Color Activity Heatmap) */}
        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="type-h2">Quest Path</h2>
          </div>

          <div
            className={`p-4 rounded-[22px] border space-y-3 shadow-xs ${
              darkMode
                ? 'bg-[#221E52] border-white/10'
                : 'bg-white border-[#1F1B4D]/10'
            }`}
          >
            {/* 28-Day Grid in a single color (#FF6B2C), darkness represents activity */}
            <div className="grid grid-cols-7 gap-1.5">
              {Array.from({ length: 28 }).map((_, i) => {
                const isToday = i === 27;
                const level = dayActivityLevels[i] ?? 1;

                // Single color intensity scale:
                // Level 0: lightest tint
                // Level 1: light shade
                // Level 2: medium-deep shade
                // Level 3: solid deep shade
                const cellBg =
                  level === 3
                    ? 'bg-[#FF6B2C] text-white font-extrabold'
                    : level === 2
                    ? 'bg-[#FF6B2C]/65 text-white font-bold'
                    : level === 1
                    ? darkMode
                      ? 'bg-[#FF6B2C]/30 text-white/90 font-medium'
                      : 'bg-[#FF6B2C]/30 text-[#1F1B4D] font-medium'
                    : darkMode
                    ? 'bg-[#FF6B2C]/10 text-white/40'
                    : 'bg-[#FF6B2C]/10 text-[#1F1B4D]/40';

                return (
                  <div
                    key={i}
                    title={isToday ? `Today · Day 28 (Level ${level})` : `Day ${i + 1} (Activity: ${level})`}
                    className={`h-7 rounded-lg flex items-center justify-center text-[10px] select-none transition-transform active:scale-95 ${cellBg} ${
                      isToday
                        ? 'ring-2 ring-[#FF6B2C] ring-offset-2 ring-offset-transparent shadow-sm scale-105'
                        : ''
                    }`}
                  >
                    {isToday ? '★ 28' : i + 1}
                  </div>
                );
              })}
            </div>

            {/* Single Color Activity Intensity Legend */}
            <div className="flex items-center justify-between pt-2 border-t border-current/10 text-[11px] font-semibold opacity-70">
              <span>Activity</span>
              <div className="flex items-center gap-1.5">
                <span className="text-[10px]">Less</span>
                <span className="w-3 h-3 rounded-xs bg-[#FF6B2C]/10 border border-[#FF6B2C]/20" title="Low" />
                <span className="w-3 h-3 rounded-xs bg-[#FF6B2C]/30" title="Moderate" />
                <span className="w-3 h-3 rounded-xs bg-[#FF6B2C]/65" title="High" />
                <span className="w-3 h-3 rounded-xs bg-[#FF6B2C]" title="Max" />
                <span className="text-[10px]">More</span>
              </div>
            </div>
          </div>
        </section>

        {/* 3. Word Log */}
        <section className="space-y-3 pb-4">
          <div className="flex items-baseline justify-between">
            <h2 className="type-h2">Word Log</h2>
          </div>

          <div
            className={`p-4 rounded-[24px] border space-y-3.5 shadow-xs ${
              darkMode
                ? 'bg-[#221E52] border-white/10'
                : 'bg-white border-[#1F1B4D]/10'
            }`}
          >
            {/* Search Input */}
            <div className="relative">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 opacity-40" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search words..."
                className={`w-full h-9 pl-9 pr-3 rounded-xl border text-[13px] font-medium focus:outline-none ${
                  darkMode
                    ? 'bg-[#17143A] border-white/15 text-[#FFF8EC] placeholder-white/40'
                    : 'bg-[#FFF8EC] border-[#1F1B4D]/15 text-[#1F1B4D] placeholder-[#1F1B4D]/40'
                }`}
              />
            </div>

            {/* Category Filter Tabs */}
            <div className="flex gap-1.5 overflow-x-auto pb-0.5 scrollbar-none">
              {categories.map((cat) => {
                const active = selectedCategory === cat;
                return (
                  <button
                    key={cat}
                    type="button"
                    onClick={() => setSelectedCategory(cat)}
                    className={`px-3 py-1.5 rounded-xl text-[11px] font-extrabold whitespace-nowrap cursor-pointer transition-colors ${
                      active
                        ? 'bg-[#FF6B2C] text-white shadow-xs'
                        : darkMode
                        ? 'bg-[#17143A] text-[#FFF8EC]/70 hover:text-[#FFF8EC]'
                        : 'bg-[#1F1B4D]/8 text-[#1F1B4D]/75 hover:text-[#1F1B4D]'
                    }`}
                  >
                    {cat}
                  </button>
                );
              })}
            </div>

            {/* Word List */}
            <div className="divide-y divide-current/10 border-t border-current/10 pt-1">
              {filteredWords.length === 0 ? (
                <div className="py-8 text-center flex flex-col items-center justify-center gap-2">
                  <ChurroMascot
                    mood="thinking"
                    size="sm"
                    speech="No encontré esa palabra... ¡prueba otra!"
                    speechPosition="top"
                  />
                  <p className="text-[12px] opacity-60 font-semibold mt-1">
                    No matching vocabulary found
                  </p>
                </div>
              ) : (
                filteredWords.map((word) => (
                  <div
                    key={word.id}
                    className="py-2.5 flex items-center justify-between gap-3"
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-[14px] font-extrabold text-[#FF6B2C] truncate">
                          {word.spanish}
                        </span>
                        <span className="text-[10px] font-bold opacity-50 shrink-0">
                          {word.partOfSpeech}
                        </span>
                      </div>
                      <p className="text-[12px] opacity-75 truncate mt-0.5 font-medium">
                        {word.english}
                      </p>
                    </div>
                    <AudioButton text={word.spanish} size="sm" />
                  </div>
                ))
              )}
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
