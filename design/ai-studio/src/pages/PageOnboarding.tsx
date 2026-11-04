import React, { useState } from 'react';
import {
  ChevronLeft,
  Check,
  Sparkles,
  Compass,
  Flame,
  Brain,
  Briefcase,
  Users,
  Music,
  Clock,
  Calendar,
  Grid,
  Hash,
  HelpCircle,
  FileText,
  Volume2,
  Gamepad2,
  Trophy,
} from 'lucide-react';
import { ActiveViewId } from '../types';
import { ChurroMascot } from '../components/common/Mascot';
import { playCelebrationSound, playSelectSound, useTheme } from '../components/common/HiFiElements';

export interface OnboardingPreferences {
  targetLanguage: string;
  motivation: string;
  dailyMinutes: number;
  weeklyFrequency: string;
  preferredGames: string[];
  startingLevel: string;
}

interface PageOnboardingProps {
  onComplete: (prefs: OnboardingPreferences) => void;
  onNavigate?: (view: ActiveViewId) => void;
}

export function PageOnboarding({ onComplete }: PageOnboardingProps) {
  const { darkMode } = useTheme();
  const [currentStep, setCurrentStep] = useState<number>(0);

  // User Selections
  const [targetLanguage, setTargetLanguage] = useState<string>('Spanish');
  const [motivation, setMotivation] = useState<string>('travel');
  const [dailyMinutes, setDailyMinutes] = useState<number>(10);
  const [weeklyFrequency, setWeeklyFrequency] = useState<string>('daily');
  const [preferredGames, setPreferredGames] = useState<string[]>([
    'connections',
    'word-guess',
    'crossword',
  ]);
  const [startingLevel, setStartingLevel] = useState<string>('beginner');

  const TOTAL_STEPS = 7;
  const progressPercent = Math.round(((currentStep + 1) / TOTAL_STEPS) * 100);

  const handleNext = () => {
    playSelectSound();
    if (currentStep < TOTAL_STEPS - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      playCelebrationSound();
      onComplete({
        targetLanguage,
        motivation,
        dailyMinutes,
        weeklyFrequency,
        preferredGames,
        startingLevel,
      });
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      playSelectSound();
      setCurrentStep(currentStep - 1);
    }
  };

  const toggleGamePreference = (gameId: string) => {
    playSelectSound();
    if (preferredGames.includes(gameId)) {
      if (preferredGames.length > 1) {
        setPreferredGames(preferredGames.filter((id) => id !== gameId));
      }
    } else {
      setPreferredGames([...preferredGames, gameId]);
    }
  };

  const handleSelectOption = (callback: () => void) => {
    playSelectSound();
    callback();
  };

  return (
    <div
      className={`flex flex-col flex-1 h-full min-h-[640px] select-none transition-colors ${
        darkMode ? 'bg-[#17143A] text-[#FFF8EC]' : 'bg-[#FFF8EC] text-[#1F1B4D]'
      }`}
    >
      {/* 1. TOP PROGRESS BAR & NAVIGATION (DUOLINGO STYLE) */}
      <header className="px-5 pt-3 pb-2 shrink-0 flex items-center gap-3">
        {currentStep > 0 ? (
          <button
            type="button"
            onClick={handleBack}
            className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all cursor-pointer ${
              darkMode
                ? 'text-[#FFF8EC]/70 hover:text-[#FFF8EC] hover:bg-white/10'
                : 'text-[#1F1B4D]/70 hover:text-[#1F1B4D] hover:bg-[#1F1B4D]/10'
            }`}
            aria-label="Previous step"
          >
            <ChevronLeft className="w-5 h-5 stroke-[2.5]" />
          </button>
        ) : (
          <div className="w-9 h-9 flex items-center justify-center">
            <Sparkles className="w-5 h-5 text-[#FF6B2C]" />
          </div>
        )}

        {/* Animated Progress Track */}
        <div
          className={`flex-1 h-3.5 rounded-full overflow-hidden p-0.5 border ${
            darkMode
              ? 'bg-[#221E52] border-white/15'
              : 'bg-[#1F1B4D]/10 border-[#1F1B4D]/10'
          }`}
        >
          <div
            className="h-full rounded-full bg-gradient-to-r from-[#FF6B2C] to-[#FF8A50] transition-all duration-300 shadow-xs"
            style={{ width: `${progressPercent}%` }}
          />
        </div>

        {/* Quick Skip Button */}
        <button
          type="button"
          onClick={() => {
            playCelebrationSound();
            onComplete({
              targetLanguage,
              motivation,
              dailyMinutes,
              weeklyFrequency,
              preferredGames,
              startingLevel,
            });
          }}
          className="text-[12px] font-extrabold uppercase tracking-wider text-[#FF6B2C] hover:opacity-80 px-2 py-1 cursor-pointer transition-opacity"
        >
          Skip
        </button>
      </header>

      {/* 2. MAIN SCROLLABLE CONTENT WITH MASCOT & QUESTION (LIGHT TEXT, NO SUBHEADINGS) */}
      <div className="flex-1 px-5 py-4 overflow-y-auto flex flex-col justify-between">
        <div className="space-y-4">
          {/* STEP 0: INITIAL WELCOME SCREEN WITH MOTTO & LUMI */}
          {currentStep === 0 && (
            <div className="space-y-6 animate-fade-in text-center py-2 flex flex-col items-center">
              {/* Mascot Hero with Language-Neutral Greeting */}
              <div className="pt-2">
                <ChurroMascot
                  mood="waving"
                  size="xl"
                  animate
                  speech="Hi, I'm Lumi!"
                  speechPosition="top"
                />
              </div>

              {/* Light Brand Title */}
              <div className="space-y-2">
                <h1 className="text-[26px] font-extrabold tracking-tight leading-tight">
                  Welcome to Fluent•ish
                </h1>
                {/* Catchy, light motto */}
                <p className="text-[14px] font-bold text-[#FF6B2C] max-w-xs mx-auto leading-snug">
                  A little daily play is all it takes to get fluent-ish.
                </p>
              </div>

              {/* Clean Feature Highlights (Equal & Light) */}
              <div className="w-full space-y-2.5 pt-1">
                {[
                  {
                    icon: <Gamepad2 className="w-5 h-5 text-[#FF6B2C]" />,
                    text: 'Daily 3-game word progression sets',
                  },
                  {
                    icon: <Clock className="w-5 h-5 text-[#7B5CFF]" />,
                    text: 'Just 10 minutes a day to build habit',
                  },
                  {
                    icon: <Trophy className="w-5 h-5 text-[#19C3B1]" />,
                    text: 'Friendly streaks and streak multipliers',
                  },
                ].map((item, idx) => (
                  <div
                    key={idx}
                    className={`p-3.5 rounded-2xl border-2 flex items-center gap-3 text-left transition-all ${
                      darkMode
                        ? 'bg-[#221E52] border-white/10'
                        : 'bg-white border-[#1F1B4D]/10'
                    }`}
                    style={{ borderBottomWidth: '4px' }}
                  >
                    <div
                      className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${
                        darkMode ? 'bg-white/10' : 'bg-[#FFF8EC]'
                      }`}
                    >
                      {item.icon}
                    </div>
                    <span className="text-[13px] font-extrabold leading-snug">
                      {item.text}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* STEP 1: LANGUAGE PREFERENCE (ALL EQUAL, NO SUBTITLES) */}
          {currentStep === 1 && (
            <div className="space-y-4 animate-fade-in">
              {/* Mascot Dialogue Header */}
              <div className="flex items-center gap-3">
                <ChurroMascot
                  mood="thinking"
                  size="md"
                  animate
                  speech="Which language sparks your curiosity?"
                  speechPosition="right"
                />
                <h1 className="text-[20px] font-extrabold leading-tight tracking-tight">
                  What would you like to learn?
                </h1>
              </div>

              {/* Language Options List - All Uniform, No Subtitles */}
              <div className="grid grid-cols-1 gap-2.5 pt-1">
                {[
                  { id: 'Spanish', name: 'Spanish', flag: '🇪🇸' },
                  { id: 'French', name: 'French', flag: '🇫🇷' },
                  { id: 'Italian', name: 'Italian', flag: '🇮🇹' },
                  { id: 'German', name: 'German', flag: '🇩🇪' },
                  { id: 'Japanese', name: 'Japanese', flag: '🇯🇵' },
                  { id: 'Portuguese', name: 'Portuguese', flag: '🇧🇷' },
                ].map((item) => {
                  const isSelected = targetLanguage === item.id;
                  return (
                    <button
                      key={item.id}
                      type="button"
                      onClick={() => handleSelectOption(() => setTargetLanguage(item.id))}
                      className={`w-full p-3.5 rounded-2xl text-left border-2 flex items-center justify-between cursor-pointer transition-all ${
                        isSelected
                          ? darkMode
                            ? 'bg-[#2D2766] border-[#FF6B2C] shadow-md scale-[1.01]'
                            : 'bg-white border-[#FF6B2C] shadow-md scale-[1.01]'
                          : darkMode
                          ? 'bg-[#221E52] border-white/10 hover:border-white/20'
                          : 'bg-white/80 border-[#1F1B4D]/15 hover:border-[#1F1B4D]/30'
                      }`}
                      style={{
                        borderBottomWidth: '4px',
                      }}
                    >
                      <div className="flex items-center gap-3">
                        <span className="text-[26px] leading-none shrink-0 drop-shadow-xs">
                          {item.flag}
                        </span>
                        <span className="text-[16px] font-extrabold block">
                          {item.name}
                        </span>
                      </div>

                      <div
                        className={`w-6 h-6 rounded-full border-2 flex items-center justify-center shrink-0 transition-colors ${
                          isSelected
                            ? 'bg-[#FF6B2C] border-[#FF6B2C] text-white'
                            : darkMode
                            ? 'border-white/20'
                            : 'border-[#1F1B4D]/25'
                        }`}
                      >
                        {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* STEP 2: WHY ARE YOU LEARNING? */}
          {currentStep === 2 && (
            <div className="space-y-4 animate-fade-in">
              {/* Mascot Dialogue Header */}
              <div className="flex items-center gap-3">
                <ChurroMascot
                  mood="encouraging"
                  size="md"
                  animate
                  speech="Great goal! Let's make it happen!"
                  speechPosition="right"
                />
                <h1 className="text-[20px] font-extrabold leading-tight tracking-tight">
                  Why are you learning {targetLanguage}?
                </h1>
              </div>

              {/* Motivation Options */}
              <div className="grid grid-cols-1 gap-2.5 pt-1">
                {[
                  {
                    id: 'travel',
                    label: 'Travel and adventures abroad',
                    icon: <Compass className="w-5 h-5 text-[#FF6B2C]" />,
                  },
                  {
                    id: 'brain',
                    label: 'Brain workout & mental sharpness',
                    icon: <Brain className="w-5 h-5 text-[#7B5CFF]" />,
                  },
                  {
                    id: 'culture',
                    label: 'Music, cinema & food culture',
                    icon: <Music className="w-5 h-5 text-[#19C3B1]" />,
                  },
                  {
                    id: 'friends',
                    label: 'Connect with family & friends',
                    icon: <Users className="w-5 h-5 text-[#FFC93C]" />,
                  },
                  {
                    id: 'career',
                    label: 'Career & professional growth',
                    icon: <Briefcase className="w-5 h-5 text-[#FF5C6C]" />,
                  },
                ].map((item) => {
                  const isSelected = motivation === item.id;
                  return (
                    <button
                      key={item.id}
                      type="button"
                      onClick={() => handleSelectOption(() => setMotivation(item.id))}
                      className={`w-full p-3.5 rounded-2xl text-left border-2 flex items-center justify-between cursor-pointer transition-all ${
                        isSelected
                          ? darkMode
                            ? 'bg-[#2D2766] border-[#FF6B2C] shadow-md scale-[1.01]'
                            : 'bg-white border-[#FF6B2C] shadow-md scale-[1.01]'
                          : darkMode
                          ? 'bg-[#221E52] border-white/10 hover:border-white/20'
                          : 'bg-white/80 border-[#1F1B4D]/15 hover:border-[#1F1B4D]/30'
                      }`}
                      style={{
                        borderBottomWidth: '4px',
                      }}
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                            darkMode ? 'bg-white/10' : 'bg-[#FFF8EC]'
                          }`}
                        >
                          {item.icon}
                        </div>
                        <span className="text-[14px] font-extrabold">
                          {item.label}
                        </span>
                      </div>

                      <div
                        className={`w-6 h-6 rounded-full border-2 flex items-center justify-center shrink-0 transition-colors ${
                          isSelected
                            ? 'bg-[#FF6B2C] border-[#FF6B2C] text-white'
                            : darkMode
                            ? 'border-white/20'
                            : 'border-[#1F1B4D]/25'
                        }`}
                      >
                        {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* STEP 3: TIME PER DAY & WEEKLY FREQUENCY */}
          {currentStep === 3 && (
            <div className="space-y-4 animate-fade-in">
              {/* Mascot Dialogue Header */}
              <div className="flex items-center gap-3">
                <ChurroMascot
                  mood="encouraging"
                  size="md"
                  animate
                  speech="A few minutes a day builds fluency!"
                  speechPosition="right"
                />
                <h1 className="text-[20px] font-extrabold leading-tight tracking-tight">
                  How often do you want to practice?
                </h1>
              </div>

              {/* Daily Minutes Selection */}
              <div className="space-y-2 pt-1">
                <div className="grid grid-cols-1 gap-2.5">
                  {[
                    {
                      mins: 5,
                      label: '5 min / day',
                    },
                    {
                      mins: 10,
                      label: '10 min / day',
                    },
                    {
                      mins: 15,
                      label: '15 min / day',
                    },
                    {
                      mins: 20,
                      label: '20 min / day',
                    },
                  ].map((item) => {
                    const isSelected = dailyMinutes === item.mins;
                    return (
                      <button
                        key={item.mins}
                        type="button"
                        onClick={() => handleSelectOption(() => setDailyMinutes(item.mins))}
                        className={`w-full p-3.5 rounded-2xl text-left border-2 flex items-center justify-between cursor-pointer transition-all ${
                          isSelected
                            ? darkMode
                              ? 'bg-[#2D2766] border-[#FF6B2C] shadow-md scale-[1.01]'
                              : 'bg-white border-[#FF6B2C] shadow-md scale-[1.01]'
                            : darkMode
                            ? 'bg-[#221E52] border-white/10 hover:border-white/20'
                            : 'bg-white/80 border-[#1F1B4D]/15 hover:border-[#1F1B4D]/30'
                        }`}
                        style={{
                          borderBottomWidth: '4px',
                        }}
                      >
                        <div className="flex items-center gap-3">
                          <div
                            className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                              darkMode ? 'bg-white/10' : 'bg-[#FFF8EC]'
                            }`}
                          >
                            <Clock className="w-5 h-5 text-[#FF6B2C]" />
                          </div>
                          <span className="text-[15px] font-extrabold block">
                            {item.label}
                          </span>
                        </div>

                        <div
                          className={`w-6 h-6 rounded-full border-2 flex items-center justify-center shrink-0 transition-colors ${
                            isSelected
                              ? 'bg-[#FF6B2C] border-[#FF6B2C] text-white'
                              : darkMode
                              ? 'border-white/20'
                              : 'border-[#1F1B4D]/25'
                          }`}
                        >
                          {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Weekly Frequency Segment */}
              <div className="pt-2 space-y-2">
                <div className="grid grid-cols-2 gap-2.5">
                  {[
                    { id: 'casual-week', title: '3 to 4 days / week', icon: Calendar },
                    { id: 'daily', title: 'Every single day', icon: Flame },
                  ].map((freq) => {
                    const isSelected = weeklyFrequency === freq.id;
                    const Icon = freq.icon;
                    return (
                      <button
                        key={freq.id}
                        type="button"
                        onClick={() => handleSelectOption(() => setWeeklyFrequency(freq.id))}
                        className={`p-3 rounded-xl border-2 text-center flex flex-col items-center gap-1.5 cursor-pointer transition-all ${
                          isSelected
                            ? 'border-[#7B5CFF] bg-[#7B5CFF]/15 font-extrabold'
                            : darkMode
                            ? 'border-white/10 bg-[#221E52] opacity-80'
                            : 'border-[#1F1B4D]/15 bg-white opacity-80'
                        }`}
                      >
                        <Icon
                          className={`w-4 h-4 ${
                            isSelected ? 'text-[#7B5CFF]' : 'opacity-60'
                          }`}
                        />
                        <span className="text-[12px] font-extrabold">
                          {freq.title}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {/* STEP 4: PREFERRED GAMES */}
          {currentStep === 4 && (
            <div className="space-y-4 animate-fade-in">
              {/* Mascot Dialogue Header */}
              <div className="flex items-center gap-3">
                <ChurroMascot
                  mood="quest"
                  size="md"
                  animate
                  speech="Games make every word stick!"
                  speechPosition="right"
                />
                <h1 className="text-[20px] font-extrabold leading-tight tracking-tight">
                  What games do you prefer to play?
                </h1>
              </div>

              {/* Games Multi-Select Cards */}
              <div className="grid grid-cols-1 gap-2.5 pt-1">
                {[
                  {
                    id: 'connections',
                    name: 'Conexiones',
                    tag: 'Group 4 related words',
                    icon: <Grid className="w-5 h-5 text-[#7B5CFF]" />,
                  },
                  {
                    id: 'word-guess',
                    name: 'Word Guess',
                    tag: 'Daily 5-letter puzzle',
                    icon: <Hash className="w-5 h-5 text-[#FFC93C]" />,
                  },
                  {
                    id: 'crossword',
                    name: 'Mini Crossword',
                    tag: 'Bite-sized crossword with hints',
                    icon: <HelpCircle className="w-5 h-5 text-[#19C3B1]" />,
                  },
                  {
                    id: 'fill-blank',
                    name: 'Rapid Fill-In',
                    tag: 'Context & recall drills',
                    icon: <FileText className="w-5 h-5 text-[#FF6B2C]" />,
                  },
                  {
                    id: 'pronunciation',
                    name: 'Sentence Builder',
                    tag: 'Piece together natural phrasing',
                    icon: <Volume2 className="w-5 h-5 text-[#3DDC84]" />,
                  },
                ].map((game) => {
                  const isSelected = preferredGames.includes(game.id);
                  return (
                    <button
                      key={game.id}
                      type="button"
                      onClick={() => toggleGamePreference(game.id)}
                      className={`w-full p-3.5 rounded-2xl text-left border-2 flex items-center justify-between cursor-pointer transition-all ${
                        isSelected
                          ? darkMode
                            ? 'bg-[#2D2766] border-[#FF6B2C] shadow-md scale-[1.01]'
                            : 'bg-white border-[#FF6B2C] shadow-md scale-[1.01]'
                          : darkMode
                          ? 'bg-[#221E52] border-white/10 opacity-70 hover:opacity-100'
                          : 'bg-white/80 border-[#1F1B4D]/15 opacity-70 hover:opacity-100'
                      }`}
                      style={{
                        borderBottomWidth: '4px',
                      }}
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                            darkMode ? 'bg-white/10' : 'bg-[#FFF8EC]'
                          }`}
                        >
                          {game.icon}
                        </div>
                        <div>
                          <span className="text-[15px] font-extrabold block">
                            {game.name}
                          </span>
                          <span className="text-[11px] font-bold opacity-70">
                            {game.tag}
                          </span>
                        </div>
                      </div>

                      <div
                        className={`w-6 h-6 rounded-lg border-2 flex items-center justify-center shrink-0 transition-colors ${
                          isSelected
                            ? 'bg-[#FF6B2C] border-[#FF6B2C] text-white'
                            : darkMode
                            ? 'border-white/20'
                            : 'border-[#1F1B4D]/25'
                        }`}
                      >
                        {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* STEP 5: EXPERIENCE / STARTING LEVEL */}
          {currentStep === 5 && (
            <div className="space-y-4 animate-fade-in">
              {/* Mascot Dialogue Header */}
              <div className="flex items-center gap-3">
                <ChurroMascot
                  mood="proud"
                  size="md"
                  animate
                  speech="No stress, we'll start where you're comfortable!"
                  speechPosition="right"
                />
                <h1 className="text-[20px] font-extrabold leading-tight tracking-tight">
                  How much {targetLanguage} do you know?
                </h1>
              </div>

              {/* Level Cards */}
              <div className="grid grid-cols-1 gap-2.5 pt-1">
                {[
                  {
                    id: 'beginner',
                    title: 'Just starting fresh from zero',
                    emoji: '🌱',
                  },
                  {
                    id: 'elementary',
                    title: 'I know some common words',
                    emoji: '☕',
                  },
                  {
                    id: 'intermediate',
                    title: 'I can have basic conversations',
                    emoji: '💬',
                  },
                  {
                    id: 'advanced',
                    title: 'Intermediate or higher',
                    emoji: '⚡',
                  },
                ].map((item) => {
                  const isSelected = startingLevel === item.id;
                  return (
                    <button
                      key={item.id}
                      type="button"
                      onClick={() => handleSelectOption(() => setStartingLevel(item.id))}
                      className={`w-full p-3.5 rounded-2xl text-left border-2 flex items-center justify-between cursor-pointer transition-all ${
                        isSelected
                          ? darkMode
                            ? 'bg-[#2D2766] border-[#FF6B2C] shadow-md scale-[1.01]'
                            : 'bg-white border-[#FF6B2C] shadow-md scale-[1.01]'
                          : darkMode
                          ? 'bg-[#221E52] border-white/10 hover:border-white/20'
                          : 'bg-white/80 border-[#1F1B4D]/15 hover:border-[#1F1B4D]/30'
                      }`}
                      style={{
                        borderBottomWidth: '4px',
                      }}
                    >
                      <div className="flex items-center gap-3">
                        <span className="text-[24px] leading-none shrink-0">
                          {item.emoji}
                        </span>
                        <span className="text-[15px] font-extrabold block">
                          {item.title}
                        </span>
                      </div>

                      <div
                        className={`w-6 h-6 rounded-full border-2 flex items-center justify-center shrink-0 transition-colors ${
                          isSelected
                            ? 'bg-[#FF6B2C] border-[#FF6B2C] text-white'
                            : darkMode
                            ? 'border-white/20'
                            : 'border-[#1F1B4D]/25'
                        }`}
                      >
                        {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* STEP 6: CELEBRATION / READY TO START */}
          {currentStep === 6 && (
            <div className="space-y-5 animate-fade-in text-center py-2">
              {/* Grand Mascot Celebration */}
              <div className="flex flex-col items-center justify-center space-y-3">
                <ChurroMascot
                  mood="celebrating"
                  size="xl"
                  animate
                  speech="Let's get fluent-ish!"
                  speechPosition="top"
                />
                <h1 className="text-[24px] font-extrabold leading-tight tracking-tight">
                  Your daily plan is ready!
                </h1>
              </div>

              {/* Summary Cards */}
              <div
                className={`p-4 rounded-[24px] border-2 shadow-xs space-y-3 text-left ${
                  darkMode
                    ? 'bg-[#221E52] border-white/10'
                    : 'bg-white border-[#1F1B4D]/10'
                }`}
              >
                <div className="flex items-center justify-between pb-2 border-b border-current/10">
                  <span className="text-[13px] font-bold opacity-75">Target Language</span>
                  <span className="text-[14px] font-extrabold text-[#FF6B2C]">
                    {targetLanguage}
                  </span>
                </div>

                <div className="flex items-center justify-between pb-2 border-b border-current/10">
                  <span className="text-[13px] font-bold opacity-75">Daily Pace</span>
                  <span className="text-[14px] font-extrabold text-[#7B5CFF] flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5" />
                    <span>{dailyMinutes} min / day</span>
                  </span>
                </div>

                <div className="flex items-center justify-between pb-2 border-b border-current/10">
                  <span className="text-[13px] font-bold opacity-75">Weekly Frequency</span>
                  <span className="text-[14px] font-extrabold text-[#19C3B1] flex items-center gap-1">
                    <Flame className="w-3.5 h-3.5" />
                    <span>
                      {weeklyFrequency === 'daily' ? 'Every day' : '3-4 days / week'}
                    </span>
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-[13px] font-bold opacity-75">Favorite Games</span>
                  <span className="text-[13px] font-extrabold text-[#FFC93C]">
                    {preferredGames.length} selected
                  </span>
                </div>
              </div>

              <div className="p-3 rounded-2xl bg-[#FF6B2C]/10 border border-[#FF6B2C]/20 text-[#FF6B2C] flex items-center justify-center gap-2">
                <Sparkles className="w-4 h-4" />
                <span className="text-[12px] font-extrabold">
                  +30 XP Bonus ready on your first game!
                </span>
              </div>
            </div>
          )}
        </div>

        {/* 3. PINNED BOTTOM ACTION BUTTON (CHUNKY DUOLINGO 3D BUTTON) */}
        <div className="pt-4 pb-2">
          <button
            type="button"
            onClick={handleNext}
            className="w-full h-13 btn-3d-primary rounded-2xl font-extrabold text-[15px] uppercase tracking-wider flex items-center justify-center gap-2 shadow-lg cursor-pointer"
          >
            {currentStep === 0 ? (
              <span>Get Started</span>
            ) : currentStep === TOTAL_STEPS - 1 ? (
              <>
                <Sparkles className="w-4 h-4" />
                <span>Start Practicing</span>
              </>
            ) : (
              <span>Continue</span>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
