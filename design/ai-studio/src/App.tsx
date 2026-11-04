import React, { useState, useEffect } from 'react';
import {
  ActiveViewId,
  DAILY_SPANISH_VOCAB,
  DifficultyLevel,
  FriendHighlight,
  MainTabId,
  SessionReviewData,
  UserStats,
} from './types';
import {
  BottomNavBar,
  ThemeContext,
  playCelebrationSound,
} from './components/common/HiFiElements';
import { DeviceFrame } from './components/DeviceFrame';
import { WireframeToolbar } from './components/WireframeToolbar';
import { DesignDocModal } from './components/DesignDocModal';
import { RulesModal } from './components/RulesModal';
import { LevelUpModal } from './components/LevelUpModal';
import { Page01Progress } from './pages/Page01Progress';
import { Page02Friends } from './pages/Page02Friends';
import { Page03Daily } from './pages/Page03Daily';
import { Page04Settings } from './pages/Page04Settings';
import { PageOnboarding } from './pages/PageOnboarding';
import { GamesAndExercises } from './pages/GamesAndExercises';

const INITIAL_HIGHLIGHTS: FriendHighlight[] = [
  {
    id: 'fh-1',
    userName: 'Maya Lin',
    userHandle: '@maya',
    avatarInitials: 'ML',
    avatarBg: '#254441',
    type: 'fill-in',
    timestamp: '28m',
    badgeText: 'Best Fill-In of the Day',
    contentEs:
      'En nuestra sobremesa nunca falta un cortado bien cargado y risas.',
    contentEn: '',
    likes: 18,
    likedByMe: true,
  },
  {
    id: 'fh-2',
    userName: 'Lucas Chen',
    userHandle: '@lucas',
    avatarInitials: 'LC',
    avatarBg: '#5CA4A9',
    type: 'game-score',
    timestamp: '1h',
    badgeText: 'Conexiones · 4/4',
    contentEs: '¡Resolví las 4 categorías sin ningún error!',
    contentEn: '',
    likes: 11,
    likedByMe: false,
  },
  {
    id: 'fh-3',
    userName: 'Elena Vance',
    userHandle: '@elena',
    avatarInitials: 'EV',
    avatarBg: '#D74E09',
    type: 'achievement',
    timestamp: '3h',
    badgeText: '250 Words Mastered',
    contentEs: 'Tómate tu tiempo para saborear cada sorbo.',
    contentEn: '',
    likes: 9,
    likedByMe: false,
  },
];

const DEFAULT_USER_STATS: UserStats = {
  totalXP: 1470, // Exactly 30 XP away from 1,500 XP! Finishing the Daily Vocab Lesson (+30 XP) immediately levels up to Level 2!
  totalScore: 850,
  streakCount: 14,
  streakCountedToday: false,
  lastActiveDate: new Date().toISOString().split('T')[0],
};

export default function App() {
  const [activeView, setActiveView] = useState<ActiveViewId>(() => {
    try {
      const isCompleted = localStorage.getItem('fluentish_onboarding_completed');
      if (isCompleted !== 'true') return 'onboarding';
    } catch {
      // ignore
    }
    return 'daily';
  });
  const [darkMode, setDarkMode] = useState<boolean>(false);

  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [darkMode]);

  const [isDeviceMode, setIsDeviceMode] = useState<boolean>(true);
  const [isDesignDocOpen, setIsDesignDocOpen] = useState<boolean>(false);
  const [isRulesModalOpen, setIsRulesModalOpen] = useState<boolean>(false);
  const [levelUpData, setLevelUpData] = useState<{
    newLevel: number;
    totalXP: number;
  } | null>(null);

  const [celebratedIds, setCelebratedIds] = useState<string[]>([]);
  const [selectedDifficulty, setSelectedDifficulty] =
    useState<DifficultyLevel>('Medium');
  const [completedIds, setCompletedIds] = useState<string[]>([]);
  const [highlights, setHighlights] =
    useState<FriendHighlight[]>(INITIAL_HIGHLIGHTS);

  // Persistent User Progression Stats (Streak, Level at 1500 XP, Score & XP)
  const [userStats, setUserStats] = useState<UserStats>(() => {
    try {
      const saved = localStorage.getItem('fluentish_user_stats');
      if (saved) return JSON.parse(saved);
    } catch {
      // ignore
    }
    return DEFAULT_USER_STATS;
  });

  useEffect(() => {
    try {
      localStorage.setItem('fluentish_user_stats', JSON.stringify(userStats));
    } catch {
      // ignore
    }
  }, [userStats]);

  const [lastReviewData, setLastReviewData] = useState<SessionReviewData>({
    sourceId: 'game-connections',
    title: 'Conexiones',
    subtitle: '4/4 Groups',
    scoreLabel: '100 pts',
    accuracy: '95%',
    timeSpent: '1m 42s',
    streakEarned: true,
    spanishTipTitle: 'Sin embargo vs Aunque',
    spanishTipBody:
      'Use "sin embargo" (however) between sentences and "aunque" (although) inside a clause.',
    wordsPracticed: DAILY_SPANISH_VOCAB.slice(0, 4),
    xpEarned: 40,
    pointsScore: 100,
  });

  const getActiveMainTab = (): MainTabId => {
    if (activeView === 'progress') return 'progress';
    if (activeView === 'friends') return 'friends';
    if (activeView === 'settings') return 'settings';
    return 'daily';
  };

  /**
   * Rule 1: A day counts when a game or lesson is finished.
   * Rule 2: Users level up at 1,500 XP.
   * Rule 3: Each game gives a score and XP.
   */
  const handleFinishSession = (data: SessionReviewData) => {
    const xpEarned = data.xpEarned || 40;
    const pointsScore = data.pointsScore || 100;

    // Rule 1: Streak counting
    const isNewStreakDay = !userStats.streakCountedToday;
    const nextStreakCount = isNewStreakDay
      ? userStats.streakCount + 1
      : userStats.streakCount;

    // Rule 2: Level up at 1500 XP
    const currentLevel = Math.floor(userStats.totalXP / 1500) + 1;
    const newTotalXP = userStats.totalXP + xpEarned;
    const newLevel = Math.floor(newTotalXP / 1500) + 1;
    const didLevelUp = newLevel > currentLevel;

    // Rule 3: Cumulative score
    const newTotalScore = userStats.totalScore + pointsScore;

    const nextStats: UserStats = {
      totalXP: newTotalXP,
      totalScore: newTotalScore,
      streakCount: nextStreakCount,
      streakCountedToday: true,
      lastActiveDate: new Date().toISOString().split('T')[0],
    };

    setUserStats(nextStats);

    const enrichedData: SessionReviewData = {
      ...data,
      xpEarned,
      pointsScore,
      isNewStreakDay,
      leveledUp: didLevelUp,
      newLevel,
      totalXP: newTotalXP,
    };

    setLastReviewData(enrichedData);

    if (!completedIds.includes(data.sourceId)) {
      setCompletedIds([...completedIds, data.sourceId]);
    }

    if (didLevelUp) {
      playCelebrationSound();
      setLevelUpData({ newLevel, totalXP: newTotalXP });
    }

    setActiveView('session-review');
  };

  const handleAddHighlight = (newPost: FriendHighlight) => {
    setHighlights([newPost, ...highlights]);
  };

  const handleToggleLike = (id: string) => {
    setHighlights(
      highlights.map((item) =>
        item.id === id
          ? {
              ...item,
              likedByMe: !item.likedByMe,
              likes: item.likedByMe ? item.likes - 1 : item.likes + 1,
            }
          : item
      )
    );
  };

  const handleCompleteOnboarding = (prefs?: any) => {
    try {
      localStorage.setItem('fluentish_onboarding_completed', 'true');
      if (prefs) {
        localStorage.setItem('fluentish_user_preferences', JSON.stringify(prefs));
      }
    } catch {
      // ignore
    }
    setActiveView('daily');
  };

  const handleResetAll = () => {
    try {
      localStorage.removeItem('fluentish_onboarding_completed');
    } catch {
      // ignore
    }
    setActiveView('onboarding');
    setCompletedIds([]);
    setCelebratedIds([]);
    setSelectedDifficulty('Medium');
    setHighlights(INITIAL_HIGHLIGHTS);
    setUserStats(DEFAULT_USER_STATS);
  };

  const currentLevel = Math.floor(userStats.totalXP / 1500) + 1;

  return (
    <ThemeContext.Provider value={{ darkMode, setDarkMode }}>
      <div
        className={`min-h-screen flex flex-col transition-colors ${
          darkMode
            ? 'bg-[#17143A] text-[#FFF8EC]'
            : 'bg-[#FFF8EC] text-[#1F1B4D]'
        }`}
      >
        <WireframeToolbar
          activeView={activeView}
          onSelectView={setActiveView}
          isDeviceMode={isDeviceMode}
          onToggleDeviceMode={() => setIsDeviceMode(!isDeviceMode)}
          onOpenDesignDoc={() => setIsDesignDocOpen(true)}
          onOpenRules={() => setIsRulesModalOpen(true)}
          onResetAll={handleResetAll}
        />

        {/* Centered, Spacious Canvas — No Cluttered Sidebars */}
        <main className="flex-1 w-full max-w-5xl mx-auto px-4 py-6 flex items-center justify-center">
          <DeviceFrame
            isDeviceMode={isDeviceMode}
            bottomBar={
              activeView !== 'onboarding' ? (
                <BottomNavBar
                  activeTab={getActiveMainTab()}
                  onSelectTab={(tab) => setActiveView(tab)}
                />
              ) : undefined
            }
          >
            {activeView === 'onboarding' && (
              <PageOnboarding
                onComplete={handleCompleteOnboarding}
                onNavigate={setActiveView}
              />
            )}

            {activeView === 'progress' && (
              <Page01Progress
                onNavigate={setActiveView}
                selectedDifficulty={selectedDifficulty}
                onSelectDifficulty={setSelectedDifficulty}
                userStats={userStats}
                onOpenRules={() => setIsRulesModalOpen(true)}
              />
            )}

            {activeView === 'friends' && (
              <Page02Friends
                highlights={highlights}
                onAddHighlight={handleAddHighlight}
                onToggleLike={handleToggleLike}
                userStats={userStats}
                onOpenRules={() => setIsRulesModalOpen(true)}
              />
            )}

            {(activeView === 'daily' || activeView === 'vocab-deck') && (
              <Page03Daily
                activeView={activeView}
                onNavigate={setActiveView}
                completedIds={completedIds}
                selectedDifficulty={selectedDifficulty}
                onSelectDifficulty={setSelectedDifficulty}
                onCompleteVocabDeck={handleFinishSession}
                userStats={userStats}
                onOpenRules={() => setIsRulesModalOpen(true)}
              />
            )}

            {activeView === 'settings' && (
              <Page04Settings
                onResetProgress={() => {
                  setCompletedIds([]);
                  setUserStats({
                    ...userStats,
                    streakCountedToday: false,
                  });
                }}
                userStats={userStats}
                onNavigate={setActiveView}
                onOpenRules={() => setIsRulesModalOpen(true)}
              />
            )}

            {(activeView === 'game-connections' ||
              activeView === 'game-word-guess' ||
              activeView === 'game-crossword' ||
              activeView === 'exercise-fill-blank' ||
              activeView === 'exercise-sentence-builder' ||
              activeView === 'exercise-definition-match' ||
              activeView === 'session-review') && (
              <GamesAndExercises
                activeView={activeView}
                difficulty={selectedDifficulty}
                reviewData={lastReviewData}
                onNavigate={setActiveView}
                onFinishSession={handleFinishSession}
                onShareToFriends={handleAddHighlight}
                celebratedIds={celebratedIds}
                onMarkCelebrated={(id: string) =>
                  setCelebratedIds((prev) =>
                    prev.includes(id) ? prev : [...prev, id]
                  )
                }
                userStats={userStats}
              />
            )}
          </DeviceFrame>
        </main>

        {/* Streak, Level & Score Rules Modal */}
        <RulesModal
          isOpen={isRulesModalOpen}
          onClose={() => setIsRulesModalOpen(false)}
          totalXP={userStats.totalXP}
          streakCount={userStats.streakCount}
          streakCountedToday={userStats.streakCountedToday}
          level={currentLevel}
        />

        {/* Level Up at 1500 XP Milestone Modal */}
        <LevelUpModal
          isOpen={levelUpData !== null}
          newLevel={levelUpData?.newLevel || 2}
          totalXP={levelUpData?.totalXP || 1500}
          onClose={() => setLevelUpData(null)}
        />

        <DesignDocModal
          isOpen={isDesignDocOpen}
          onClose={() => setIsDesignDocOpen(false)}
        />
      </div>
    </ThemeContext.Provider>
  );
}
