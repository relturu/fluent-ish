import React, { useState, useRef } from 'react';
import {
  Flame,
  Check,
  ChevronLeft,
  ChevronRight,
  Play,
  RotateCcw,
  BookOpen,
  Award,
  List,
  Layers,
  Sparkles,
  ArrowUpRight,
  X,
} from 'lucide-react';
import {
  ActiveViewId,
  DAILY_SPANISH_VOCAB,
  DifficultyLevel,
  SessionReviewData,
  UserStats,
  VocabWord,
} from '../types';
import {
  HiFiButton,
  PageTopBar,
  GameHeaderBar,
  AudioButton,
  ConfettiBurst,
  StreakIndicator,
  useTheme,
} from '../components/common/HiFiElements';
import { ChurroMascot } from '../components/common/Mascot';

export function Page03Daily({
  activeView,
  onNavigate,
  completedIds,
  selectedDifficulty,
  onSelectDifficulty,
  onCompleteVocabDeck,
  userStats,
  onOpenRules,
}: {
  activeView: ActiveViewId;
  onNavigate: (view: ActiveViewId) => void;
  completedIds: string[];
  selectedDifficulty: DifficultyLevel;
  onSelectDifficulty: (diff: DifficultyLevel) => void;
  onCompleteVocabDeck: (review: SessionReviewData) => void;
  userStats: UserStats;
  onOpenRules: () => void;
}) {
  const { darkMode } = useTheme();
  const [cardIndex, setCardIndex] = useState(0);
  const [viewMode, setViewMode] = useState<'card' | 'list'>('card');
  const [showDemoBanner, setShowDemoBanner] = useState<boolean>(true);
  const [celebrationData, setCelebrationData] = useState<{
    message: string;
    onComplete?: () => void;
  } | null>(null);

  // Derived user progression info
  const currentLevel = Math.floor(userStats.totalXP / 1500) + 1;
  const currentLevelXP = userStats.totalXP % 1500;
  const xpNeeded = 1500 - currentLevelXP;

  // ----------------------------------------------------------------------------
  // Sub-view: Daily Vocab Lesson (Words & Definitions, NO info button!)
  // ----------------------------------------------------------------------------
  if (activeView === 'vocab-deck') {
    const currentWord = DAILY_SPANISH_VOCAB[cardIndex];
    const isReview = currentWord.splitType === 'review';
    const isCompleted = completedIds.includes('vocab-deck');

    const handleFinishLesson = () => {
      const reviewPayload: SessionReviewData = {
        sourceId: 'vocab-deck',
        title: 'Daily Vocab Lesson',
        subtitle: 'Words & Definitions · 10 Words',
        scoreLabel: '10 / 10',
        accuracy: '100%',
        timeSpent: '2m 10s',
        streakEarned: true,
        spanishTipTitle: 'La Sobremesa & Conectores',
        spanishTipBody:
          'Spanish café culture thrives on unhurried conversation. Use "sin embargo" and "además" to connect thoughts naturally.',
        wordsPracticed: DAILY_SPANISH_VOCAB.slice(0, 4),
        xpEarned: 30,
        pointsScore: 100,
      };

      setCelebrationData({
        message: '¡Lección Completada! +30 XP & 100 Pts 🎉',
        onComplete: () => onCompleteVocabDeck(reviewPayload),
      });
    };

    return (
      <div className="flex flex-col flex-1 relative">
        {celebrationData && (
          <ConfettiBurst
            message={celebrationData.message}
            onDone={() => {
              const cb = celebrationData.onComplete;
              setCelebrationData(null);
              cb?.();
            }}
          />
        )}

        {/* GameHeaderBar with NO info button (no onOpenHowToPlay, no onOpenHint) */}
        <GameHeaderBar
          title="Daily Vocab Lesson"
          subtitle="Words & Definitions"
          onBack={() => onNavigate('daily')}
          rightBadge={
            <div className="flex items-center gap-1 bg-current/10 p-0.5 rounded-xl">
              <button
                type="button"
                onClick={() => setViewMode('card')}
                className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                  viewMode === 'card'
                    ? 'bg-[#FF6B2C] text-white shadow-xs'
                    : 'opacity-60 hover:opacity-100'
                }`}
                title="Card View"
              >
                <Layers className="w-3.5 h-3.5" />
              </button>
              <button
                type="button"
                onClick={() => setViewMode('list')}
                className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                  viewMode === 'list'
                    ? 'bg-[#FF6B2C] text-white shadow-xs'
                    : 'opacity-60 hover:opacity-100'
                }`}
                title="All Words List"
              >
                <List className="w-3.5 h-3.5" />
              </button>
            </div>
          }
        />

        {viewMode === 'card' ? (
          <div className="flex-1 px-4 py-5 flex flex-col justify-between">
            {/* Top Indicator & Mini Progress Bar */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between text-[12px] font-bold">
                <span className="opacity-75">
                  Word {cardIndex + 1} of {DAILY_SPANISH_VOCAB.length}
                </span>
                <span
                  className={
                    isReview ? 'text-[#19C3B1]' : 'text-[#FF6B2C]'
                  }
                >
                  {isReview ? '70% Review' : '30% New'}
                </span>
              </div>
              <div className="h-2 w-full rounded-full bg-current/10 overflow-hidden flex gap-0.5">
                {DAILY_SPANISH_VOCAB.map((w, idx) => (
                  <div
                    key={w.id}
                    className={`flex-1 h-full transition-all ${
                      idx <= cardIndex
                        ? w.splitType === 'review'
                          ? 'bg-[#19C3B1]'
                          : 'bg-[#FF6B2C]'
                        : 'bg-transparent'
                    }`}
                  />
                ))}
              </div>
            </div>

            {/* Clean, Focused Word & Definition Flashcard */}
            <div
              className={`my-auto py-6 px-5 rounded-[26px] border space-y-5 shadow-sm transition-colors ${
                darkMode
                  ? 'bg-[#221E52] border-white/10 text-[#FFF8EC]'
                  : 'bg-white border-[#1F1B4D]/10 text-[#1F1B4D]'
              }`}
            >
              {/* Word & Pronunciation */}
              <div className="flex items-start justify-between gap-3">
                <div className="space-y-0.5 min-w-0">
                  <span className="text-[11px] font-extrabold uppercase tracking-wider opacity-60">
                    {currentWord.partOfSpeech}
                  </span>
                  <h2 className="type-display text-[#FF6B2C] tracking-tight">
                    {currentWord.spanish}
                  </h2>
                  <span className="text-[13px] opacity-60 block font-medium">
                    {currentWord.phonetic}
                  </span>
                </div>
                <AudioButton text={currentWord.spanish} size="lg" />
              </div>

              {/* Crystal Clear Definition Box (No info button needed!) */}
              <div
                className={`p-4 rounded-2xl border space-y-1 transition-colors ${
                  darkMode
                    ? 'bg-[#17143A]/60 border-white/10'
                    : 'bg-[#FFF8EC] border-[#1F1B4D]/10'
                }`}
              >
                <div className="flex items-center gap-1.5 text-[11px] font-extrabold uppercase tracking-wide text-[#19C3B1]">
                  <BookOpen className="w-3.5 h-3.5" />
                  <span>Definition</span>
                </div>
                <p className="text-[16px] font-bold leading-snug">
                  {currentWord.english}
                </p>
              </div>

              {/* Example Sentence with Audio */}
              <div className="pt-2 border-t border-current/10 space-y-1">
                <div className="flex items-center justify-between gap-2">
                  <p className="text-[14px] italic opacity-95 font-medium leading-relaxed">
                    “{currentWord.exampleEs}”
                  </p>
                  <AudioButton text={currentWord.exampleEs} size="sm" />
                </div>
                <p className="text-[12px] opacity-65 font-medium">
                  {currentWord.exampleEn}
                </p>
              </div>
            </div>

            {/* Bottom Navigation Buttons */}
            <div className="flex items-center gap-2 pt-2">
              <HiFiButton
                size="lg"
                variant="outline"
                disabled={cardIndex === 0}
                onClick={() => setCardIndex(Math.max(0, cardIndex - 1))}
                icon={<ChevronLeft className="w-4 h-4" />}
              >
                Prev
              </HiFiButton>

              {cardIndex < DAILY_SPANISH_VOCAB.length - 1 ? (
                <HiFiButton
                  size="lg"
                  variant="primary"
                  fullWidth
                  onClick={() => setCardIndex(cardIndex + 1)}
                  icon={<ChevronRight className="w-4 h-4" />}
                >
                  Next Word
                </HiFiButton>
              ) : (
                <HiFiButton
                  size="lg"
                  variant="primary"
                  fullWidth
                  onClick={handleFinishLesson}
                  icon={<Check className="w-4 h-4" />}
                >
                  Finish Lesson (+30 XP)
                </HiFiButton>
              )}
            </div>
          </div>
        ) : (
          /* All 10 Words & Definitions List View */
          <div className="flex-1 px-4 py-4 space-y-3 overflow-y-auto">
            <div className="flex items-center justify-between">
              <p className="text-[12px] opacity-70 font-bold">
                10 Daily Words & Definitions · La Sobremesa
              </p>
              <span className="text-[11px] font-extrabold text-[#19C3B1]">
                70% Review · 30% New
              </span>
            </div>

            <div className="space-y-2">
              {DAILY_SPANISH_VOCAB.map((word, idx) => (
                <div
                  key={word.id}
                  className={`p-3.5 rounded-2xl border space-y-1.5 transition-colors ${
                    darkMode
                      ? 'bg-[#221E52] border-white/10'
                      : 'bg-white border-[#1F1B4D]/10'
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="w-5 h-5 rounded-full bg-current/10 text-[10px] font-extrabold flex items-center justify-center">
                          {idx + 1}
                        </span>
                        <h4 className="text-[15px] font-extrabold text-[#FF6B2C]">
                          {word.spanish}
                        </h4>
                        <span className="text-[11px] opacity-60">
                          {word.phonetic}
                        </span>
                      </div>
                    </div>
                    <AudioButton text={word.spanish} size="sm" />
                  </div>

                  {/* Clean Definition */}
                  <div className="pl-7">
                    <p className="text-[13px] font-bold leading-snug">
                      {word.english}
                    </p>
                    <p className="text-[12px] opacity-65 italic mt-0.5">
                      “{word.exampleEs}”
                    </p>
                  </div>
                </div>
              ))}
            </div>

            <div className="pt-2 pb-4">
              <HiFiButton
                fullWidth
                size="lg"
                variant="primary"
                onClick={handleFinishLesson}
                icon={<Check className="w-4 h-4" />}
              >
                {isCompleted ? 'Mark Lesson Complete' : 'Finish Lesson (+30 XP)'}
              </HiFiButton>
            </div>
          </div>
        )}
      </div>
    );
  }

  // ----------------------------------------------------------------------------
  // Main Today Screen (Matched to exact screenshots)
  // ----------------------------------------------------------------------------
  const [activeInfoModal, setActiveInfoModal] = useState<
    | 'vocab'
    | 'connections'
    | 'word-guess'
    | 'crossword'
    | 'fill-blank'
    | 'sentence-builder'
    | 'definition-match'
    | null
  >(null);
  const [isLevelModalOpen, setIsLevelModalOpen] = useState<boolean>(false);
  const [canScrollLeft, setCanScrollLeft] = useState<boolean>(false);
  const wordsScrollRef = useRef<HTMLDivElement>(null);

  const handleWordsScroll = () => {
    if (wordsScrollRef.current) {
      setCanScrollLeft(wordsScrollRef.current.scrollLeft > 10);
    }
  };

  const scrollWordsLeft = () => {
    if (wordsScrollRef.current) {
      wordsScrollRef.current.scrollBy({ left: -180, behavior: 'smooth' });
    }
  };

  const scrollWordsRight = () => {
    if (wordsScrollRef.current) {
      const { scrollLeft, scrollWidth, clientWidth } = wordsScrollRef.current;
      if (scrollLeft + clientWidth >= scrollWidth - 10) {
        wordsScrollRef.current.scrollTo({ left: 0, behavior: 'smooth' });
      } else {
        wordsScrollRef.current.scrollBy({ left: 180, behavior: 'smooth' });
      }
    }
  };

  const isVocabCompleted = completedIds.includes('vocab-deck');
  const completedGamesCount = [
    'game-connections',
    'game-word-guess',
    'game-crossword',
  ].filter((id) => completedIds.includes(id)).length;

  const todayDayName = new Date()
    .toLocaleDateString('en-US', { weekday: 'long' })
    .toUpperCase();

  const infoModalDetails: Record<
    string,
    {
      title: string;
      subtitle: string;
      badge: string;
      description: string;
      tip: string;
      xpReward: string;
      actionLabel: string;
      targetView: ActiveViewId;
    }
  > = {
    vocab: {
      title: 'Daily Vocab (70/30 Mix)',
      subtitle: 'La Sobremesa · 10 Words',
      badge: 'Retention Model',
      description:
        'Fluent•ish pairs 70% familiar vocabulary for spaced-repetition memory consolidation with 30% new contextual terms to steadily elevate conversational fluency.',
      tip: 'Flip through cards or view all 10 words and native pronunciations before playing today’s games.',
      xpReward: '+30 XP & 100 Pts',
      actionLabel: isVocabCompleted ? 'Review Lesson' : 'Start Lesson',
      targetView: 'vocab-deck',
    },
    connections: {
      title: 'Connections (Conexiones)',
      subtitle: '4 Category Groups · 16 Words',
      badge: 'Pattern Puzzle',
      description:
        'Find groups of 4 Spanish words that share a common thematic, grammatical, or idiomatic thread. Solve all 4 categories without making more than 4 mistakes.',
      tip: 'Categories range from food & drinks to false friends (falsos amigos) and slang.',
      xpReward: '+40 XP & Score Points',
      actionLabel: 'Play Connections',
      targetView: 'game-connections',
    },
    'word-guess': {
      title: 'Word Guess (Palabra del Día)',
      subtitle: '6 Letters · 6 Attempts',
      badge: 'Wordle Style',
      description:
        'Guess the mystery 6-letter Spanish word of the day. Each attempt gives instant color-coded feedback: green for right letter in the right spot, yellow for right letter in the wrong spot.',
      tip: 'Starts with common Spanish vowel patterns (A, E, O). Accent marks are handled automatically!',
      xpReward: '+40 XP & Score Points',
      actionLabel: 'Play Word Guess',
      targetView: 'game-word-guess',
    },
    crossword: {
      title: 'Mini Crossword (Crucigrama)',
      subtitle: '5×5 Daily Grid · Across & Down',
      badge: 'Speed Puzzle',
      description:
        'A bite-sized 5×5 Spanish crossword designed to test both vocabulary breadth and contextual grammar clues in under 2 minutes.',
      tip: 'Tap any square to toggle between Across (Horizontales) and Down (Verticales) clues.',
      xpReward: '+40 XP & Score Points',
      actionLabel: 'Play Crossword',
      targetView: 'game-crossword',
    },
    'fill-blank': {
      title: 'Fill in the Blank',
      subtitle: 'Completa la Frase',
      badge: 'Grammar Drill',
      description:
        'Read real conversational Spanish dialogues and pick the correct verb conjugation or connecting phrase to make the sentence natural.',
      tip: 'Pay close attention to grammatical gender and subjunctive triggers!',
      xpReward: '+25 XP per session',
      actionLabel: 'Start Drill',
      targetView: 'exercise-fill-blank',
    },
    'sentence-builder': {
      title: 'Sentence Builder',
      subtitle: 'Construye la Oración',
      badge: 'Syntax Drill',
      description:
        'Unscramble Spanish word tokens and place them in the correct syntactical order to form authentic, fluent sentences.',
      tip: 'In Spanish, object pronouns (me, te, lo, la) usually precede the conjugated verb!',
      xpReward: '+25 XP per session',
      actionLabel: 'Start Drill',
      targetView: 'exercise-sentence-builder',
    },
    'definition-match': {
      title: 'Definition Match',
      subtitle: 'Empareja Palabras',
      badge: 'Speed Drill',
      description:
        'Rapid-fire association: Match target Spanish words directly with their English meanings before the timer expires.',
      tip: 'Builds automatic, translation-free word retrieval reflexes.',
      xpReward: '+25 XP per session',
      actionLabel: 'Start Drill',
      targetView: 'exercise-definition-match',
    },
  };

  return (
    <div className="flex flex-col flex-1 relative select-none">
      {celebrationData && (
        <ConfettiBurst
          message={celebrationData.message}
          onDone={() => {
            const cb = celebrationData.onComplete;
            setCelebrationData(null);
            cb?.();
          }}
        />
      )}

      {/* Top Header Bar matching Screenshot: Fluent•ish / Today  1,245 XP  🔥 14 */}
      <div
        className={`px-5 py-3 flex items-center justify-between border-b shrink-0 ${
          darkMode ? 'border-white/10' : 'border-[#1F1B4D]/10'
        }`}
      >
        <div className="flex items-center gap-1.5">
          <span
            className={`font-extrabold text-[17px] tracking-tight flex items-center ${
              darkMode ? 'text-white' : 'text-[#1F1B4D]'
            }`}
          >
            Fluent<span className="text-[#FF6B2C] mx-0.5">•</span>ish
          </span>
          <span
            className={`font-normal text-[15px] mx-0.5 ${
              darkMode ? 'text-neutral-500' : 'text-neutral-400'
            }`}
          >
            /
          </span>
          <span
            className={`font-medium text-[15px] ${
              darkMode ? 'text-neutral-400' : 'text-[#706E7B]'
            }`}
          >
            Today
          </span>
        </div>

        <div className="flex items-center gap-2.5 select-none">
          {/* Spain Flag next to Lv.1 (Opens Minimal Level Modal, 1470 XP deleted) */}
          <button
            type="button"
            onClick={() => setIsLevelModalOpen(true)}
            className={`flex items-center gap-1.5 px-2 py-1 rounded-lg font-bold text-[13px] hover:bg-black/5 dark:hover:bg-white/10 transition-colors cursor-pointer ${
              darkMode ? 'text-white' : 'text-[#1F1B4D]'
            }`}
            title="Tap to see level progress"
          >
            <span className="text-[14px] leading-none" role="img" aria-label="Spain flag">
              🇪🇸
            </span>
            <span className="text-[#7B5CFF]">Lv.{currentLevel}</span>
          </button>

          {/* Unified Daily Streak Indicator */}
          <StreakIndicator
            streakCount={userStats.streakCount}
            streakCountedToday={userStats.streakCountedToday}
            onClick={onOpenRules}
          />
        </div>
      </div>

      {/* Scrollable Content Container */}
      <div className="px-4 py-3 space-y-3 overflow-y-auto">
        {/* 1. GREETING & MASCOT HEADER (Two-column layout from Screenshot) */}
        <div className="flex items-start justify-between gap-3 pt-1">
          {/* Left Column: Speech Bubble + Mascot */}
          <div className="flex flex-col items-center shrink-0 w-36">
            <div
              className={`relative text-white text-[12px] font-bold px-3 py-2 rounded-2xl shadow-xs text-center leading-snug ${
                darkMode ? 'bg-[#2B265E]' : 'bg-[#211D4E]'
              }`}
            >
              ¡Un cafecito y a jugar!
              {/* Downward triangle pointer */}
              <div
                className={`absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-0 h-0 border-l-[6px] border-l-transparent border-r-[6px] border-r-transparent border-t-[6px] ${
                  darkMode ? 'border-t-[#2B265E]' : 'border-t-[#211D4E]'
                }`}
              />
            </div>
            <div className="mt-1">
              <ChurroMascot mood="waving" size="sm" idle />
            </div>
          </div>

          {/* Right Column: Greeting */}
          <div className="flex-1 min-w-0 pt-0.5">
            <h1
              className={`font-serif text-[28px] sm:text-[32px] font-extrabold leading-[1.15] mt-1 mb-0.5 tracking-tight ${
                darkMode ? 'text-white' : 'text-[#1F1B4D]'
              }`}
            >
              ¡Hola, Sofía!
            </h1>
          </div>
        </div>

        {/* 2. DAILY VOCAB CARD */}
        <div
          className={`rounded-[20px] p-3.5 border shadow-xs space-y-2 ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <div className="flex items-start justify-between">
            <div>
              <h2
                className={`font-serif text-[20px] font-bold leading-tight ${
                  darkMode ? 'text-white' : 'text-[#1F1B4D]'
                }`}
              >
                Daily Vocab
              </h2>
              <p
                className={`text-[12px] font-medium mt-0.5 ${
                  darkMode ? 'text-neutral-400' : 'text-[#706E7B]'
                }`}
              >
                La Sobremesa · 10 words
              </p>
            </div>

            {/* Top Right Corner: +30 XP above action buttons */}
            <div className="flex flex-col items-end gap-1">
              <span className="text-[11px] font-extrabold text-[#FF6B2C] tracking-wide">
                +30 XP
              </span>
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => setActiveInfoModal('vocab')}
                  className={`w-5.5 h-5.5 rounded-full border flex items-center justify-center transition-colors cursor-pointer ${
                    darkMode
                      ? 'border-neutral-600 text-neutral-400 hover:text-white hover:border-neutral-400'
                      : 'border-[#D1C9BC] text-[#706E7B] hover:text-[#1F1B4D] hover:border-[#706E7B]'
                  }`}
                  aria-label="Daily Vocab Information"
                >
                  <span className="text-[11px] font-serif font-bold italic">i</span>
                </button>
                <button
                  type="button"
                  onClick={() => onNavigate('vocab-deck')}
                  className="bg-[#FF6B2C] hover:bg-[#E8591C] active:scale-95 text-white font-bold text-[12px] px-3 py-1 rounded-lg flex items-center gap-1 shadow-xs transition-all cursor-pointer"
                >
                  {isVocabCompleted ? (
                    <>
                      <Check className="w-3 h-3 stroke-[3]" />
                      <span>Review</span>
                    </>
                  ) : (
                    <>
                      <Play className="w-3 h-3 fill-current" />
                      <span>Start</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>

          {/* Vocab terms row with plain grey chevrons without outlines */}
          <div className="flex items-center gap-1 pt-0.5">
            {/* Left chevron: grey chevron without outline */}
            {canScrollLeft && (
              <button
                type="button"
                onClick={scrollWordsLeft}
                className="shrink-0 p-0.5 text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-200 transition-colors cursor-pointer"
                aria-label="Scroll left"
                title="Scroll left"
              >
                <ChevronLeft className="w-5 h-5 text-neutral-400" />
              </button>
            )}

            <div
              ref={wordsScrollRef}
              onScroll={handleWordsScroll}
              className="flex-1 flex items-center gap-1.5 overflow-x-auto no-scrollbar scroll-smooth py-0.5"
              style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
            >
              {DAILY_SPANISH_VOCAB.map((word) => {
                const isFamiliar = word.splitType === 'review';
                return (
                  <div
                    key={word.id}
                    className={`shrink-0 px-2.5 py-1 rounded-lg border flex items-center gap-1 text-[11px] font-bold transition-all ${
                      isFamiliar
                        ? darkMode
                          ? 'bg-[#19C3B1]/10 border-[#19C3B1]/30 text-[#2DD4BF]'
                          : 'bg-[#E6F9F6] border-[#19C3B1]/40 text-[#0E7A6E]'
                        : darkMode
                        ? 'bg-[#FF6B2C]/10 border-[#FF6B2C]/30 text-[#FB923C]'
                        : 'bg-[#FFF3EC] border-[#FF6B2C]/40 text-[#C84814]'
                    }`}
                    title={`${word.spanish}: ${word.english}`}
                  >
                    <span
                      className={`w-1.5 h-1.5 rounded-full shrink-0 ${
                        isFamiliar ? 'bg-[#19C3B1]' : 'bg-[#FF6B2C]'
                      }`}
                    />
                    <span>{word.spanish}</span>
                  </div>
                );
              })}
            </div>

            {/* Right chevron: grey chevron without outline */}
            <button
              type="button"
              onClick={scrollWordsRight}
              className="shrink-0 p-0.5 text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-200 transition-colors cursor-pointer"
              aria-label="Scroll right"
              title="Scroll right"
            >
              <ChevronRight className="w-5 h-5 text-neutral-400" />
            </button>
          </div>
        </div>

        {/* 3. SECTION HEADER: TODAY'S GAMES */}
        <div
          className={`flex items-center justify-between pt-1 ${
            darkMode ? 'text-neutral-400' : 'text-[#706E7B]'
          }`}
        >
          <span className="text-[11px] font-bold tracking-wider uppercase">
            TODAY'S GAMES
          </span>
          <span className="text-[12px] font-bold font-mono">
            {completedGamesCount}/3
          </span>
        </div>

        {/* 4. GAME 1: CONNECTIONS */}
        <div
          className={`rounded-[20px] p-3.5 border shadow-xs space-y-2.5 ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <div className="flex items-center justify-between">
            <div>
              <h3
                className={`text-[19px] sm:text-[20px] font-extrabold tracking-tight leading-tight ${
                  darkMode ? 'text-white' : 'text-[#1F1B4D]'
                }`}
              >
                Connections
              </h3>
            </div>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                onClick={() => setActiveInfoModal('connections')}
                className={`w-5.5 h-5.5 rounded-full border flex items-center justify-center transition-colors cursor-pointer ${
                  darkMode
                    ? 'border-neutral-600 text-neutral-400 hover:text-white hover:border-neutral-400'
                    : 'border-[#D1C9BC] text-[#706E7B] hover:text-[#1F1B4D] hover:border-[#706E7B]'
                }`}
                aria-label="Connections Information"
              >
                <span className="text-[11px] font-serif font-bold italic">i</span>
              </button>
              <button
                type="button"
                onClick={() => onNavigate('game-connections')}
                className={`active:scale-95 text-white font-bold text-[11px] px-2.5 py-1 rounded-lg flex items-center gap-1 shadow-xs transition-all cursor-pointer ${
                  darkMode
                    ? 'bg-[#151238] hover:bg-[#241F58]'
                    : 'bg-[#1F1B4D] hover:bg-[#2A2566]'
                }`}
              >
                {completedIds.includes('game-connections') ? (
                  <>
                    <Check className="w-2.5 h-2.5 stroke-[3] text-[#3DDC84]" />
                    <span>Solved</span>
                  </>
                ) : (
                  <>
                    <Play className="w-2.5 h-2.5 fill-current" />
                    <span>Play</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* 4x4 Pill Tiles Preview */}
          <div className="grid grid-cols-4 gap-1.5 pt-0.5">
            {[0, 1, 2, 3].map((i) => (
              <div
                key={`conn-r1-${i}`}
                className="h-5 rounded-md bg-[#7B5CFF] text-white/90 flex items-center justify-center font-bold text-[10px] tracking-widest select-none shadow-2xs"
              >
                ···
              </div>
            ))}
            {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map((i) => (
              <div
                key={`conn-rest-${i}`}
                className={`h-5 rounded-md flex items-center justify-center font-bold text-[10px] tracking-widest select-none ${
                  darkMode
                    ? 'bg-[#2E2866] text-[#A09CA8]'
                    : 'bg-[#F0EAE0] text-[#8C867B]'
                }`}
              >
                ···
              </div>
            ))}
          </div>
        </div>

        {/* 5. GAME 2: WORD GUESS */}
        <div
          className={`rounded-[20px] p-3.5 border shadow-xs space-y-2.5 ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <div className="flex items-center justify-between">
            <div>
              <h3
                className={`text-[19px] sm:text-[20px] font-extrabold tracking-tight leading-tight ${
                  darkMode ? 'text-white' : 'text-[#1F1B4D]'
                }`}
              >
                Word Guess
              </h3>
            </div>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                onClick={() => setActiveInfoModal('word-guess')}
                className={`w-5.5 h-5.5 rounded-full border flex items-center justify-center transition-colors cursor-pointer ${
                  darkMode
                    ? 'border-neutral-600 text-neutral-400 hover:text-white hover:border-neutral-400'
                    : 'border-[#D1C9BC] text-[#706E7B] hover:text-[#1F1B4D] hover:border-[#706E7B]'
                }`}
                aria-label="Word Guess Information"
              >
                <span className="text-[11px] font-serif font-bold italic">i</span>
              </button>
              <button
                type="button"
                onClick={() => onNavigate('game-word-guess')}
                className={`active:scale-95 text-white font-bold text-[11px] px-2.5 py-1 rounded-lg flex items-center gap-1 shadow-xs transition-all cursor-pointer ${
                  darkMode
                    ? 'bg-[#151238] hover:bg-[#241F58]'
                    : 'bg-[#1F1B4D] hover:bg-[#2A2566]'
                }`}
              >
                {completedIds.includes('game-word-guess') ? (
                  <>
                    <Check className="w-2.5 h-2.5 stroke-[3] text-[#3DDC84]" />
                    <span>Solved</span>
                  </>
                ) : (
                  <>
                    <Play className="w-2.5 h-2.5 fill-current" />
                    <span>Play</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* 6 Letter Tiles Row */}
          <div className="flex items-center justify-center gap-1.5 py-0.5 max-w-[240px] mx-auto w-full">
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <div
                key={`wg-tile-${i}`}
                className={`flex-1 aspect-square max-w-[32px] rounded-lg shadow-2xs ${
                  darkMode
                    ? 'border-2 border-white/60 bg-transparent'
                    : 'border-2 border-[#1F1B4D] bg-white'
                }`}
              />
            ))}
          </div>
        </div>

        {/* 6. GAME 3: MINI CROSSWORD */}
        <div
          className={`rounded-[20px] p-3.5 border shadow-xs space-y-2.5 ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <div className="flex items-center justify-between">
            <div>
              <h3
                className={`text-[19px] sm:text-[20px] font-extrabold tracking-tight leading-tight ${
                  darkMode ? 'text-white' : 'text-[#1F1B4D]'
                }`}
              >
                Mini Crossword
              </h3>
            </div>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                onClick={() => setActiveInfoModal('crossword')}
                className={`w-5.5 h-5.5 rounded-full border flex items-center justify-center transition-colors cursor-pointer ${
                  darkMode
                    ? 'border-neutral-600 text-neutral-400 hover:text-white hover:border-neutral-400'
                    : 'border-[#D1C9BC] text-[#706E7B] hover:text-[#1F1B4D] hover:border-[#706E7B]'
                }`}
                aria-label="Mini Crossword Information"
              >
                <span className="text-[11px] font-serif font-bold italic">i</span>
              </button>
              <button
                type="button"
                onClick={() => onNavigate('game-crossword')}
                className={`active:scale-95 text-white font-bold text-[11px] px-2.5 py-1 rounded-lg flex items-center gap-1 shadow-xs transition-all cursor-pointer ${
                  darkMode
                    ? 'bg-[#151238] hover:bg-[#241F58]'
                    : 'bg-[#1F1B4D] hover:bg-[#2A2566]'
                }`}
              >
                {completedIds.includes('game-crossword') ? (
                  <>
                    <Check className="w-2.5 h-2.5 stroke-[3] text-[#3DDC84]" />
                    <span>Solved</span>
                  </>
                ) : (
                  <>
                    <Play className="w-2.5 h-2.5 fill-current" />
                    <span>Play</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* 5x5 Crossword Grid Preview */}
          <div className="flex justify-center py-0.5">
            <div
              className={`w-22 h-22 grid grid-cols-5 border shadow-2xs ${
                darkMode
                  ? 'border-[#3E3880] bg-[#1E1A46]'
                  : 'border-[#C7C0B2] bg-white'
              }`}
            >
              {[
                [false, false, false, false, true],
                [false, true, false, true, false],
                [false, false, false, false, false],
                [false, true, false, true, false],
                [false, false, false, false, false],
              ].map((row, rIdx) =>
                row.map((isDark, cIdx) => (
                  <div
                    key={`cw-${rIdx}-${cIdx}`}
                    className={`border ${
                      darkMode
                        ? isDark
                          ? 'bg-[#120F32] border-[#0A071E]'
                          : 'bg-[#2A2566] border-[#3E3880]'
                        : isDark
                        ? 'bg-[#1F1B4D] border-[#1F1B4D]'
                        : 'bg-white border-[#D1C9BC]'
                    }`}
                  />
                ))
              )}
            </div>
          </div>
        </div>

        {/* 7. PRACTICE SECTION: SKILL EXERCISES */}
        <div className="space-y-3 pt-2 pb-6">
          <div className="flex items-center justify-between">
            <div>
              <h3
                className={`font-serif text-[22px] font-bold leading-tight ${
                  darkMode ? 'text-white' : 'text-[#1F1B4D]'
                }`}
              >
                Skill Exercises
              </h3>
            </div>

            {/* Segmented Control */}
            <div
              className={`p-1 rounded-xl flex items-center gap-0.5 ${
                darkMode ? 'bg-white/10' : 'bg-[#F0EAE0]'
              }`}
            >
              {(['Easy', 'Medium', 'Hard'] as DifficultyLevel[]).map((level) => {
                const isActive = selectedDifficulty === level;
                return (
                  <button
                    key={level}
                    type="button"
                    onClick={() => onSelectDifficulty(level)}
                    className={`px-3 py-1 rounded-lg text-[12px] transition-all cursor-pointer ${
                      isActive
                        ? 'bg-[#FF6B2C] text-white font-bold shadow-xs'
                        : darkMode
                        ? 'text-neutral-300 hover:text-white font-semibold'
                        : 'text-[#615E6D] hover:text-[#1F1B4D] font-semibold'
                    }`}
                  >
                    {level}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Grouped Exercise List */}
          <div
            className={`rounded-2xl border overflow-hidden shadow-xs ${
              darkMode
                ? 'bg-[#221E52] border-white/10 divide-y divide-white/10'
                : 'bg-white border-[#1F1B4D]/10 divide-y divide-[#1F1B4D]/8'
            }`}
          >
            {[
              {
                id: 'exercise-fill-blank' as ActiveViewId,
                infoKey: 'fill-blank' as const,
                title: 'Fill in the Blank',
              },
              {
                id: 'exercise-sentence-builder' as ActiveViewId,
                infoKey: 'sentence-builder' as const,
                title: 'Sentence Builder',
              },
              {
                id: 'exercise-definition-match' as ActiveViewId,
                infoKey: 'definition-match' as const,
                title: 'Definition Match',
              },
            ].map((ex) => (
              <div
                key={ex.id}
                onClick={() => onNavigate(ex.id)}
                className={`p-4 flex items-center justify-between transition-colors cursor-pointer group ${
                  darkMode ? 'hover:bg-white/5' : 'hover:bg-[#FAF6EE]'
                }`}
              >
                <div>
                  <h4
                    className={`text-[15px] font-bold group-hover:text-[#FF6B2C] transition-colors ${
                      darkMode ? 'text-white' : 'text-[#1F1B4D]'
                    }`}
                  >
                    {ex.title}
                  </h4>
                </div>

                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    setActiveInfoModal(ex.infoKey);
                  }}
                  className={`text-[13px] font-medium flex items-center gap-1 transition-colors px-2 py-1 rounded-lg cursor-pointer ${
                    darkMode
                      ? 'text-neutral-400 hover:text-[#FF6B2C] hover:bg-white/10'
                      : 'text-[#706E7B] hover:text-[#FF6B2C] hover:bg-[#F0EAE0]'
                  }`}
                >
                  <span>About</span>
                  <ArrowUpRight className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 8. MINIMAL LEVEL PROGRESS MODAL (Only what is absolutely necessary) */}
      {isLevelModalOpen && (
        <div
          className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setIsLevelModalOpen(false)}
        >
          <div
            className={`w-full max-w-xs rounded-2xl p-5 shadow-2xl border space-y-3.5 animate-scale-bounce ${
              darkMode
                ? 'bg-[#1E1A46] text-white border-white/10'
                : 'bg-white text-[#1F1B4D] border-neutral-200'
            }`}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1.5 font-serif text-[18px] font-bold">
                <span role="img" aria-label="Spain flag">
                  🇪🇸
                </span>
                <span>Level {currentLevel}</span>
              </div>
              <button
                type="button"
                onClick={() => setIsLevelModalOpen(false)}
                className="w-7 h-7 rounded-full border border-neutral-200 dark:border-neutral-700 flex items-center justify-center text-neutral-400 hover:text-neutral-700 cursor-pointer transition-colors"
                aria-label="Close"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>

            <div className="space-y-1.5">
              <p className="text-sm font-bold text-[#FF6B2C]">
                {xpNeeded} XP to Level {currentLevel + 1}
              </p>
              <div
                className={`w-full h-2 rounded-full overflow-hidden ${
                  darkMode ? 'bg-white/10' : 'bg-[#EAE4D8]'
                }`}
              >
                <div
                  className="bg-gradient-to-r from-[#19C3B1] via-[#7B5CFF] to-[#FF6B2C] h-full rounded-full transition-all duration-300"
                  style={{
                    width: `${Math.min(
                      100,
                      Math.max(5, Math.round((currentLevelXP / 1500) * 100))
                    )}%`,
                  }}
                />
              </div>
              <div className="flex justify-between text-[11px] text-neutral-500 dark:text-neutral-400 font-medium">
                <span>{currentLevelXP} XP</span>
                <span>1,500 XP</span>
              </div>
            </div>

            <button
              type="button"
              onClick={() => setIsLevelModalOpen(false)}
              className="w-full py-2.5 rounded-xl bg-[#1F1B4D] hover:bg-[#2A2566] text-white font-bold text-xs transition-colors cursor-pointer"
            >
              Got it
            </button>
          </div>
        </div>
      )}

      {/* 9. INTERACTIVE INFO MODAL SHEET (For (i) and About ↗) */}
      {activeInfoModal && infoModalDetails[activeInfoModal] && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-[#1E1A46] text-[#1F1B4D] dark:text-white rounded-[28px] max-w-sm w-full p-6 shadow-2xl border border-neutral-200 dark:border-white/10 space-y-4 animate-scale-bounce">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-[#FF6B2C]/15 text-[#FF6B2C]">
                  {infoModalDetails[activeInfoModal].badge}
                </span>
                <h3 className="font-serif text-[20px] font-bold mt-1.5 leading-snug">
                  {infoModalDetails[activeInfoModal].title}
                </h3>
                <p className="text-xs text-neutral-500 dark:text-neutral-400">
                  {infoModalDetails[activeInfoModal].subtitle}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setActiveInfoModal(null)}
                className="w-8 h-8 rounded-full border border-neutral-200 dark:border-neutral-700 hover:bg-neutral-100 dark:hover:bg-white/10 flex items-center justify-center text-neutral-500 cursor-pointer transition-colors"
                aria-label="Close modal"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-[13px] text-neutral-700 dark:text-neutral-300 leading-relaxed">
              {infoModalDetails[activeInfoModal].description}
            </p>

            <div className="p-3 rounded-xl bg-[#FFF8EC] dark:bg-white/5 border border-amber-200/50 dark:border-white/10 text-xs text-neutral-700 dark:text-neutral-300 space-y-1">
              <span className="font-bold text-[#FF6B2C] block">Pro Tip</span>
              <p>{infoModalDetails[activeInfoModal].tip}</p>
            </div>

            <div className="flex items-center justify-between pt-1 text-xs">
              <span className="text-neutral-500 dark:text-neutral-400 font-medium">
                Reward
              </span>
              <span className="font-bold text-[#FF6B2C]">
                {infoModalDetails[activeInfoModal].xpReward}
              </span>
            </div>

            <button
              type="button"
              onClick={() => {
                const target = infoModalDetails[activeInfoModal].targetView;
                setActiveInfoModal(null);
                onNavigate(target);
              }}
              className="w-full py-3 rounded-xl bg-[#FF6B2C] hover:bg-[#E8591C] active:scale-98 text-white font-bold text-sm flex items-center justify-center gap-2 shadow-sm transition-all cursor-pointer"
            >
              <Play className="w-4 h-4 fill-current" />
              <span>{infoModalDetails[activeInfoModal].actionLabel}</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
