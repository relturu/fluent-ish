import React, { useState } from 'react';
import {
  Check,
  Shuffle,
  Delete,
  Sparkles,
  Share2,
  ArrowRight,
  RotateCcw,
  Eye,
} from 'lucide-react';
import {
  ActiveViewId,
  DAILY_SPANISH_VOCAB,
  DifficultyLevel,
  FriendHighlight,
  SessionReviewData,
  UserStats,
} from '../types';
import {
  HiFiButton,
  GameHeaderBar,
  GameAssistModal,
  AudioButton,
  ConfettiBurst,
  CountUpNumber,
  useTheme,
} from '../components/common/HiFiElements';
import {
  ChurroMascot,
  MascotEncouragementToast,
  getRandomEncouragingCheer,
} from '../components/common/Mascot';

interface CategoryGroup {
  id: string;
  title: string;
  words: string[];
  translations: { es: string; en: string }[];
  bgClass: string;
  textClass: string;
}

const CONNECTIONS_GROUPS: CategoryGroup[] = [
  {
    id: 'cg1',
    title: 'Café & Sobremesa',
    words: ['CORTADO', 'SOBREMESA', 'MERIENDA', 'TERRAZA'],
    translations: [
      { es: 'CORTADO', en: 'espresso with a dash of warm milk' },
      { es: 'SOBREMESA', en: 'unhurried conversation after a meal' },
      { es: 'MERIENDA', en: 'late-afternoon coffee or snack' },
      { es: 'TERRAZA', en: 'outdoor café seating or patio' },
    ],
    bgClass: 'bg-[#FFC93C]',
    textClass: 'text-[#1F1B4D]',
  },
  {
    id: 'cg2',
    title: 'Connectors · Conectores',
    words: ['ADEMÁS', 'AUNQUE', 'MIENTRAS', 'INCLUSO'],
    translations: [
      { es: 'ADEMÁS', en: 'furthermore / in addition' },
      { es: 'AUNQUE', en: 'although / even though' },
      { es: 'MIENTRAS', en: 'while / in the meantime' },
      { es: 'INCLUSO', en: 'even / including' },
    ],
    bgClass: 'bg-[#19C3B1]',
    textClass: 'text-[#1F1B4D]',
  },
  {
    id: 'cg3',
    title: 'Table Verbs · Verbos de Mesa',
    words: ['CHARLAR', 'COMPARTIR', 'SABOREAR', 'BRINDAR'],
    translations: [
      { es: 'CHARLAR', en: 'to chat / have a friendly talk' },
      { es: 'COMPARTIR', en: 'to share food and stories' },
      { es: 'SABOREAR', en: 'to savor every bite or sip' },
      { es: 'BRINDAR', en: 'to make a celebratory toast' },
    ],
    bgClass: 'bg-[#7B5CFF]',
    textClass: 'text-white',
  },
  {
    id: 'cg4',
    title: 'Cozy Vibes · Ambiente Acogedor',
    words: ['ACOGEDOR', 'CÁLIDO', 'TRANQUILO', 'AMENO'],
    translations: [
      { es: 'ACOGEDOR', en: 'cozy / welcoming / snug' },
      { es: 'CÁLIDO', en: 'warm / friendly ambiance' },
      { es: 'TRANQUILO', en: 'peaceful / unhurried' },
      { es: 'AMENO', en: 'pleasant / delightful / engaging' },
    ],
    bgClass: 'bg-[#FF6B2C]',
    textClass: 'text-white',
  },
];

// All 16 words shuffled for the 4x4 Connections grid (4 rows of 4 cards)
const CONNECTIONS_INITIAL_WORDS: string[] = [
  'SOBREMESA', 'ADEMÁS', 'CHARLAR', 'ACOGEDOR',
  'CORTADO', 'AUNQUE', 'COMPARTIR', 'CÁLIDO',
  'MERIENDA', 'MIENTRAS', 'SABOREAR', 'TRANQUILO',
  'TERRAZA', 'INCLUSO', 'BRINDAR', 'AMENO',
];

const CROSSWORD_SOLUTION: string[][] = [
  ['C', 'A', 'F', 'E', '#'],
  ['O', '#', 'L', '#', 'S'],
  ['R', 'I', 'O', 'S', 'O'],
  ['T', '#', 'R', '#', 'L'],
  ['A', 'M', 'I', 'G', 'O'],
];

export function GamesAndExercises({
  activeView,
  difficulty,
  reviewData,
  onNavigate,
  onFinishSession,
  onShareToFriends,
  celebratedIds = [],
  onMarkCelebrated,
  userStats,
}: {
  activeView: ActiveViewId;
  difficulty: DifficultyLevel;
  reviewData: SessionReviewData | null;
  onNavigate: (view: ActiveViewId) => void;
  onFinishSession: (data: SessionReviewData) => void;
  onShareToFriends: (highlight: FriendHighlight) => void;
  celebratedIds?: string[];
  onMarkCelebrated?: (id: string) => void;
  userStats?: UserStats;
}) {
  const { darkMode } = useTheme();
  const [assistModal, setAssistModal] = useState<'how-to' | 'hint' | null>(null);

  // Full-screen celebration state (strictly shown once per solved puzzle)
  const [showConfetti, setShowConfetti] = useState(false);
  const [confettiMessage, setConfettiMessage] = useState<string | undefined>(undefined);

  const triggerCelebrationOnce = (puzzleId: string, msg?: string) => {
    // If the user has already solved this puzzle once, never show confetti again
    if (celebratedIds.includes(puzzleId)) {
      return;
    }
    onMarkCelebrated?.(puzzleId);
    setConfettiMessage(msg);
    setShowConfetti(false);
    requestAnimationFrame(() => {
      setShowConfetti(true);
    });
  };

  // Gentle mascot encouragement reaction for mistakes / incorrect guesses
  const [encouragementMsg, setEncouragementMsg] = useState<string | null>(null);

  const triggerEncouragement = (customMsg?: string) => {
    setEncouragementMsg(customMsg || getRandomEncouragingCheer());
    setTimeout(() => {
      setEncouragementMsg(null);
    }, 2400);
  };

  // 1. CONNECTIONS — All 16 words active initially in a full 4x4 grid (4 rows of 4 cards)
  const [connSolvedIds, setConnSolvedIds] = useState<string[]>([]);
  const [connSelected, setConnSelected] = useState<string[]>([]);
  const [connMistakes, setConnMistakes] = useState<number>(0);
  const [showAnswersModal, setShowAnswersModal] = useState<boolean>(false);
  const [connFeedback, setConnFeedback] = useState<string | null>(null);
  const [connIsShaking, setConnIsShaking] = useState<boolean>(false);
  const [connPoppingWord, setConnPoppingWord] = useState<string | null>(null);

  // 2. WORD GUESS (Target: CHARLA)
  const TARGET_WORD = 'CHARLA';
  const [wgGuesses, setWgGuesses] = useState<string[]>(['CAMINO', 'CORTAR']);
  const [wgCurrent, setWgCurrent] = useState<string>('');
  const [wgIsShaking, setWgIsShaking] = useState<boolean>(false);

  // 3. MINI CROSSWORD
  const [cwGrid, setCwGrid] = useState<string[][]>([
    ['C', 'A', 'F', 'E', '#'],
    ['O', '#', 'L', '#', 'S'],
    ['R', 'I', 'O', 'S', 'O'],
    ['T', '#', 'R', '#', 'L'],
    ['A', 'M', 'I', 'G', 'O'],
  ]);
  const [cwCell, setCwCell] = useState<{ r: number; c: number }>({ r: 0, c: 0 });
  const [cwCompleted, setCwCompleted] = useState<boolean>(false);

  // 4. FILL IN THE BLANK
  const [fitbIndex, setFitbIndex] = useState<number>(0);
  const [fitbChoice, setFitbChoice] = useState<number | null>(null);
  const [fitbShaking, setFitbShaking] = useState<boolean>(false);

  // 5. SENTENCE BUILDER
  const builderTarget = ['Nos', 'encanta', 'charlar', 'en', 'la', 'sobremesa'];
  const [builderPicked, setBuilderPicked] = useState<string[]>(['Nos', 'encanta']);

  // 6. DEFINITION MATCH
  const initialMatchPairs = [
    { es: 'la sobremesa', en: 'table talk' },
    { es: 'el cortado', en: 'espresso + milk' },
    { es: 'sin embargo', en: 'however' },
    { es: 'acogedor', en: 'cozy' },
    { es: 'saborear', en: 'to savor' },
  ];
  const [matchedEs, setMatchedEs] = useState<string[]>(['la sobremesa']);
  const [pickedEs, setPickedEs] = useState<string | null>(null);
  const [pickedEn, setPickedEn] = useState<string | null>(null);
  const [matchShaking, setMatchShaking] = useState<boolean>(false);

  // Review state
  const [sharedSuccess, setSharedSuccess] = useState<boolean>(false);

  // ----------------------------------------------------------------------------
  // POST-GAME REVIEW SCREEN ('session-review')
  // ----------------------------------------------------------------------------
  if (activeView === 'session-review' && reviewData) {
    const isDailyGame =
      reviewData.sourceId === 'game-connections' ||
      reviewData.sourceId === 'game-word-guess' ||
      reviewData.sourceId === 'game-crossword';

    const handleShareReview = () => {
      onShareToFriends({
        id: `rev-${Date.now()}`,
        userName: 'Sofía',
        userHandle: '@sofia',
        avatarInitials: 'SM',
        avatarBg: '#FF6B2C',
        type: 'game-score',
        timestamp: 'Now',
        badgeText: `${reviewData.title} · ${reviewData.scoreLabel}`,
        contentEs: `¡Completé ${reviewData.title} con ${reviewData.accuracy}!`,
        contentEn: '',
        likes: 1,
        likedByMe: true,
        isCurrentUser: true,
      });
      setSharedSuccess(true);
      setTimeout(() => setSharedSuccess(false), 2000);
    };

    return (
      <div className="flex flex-col flex-1 relative">
        <GameHeaderBar
          title="Result"
          onOpenHowToPlay={() => setAssistModal('how-to')}
          onOpenHint={() => setAssistModal('hint')}
          onBack={() => onNavigate(isDailyGame ? reviewData.sourceId : 'daily')}
        />

        <div className="px-4 py-6 space-y-6 flex-1 flex flex-col justify-between">
          <div className="space-y-5">
            {/* Clean Result Card with Score Count-Up and Celebrating Churro */}
            <div
              className={`p-6 rounded-[26px] border text-center space-y-3 shadow-xs animate-scale-bounce transition-colors ${
                darkMode
                  ? 'bg-[#221E52] border-white/10'
                  : 'bg-white border-[#1F1B4D]/10'
              }`}
            >
              <div className="flex justify-center -mt-2 mb-1">
                <ChurroMascot
                  mood="celebrating"
                  size="md"
                  speech="¡Increíble jugada! ¡Estás que te sales! 🎉"
                  speechPosition="top"
                />
              </div>

              <div className="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full bg-[#3DDC84]/15 text-[#3DDC84] border border-[#3DDC84]/30 text-[11px] font-extrabold uppercase tracking-wide">
                <span>Nice! Solved</span>
              </div>

              <h2 className="type-display">{reviewData.title}</h2>

              {/* Animated XP Count-Up & Score Notice */}
              <div className="flex items-center justify-center gap-3">
                <span className="text-[14px] font-extrabold text-[#FF6B2C] tabular-nums bg-[#FF6B2C]/10 px-3 py-1 rounded-full border border-[#FF6B2C]/20">
                  +<CountUpNumber target={reviewData.xpEarned || 40} duration={800} /> XP Earned
                </span>
                <span className="text-[14px] font-extrabold text-[#19C3B1] tabular-nums bg-[#19C3B1]/10 px-3 py-1 rounded-full border border-[#19C3B1]/20">
                  {reviewData.pointsScore ? `${reviewData.pointsScore} Pts` : reviewData.scoreLabel}
                </span>
              </div>

              {/* Score / Accuracy / Time Breakdown */}
              <div className="grid grid-cols-3 gap-3 pt-4 border-t border-current/10">
                <div>
                  <span className="type-h2 text-[#FF6B2C] block tabular-nums">
                    {reviewData.scoreLabel}
                  </span>
                  <span className="text-[11px] opacity-60 font-bold uppercase tracking-wider">
                    Score
                  </span>
                </div>
                <div>
                  <span className="type-h2 text-[#3DDC84] block tabular-nums">
                    {reviewData.accuracy}
                  </span>
                  <span className="text-[11px] opacity-60 font-bold uppercase tracking-wider">
                    Accuracy
                  </span>
                </div>
                <div>
                  <span className="type-h2 block tabular-nums">
                    {reviewData.timeSpent}
                  </span>
                  <span className="text-[11px] opacity-60 font-bold uppercase tracking-wider">
                    Time
                  </span>
                </div>
              </div>

              {/* Streak and Level Rules Status */}
              <div className="pt-3 border-t border-current/10 space-y-1.5 text-left">
                <div className="flex items-center justify-between text-[12px] font-bold">
                  <span className="text-[#FF6B2C] flex items-center gap-1">
                    🔥 Daily Streak: Active
                  </span>
                  <span className="opacity-70 text-[11px]">
                    Day counted on completion ✓
                  </span>
                </div>
                {userStats && (
                  <div className="flex items-center justify-between text-[11px] font-bold opacity-80">
                    <span className="text-[#7B5CFF]">
                      Level {Math.floor(userStats.totalXP / 1500) + 1} ({userStats.totalXP % 1500}/1,500 XP)
                    </span>
                    <span>
                      {1500 - (userStats.totalXP % 1500)} XP to Next Level
                    </span>
                  </div>
                )}
              </div>
            </div>

            {/* Quick Learning Tip */}
            <div
              className={`p-4 rounded-[22px] border space-y-1 shadow-xs ${
                darkMode
                  ? 'bg-[#221E52] border-white/10'
                  : 'bg-white border-[#1F1B4D]/10'
              }`}
            >
              <span className="type-caption text-[#FF6B2C] block">
                {reviewData.spanishTipTitle}
              </span>
              <p className="text-[13px] leading-snug opacity-85 font-medium">
                {reviewData.spanishTipBody}
              </p>
            </div>

            {/* Practiced Words */}
            <div className="space-y-2">
              <span className="type-caption opacity-55 block">Words Practiced</span>
              <div
                className={`p-3 rounded-[22px] border divide-y divide-current/10 shadow-xs ${
                  darkMode
                    ? 'bg-[#221E52] border-white/10'
                    : 'bg-white border-[#1F1B4D]/10'
                }`}
              >
                {reviewData.wordsPracticed.slice(0, 3).map((w) => (
                  <div
                    key={w.id}
                    className="py-2.5 flex items-center justify-between gap-2 first:pt-1 last:pb-1"
                  >
                    <div className="flex items-baseline gap-2 min-w-0">
                      <span className="text-[14px] font-extrabold text-[#FF6B2C]">
                        {w.spanish}
                      </span>
                      <span className="text-[12px] opacity-65 truncate font-medium">
                        {w.english}
                      </span>
                    </div>
                    <AudioButton text={w.spanish} size="sm" />
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Chunky 3D Actions */}
          <div className="space-y-2.5">
            {isDailyGame && (
              <HiFiButton
                fullWidth
                size="lg"
                variant="secondary"
                onClick={() => onNavigate(reviewData.sourceId)}
                icon={<Eye className="w-4 h-4" />}
              >
                View Solved Puzzle
              </HiFiButton>
            )}

            <div className="grid grid-cols-2 gap-2">
              <HiFiButton
                fullWidth
                size="lg"
                variant="outline"
                onClick={handleShareReview}
                icon={
                  sharedSuccess ? (
                    <Check className="w-4 h-4 stroke-[3]" />
                  ) : (
                    <Share2 className="w-4 h-4" />
                  )
                }
              >
                {sharedSuccess ? 'Shared!' : 'Share'}
              </HiFiButton>

              <HiFiButton
                fullWidth
                size="lg"
                variant="primary"
                onClick={() => onNavigate('daily')}
                icon={<ArrowRight className="w-4 h-4" />}
              >
                Done
              </HiFiButton>
            </div>
          </div>
        </div>

        <GameAssistModal
          isOpen={assistModal !== null}
          mode={assistModal}
          title={reviewData.title}
          howToPlaySteps={[
            'Review your accuracy and time.',
            'Tap "View Solved Puzzle" to inspect your solved board.',
          ]}
          hintText={reviewData.spanishTipBody}
          onClose={() => setAssistModal(null)}
        />
      </div>
    );
  }

  // ----------------------------------------------------------------------------
  // 1. CONNECTIONS (CONEXIONES · Purple #7B5CFF)
  // ----------------------------------------------------------------------------
  if (activeView === 'game-connections') {
    const solvedGroups = CONNECTIONS_GROUPS.filter((g) =>
      connSolvedIds.includes(g.id)
    );
    const unsolvedWords = CONNECTIONS_GROUPS.filter(
      (g) => !connSolvedIds.includes(g.id)
    ).flatMap((g) => g.words);
    const isConnComplete = connSolvedIds.length === CONNECTIONS_GROUPS.length;

    const toggleConnWord = (word: string) => {
      setConnFeedback(null);
      setConnPoppingWord(word);
      setTimeout(() => setConnPoppingWord(null), 250);

      if (connSelected.includes(word)) {
        setConnSelected(connSelected.filter((w) => w !== word));
      } else if (connSelected.length < 4) {
        setConnSelected([...connSelected, word]);
      }
    };

    const goToConnectionsReview = () => {
      const score = connMistakes === 0 ? 100 : Math.max(70, 100 - connMistakes * 10);
      onFinishSession({
        sourceId: 'game-connections',
        title: 'Conexiones',
        subtitle: '4/4 Groups Solved',
        scoreLabel: `${score} pts`,
        accuracy: connMistakes === 0 ? '100%' : `${100 - connMistakes * 5}%`,
        timeSpent: '1m 45s',
        streakEarned: true,
        spanishTipTitle: 'Sin embargo vs Aunque',
        spanishTipBody:
          'Use "aunque" (although) inside a clause, and "sin embargo" (however) to link two sentences.',
        wordsPracticed: DAILY_SPANISH_VOCAB.slice(0, 4),
        xpEarned: 40,
        pointsScore: score,
      });
    };

    const handleConnSubmit = () => {
      if (connSelected.length !== 4) return;
      const matchedGroup = CONNECTIONS_GROUPS.find((g) =>
        g.words.every((w) => connSelected.includes(w))
      );

      if (matchedGroup) {
        const nextSolved = [...connSolvedIds, matchedGroup.id];
        setConnSolvedIds(nextSolved);
        setConnSelected([]);
        if (nextSolved.length === CONNECTIONS_GROUPS.length) {
          triggerCelebrationOnce('game-connections', '¡Conexiones Resueltas! 🎉');
        } else {
          setConnFeedback(`Solved: ${matchedGroup.title}`);
          setTimeout(() => setConnFeedback(null), 1500);
        }
      } else {
        setConnMistakes(connMistakes + 1);
        setConnIsShaking(true);
        setTimeout(() => setConnIsShaking(false), 350);
        setConnFeedback('Not quite — try again');
        setTimeout(() => setConnFeedback(null), 1500);
        triggerEncouragement();
      }
    };

    const handleAutoSolveNextGroup = () => {
      const nextUnsolved = CONNECTIONS_GROUPS.find(
        (g) => !connSolvedIds.includes(g.id)
      );
      if (nextUnsolved) {
        const updated = [...connSolvedIds, nextUnsolved.id];
        setConnSolvedIds(updated);
        setConnSelected([]);
        if (updated.length === CONNECTIONS_GROUPS.length) {
          triggerCelebrationOnce('game-connections', '¡Conexiones Resueltas! 🎉');
        }
      }
    };

    return (
      <div className="flex flex-col flex-1 relative">
        {showConfetti && (
          <ConfettiBurst
            message={confettiMessage || '¡Conexiones Resueltas! 🎉'}
            onDone={() => setShowConfetti(false)}
          />
        )}
        {encouragementMsg && (
          <MascotEncouragementToast
            message={encouragementMsg}
            onClose={() => setEncouragementMsg(null)}
          />
        )}

        <GameHeaderBar
          title="Connections"
          onOpenHowToPlay={() => setAssistModal('how-to')}
          onOpenHint={() => setAssistModal('hint')}
          onBack={() => onNavigate('daily')}
        />

        <div className="px-4 py-5 space-y-4 flex-1 flex flex-col justify-between">
          <div className="space-y-3">
            {/* Header info with mistakes indicator */}
            <div className="flex items-center justify-between text-[12px] font-bold">
              <span className="opacity-70">
                {isConnComplete ? 'All 4 groups solved' : 'Find groups of 4 words'}
              </span>
              <div className="flex items-center gap-1.5">
                <span className="opacity-50">Mistakes:</span>
                {Array.from({ length: 4 }).map((_, i) => (
                  <span
                    key={i}
                    className={`w-2 h-2 rounded-full transition-colors ${
                      i < 4 - connMistakes ? 'bg-[#FF6B2C]' : 'bg-current/15'
                    }`}
                  />
                ))}
              </div>
            </div>

            {connFeedback && (
              <p className="text-[13px] font-extrabold text-[#FF6B2C] text-center animate-scale-bounce">
                {connFeedback}
              </p>
            )}

            {/* Solved Groups Cards */}
            <div className="space-y-2">
              {solvedGroups.map((group) => (
                <div
                  key={group.id}
                  className={`py-3 px-3.5 rounded-2xl text-center shadow-xs ${group.bgClass} ${group.textClass} animate-scale-bounce`}
                >
                  <span className="text-[14px] font-extrabold block">
                    {group.title}
                  </span>
                  <span className="text-[11px] opacity-90 tracking-wide font-bold">
                    {group.words.join(' · ')}
                  </span>
                </div>
              ))}
            </div>

            {/* 4x4 Tiles Grid */}
            {!isConnComplete && (
              <div
                className={`grid grid-cols-4 gap-2 ${
                  connIsShaking ? 'animate-tile-shake' : ''
                }`}
              >
                {unsolvedWords.map((word) => {
                  const isSelected = connSelected.includes(word);
                  const isPopping = connPoppingWord === word;
                  return (
                    <button
                      key={word}
                      type="button"
                      onClick={() => toggleConnWord(word)}
                      className={`h-16 px-1 rounded-2xl text-[11px] font-extrabold uppercase tracking-tight flex items-center justify-center text-center cursor-pointer select-none transition-all ${
                        isPopping ? 'animate-tile-pop' : ''
                      } ${
                        isSelected
                          ? 'btn-3d-purple'
                          : darkMode
                          ? 'bg-[#221E52] text-[#FFF8EC] border-2 border-white/10 border-b-4 border-b-white/20'
                          : 'bg-white text-[#1F1B4D] border-2 border-[#1F1B4D]/15 border-b-4 border-b-[#1F1B4D]/25'
                      }`}
                    >
                      {word}
                    </button>
                  );
                })}
              </div>
            )}
          </div>

          {/* Controls */}
          {isConnComplete ? (
            <HiFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={goToConnectionsReview}
              icon={<ArrowRight className="w-4 h-4" />}
            >
              Continue to Review
            </HiFiButton>
          ) : (
            <div className="space-y-2">
              <div className="grid grid-cols-2 gap-2">
                <HiFiButton
                  fullWidth
                  size="lg"
                  variant="outline"
                  onClick={() => setConnSelected([])}
                  disabled={connSelected.length === 0}
                >
                  Deselect All
                </HiFiButton>

                <HiFiButton
                  fullWidth
                  size="lg"
                  variant="purple"
                  onClick={handleConnSubmit}
                  disabled={connSelected.length !== 4}
                >
                  Submit
                </HiFiButton>
              </div>
            </div>
          )}
        </div>

        <GameAssistModal
          isOpen={assistModal !== null}
          mode={assistModal}
          title="Connections"
          howToPlaySteps={[
            'Select 4 words that share a Spanish category.',
            'Submit to check. Watch out for tricky overlaps.',
          ]}
          hintText="Connectors group: ADEMÁS, AUNQUE, MIENTRAS, INCLUSO."
          hintActionLabel="Auto-Solve Group"
          onApplyHint={handleAutoSolveNextGroup}
          onClose={() => setAssistModal(null)}
        />
      </div>
    );
  }

  // ----------------------------------------------------------------------------
  // 2. WORD GUESS (PALABRA DEL DÍA · Sunny Yellow #FFC93C)
  // ----------------------------------------------------------------------------
  if (activeView === 'game-word-guess') {
    const isWgWon = wgGuesses.includes(TARGET_WORD);
    const isWgComplete = isWgWon || wgGuesses.length >= 5;

    const goToWordGuessReview = () => {
      const score = Math.max(75, 105 - wgGuesses.length * 5);
      onFinishSession({
        sourceId: 'game-word-guess',
        title: 'Palabra del Día',
        subtitle: 'CHARLA Solved',
        scoreLabel: `${score} pts`,
        accuracy: `${Math.round((1 - (wgGuesses.length - 1) / 10) * 100)}%`,
        timeSpent: '1m 24s',
        streakEarned: true,
        spanishTipTitle: 'La Charla',
        spanishTipBody:
          '"Charla" means a friendly chat over coffee; "charlar" is the verb to chat.',
        wordsPracticed: [DAILY_SPANISH_VOCAB[2], DAILY_SPANISH_VOCAB[0]],
        xpEarned: 40,
        pointsScore: score,
      });
    };

    const handleKeyClick = (key: string) => {
      if (isWgComplete) return;
      if (key === 'DEL') {
        setWgCurrent(wgCurrent.slice(0, -1));
      } else if (key === 'ENTER') {
        if (wgCurrent.length === 6) {
          const next = [...wgGuesses, wgCurrent];
          setWgGuesses(next);
          setWgCurrent('');
          if (wgCurrent === TARGET_WORD) {
            triggerCelebrationOnce('game-word-guess', '¡Palabra Encontrada! CHARLA 🎉');
          } else {
            setWgIsShaking(true);
            setTimeout(() => setWgIsShaking(false), 350);
            triggerEncouragement();
          }
        }
      } else if (wgCurrent.length < 6) {
        setWgCurrent(wgCurrent + key);
      }
    };

    const getTileStyle = (letter: string, idx: number, isSubmitted: boolean) => {
      if (!isSubmitted) {
        return darkMode
          ? 'bg-[#221E52] border-2 border-white/15 text-[#FFF8EC]'
          : 'bg-white border-2 border-[#1F1B4D]/15 text-[#1F1B4D]';
      }
      if (TARGET_WORD[idx] === letter) {
        return 'bg-[#3DDC84] border-2 border-[#25B867] text-[#1F1B4D] font-extrabold';
      }
      if (TARGET_WORD.includes(letter)) {
        return 'bg-[#FFC93C] border-2 border-[#D49C14] text-[#1F1B4D] font-extrabold';
      }
      return darkMode
        ? 'bg-white/10 border-2 border-white/5 text-white/40'
        : 'bg-black/10 border-2 border-black/5 text-[#1F1B4D]/40';
    };

    return (
      <div className="flex flex-col flex-1 relative">
        {showConfetti && (
          <ConfettiBurst
            message={confettiMessage || '¡Palabra Encontrada! CHARLA 🎉'}
            onDone={() => setShowConfetti(false)}
          />
        )}
        {encouragementMsg && (
          <MascotEncouragementToast
            message={encouragementMsg}
            onClose={() => setEncouragementMsg(null)}
          />
        )}

        <GameHeaderBar
          title="Word Guess"
          onOpenHowToPlay={() => setAssistModal('how-to')}
          onOpenHint={() => setAssistModal('hint')}
          onBack={() => onNavigate('daily')}
        />

        <div className="px-4 py-5 space-y-4 flex-1 flex flex-col justify-between">
          {/* Minimal 1-line clue */}
          <div className="flex items-center justify-between text-[12px] px-1 font-bold">
            <span className="opacity-70">
              {isWgComplete
                ? 'Solved: CHARLA (friendly chat)'
                : 'Clue: Friendly chat over coffee'}
            </span>
            <AudioButton text="charla" size="sm" />
          </div>

          {/* Clean 5x6 Grid */}
          <div
            className={`space-y-1.5 my-auto ${
              wgIsShaking ? 'animate-tile-shake' : ''
            }`}
          >
            {Array.from({ length: 5 }).map((_, rowIdx) => {
              const isSubmitted = rowIdx < wgGuesses.length;
              const isCurrent = rowIdx === wgGuesses.length && !isWgComplete;
              const wordStr = isSubmitted
                ? wgGuesses[rowIdx]
                : isCurrent
                ? wgCurrent.padEnd(6, ' ')
                : '      ';

              return (
                <div
                  key={rowIdx}
                  className="grid grid-cols-6 gap-1.5 max-w-[270px] mx-auto"
                >
                  {wordStr.split('').map((ch, colIdx) => (
                    <div
                      key={colIdx}
                      className={`h-11 rounded-xl flex items-center justify-center text-[17px] font-extrabold uppercase transition-all ${getTileStyle(
                        ch,
                        colIdx,
                        isSubmitted
                      )}`}
                    >
                      {ch.trim()}
                    </div>
                  ))}
                </div>
              );
            })}
          </div>

          {/* Complete Controls or Keyboard */}
          {isWgComplete ? (
            <div className="space-y-2">
              <HiFiButton
                fullWidth
                size="lg"
                variant="primary"
                onClick={goToWordGuessReview}
                icon={<ArrowRight className="w-4 h-4" />}
              >
                Continue to Review
              </HiFiButton>
              <HiFiButton
                fullWidth
                size="sm"
                variant="outline"
                onClick={() => {
                  setWgGuesses(['CAMINO', 'CORTAR']);
                  setWgCurrent('');
                }}
                icon={<RotateCcw className="w-3.5 h-3.5" />}
              >
                Try Again
              </HiFiButton>
            </div>
          ) : (
            <div className="space-y-1.5">
              {[
                ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
                ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ñ'],
                ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'],
              ].map((row, rIdx) => (
                <div key={rIdx} className="flex justify-center gap-1">
                  {row.map((k) => (
                    <button
                      key={k}
                      type="button"
                      onClick={() => handleKeyClick(k)}
                      className={`h-10 rounded-xl text-[12px] font-extrabold flex items-center justify-center cursor-pointer select-none transition-all active:translate-y-0.5 ${
                        k === 'ENTER' || k === 'DEL'
                          ? 'px-2.5 btn-3d-yellow font-extrabold'
                          : darkMode
                          ? 'flex-1 bg-[#221E52] text-[#FFF8EC] border-b-2 border-white/20'
                          : 'flex-1 bg-white text-[#1F1B4D] border border-black/10 border-b-2 border-b-black/20'
                      }`}
                    >
                      {k === 'DEL' ? <Delete className="w-4 h-4" /> : k}
                    </button>
                  ))}
                </div>
              ))}

              <div className="pt-1">
                <button
                  type="button"
                  onClick={() => {
                    setWgGuesses([...wgGuesses, TARGET_WORD]);
                    setWgCurrent('');
                    triggerCelebrationOnce('game-word-guess', '¡Palabra Resuelta! CHARLA 🎉');
                  }}
                  className="w-full text-center text-[12px] font-bold text-[#FF6B2C] py-2 cursor-pointer opacity-75 hover:opacity-100"
                >
                  Solve “CHARLA”
                </button>
              </div>
            </div>
          )}
        </div>

        <GameAssistModal
          isOpen={assistModal !== null}
          mode={assistModal}
          title="Palabra del Día"
          howToPlaySteps={[
            'Guess the 6-letter Spanish word in 5 tries.',
            'Green = correct letter & spot. Yellow = in the word but wrong spot.',
          ]}
          hintText='Starts with "CH" — from the verb "charlar" (CHARLA).'
          hintActionLabel='Solve "CHARLA"'
          onApplyHint={() => {
            if (!wgGuesses.includes(TARGET_WORD)) {
              setWgGuesses([...wgGuesses, TARGET_WORD]);
              setWgCurrent('');
              triggerCelebrationOnce('game-word-guess', '¡Palabra Resuelta! CHARLA 🎉');
            }
          }}
          onClose={() => setAssistModal(null)}
        />
      </div>
    );
  }

  // ----------------------------------------------------------------------------
  // 3. MINI CROSSWORD (CRUCIGRAMA · Aqua #19C3B1)
  // ----------------------------------------------------------------------------
  if (activeView === 'game-crossword') {
    const handleCwKey = (char: string) => {
      const next = cwGrid.map((row, r) =>
        row.map((val, c) => (r === cwCell.r && c === cwCell.c ? char : val))
      );
      setCwGrid(next);

      // Check if all filled letters match the solution
      const isSolved = next.every((row, r) =>
        row.every(
          (val, c) =>
            CROSSWORD_SOLUTION[r][c] === '#' || val === CROSSWORD_SOLUTION[r][c]
        )
      );
      if (isSolved) {
        setCwCompleted(true);
        triggerCelebrationOnce('game-crossword', '¡Crucigrama Resuelto! 🎉');
      }

      // Advance cell
      if (cwCell.c < 4) {
        setCwCell({ r: cwCell.r, c: cwCell.c + 1 });
      } else if (cwCell.r < 4) {
        setCwCell({ r: cwCell.r + 1, c: 0 });
      }
    };

    const goToCrosswordReview = () => {
      onFinishSession({
        sourceId: 'game-crossword',
        title: 'Crucigrama Mini',
        subtitle: '5x5 Completed',
        scoreLabel: '100 pts',
        accuracy: '98%',
        timeSpent: '1m 15s',
        streakEarned: true,
        spanishTipTitle: 'Café & Amigo',
        spanishTipBody:
          '"Café solo" is black coffee; "amigo" is a masculine friend, "amiga" feminine.',
        wordsPracticed: [DAILY_SPANISH_VOCAB[0], DAILY_SPANISH_VOCAB[1]],
        xpEarned: 40,
        pointsScore: 100,
      });
    };

    return (
      <div className="flex flex-col flex-1 relative">
        {showConfetti && (
          <ConfettiBurst
            message={confettiMessage || '¡Crucigrama Resuelto! 🎉'}
            onDone={() => setShowConfetti(false)}
          />
        )}

        <GameHeaderBar
          title="Mini Crossword"
          onOpenHowToPlay={() => setAssistModal('how-to')}
          onOpenHint={() => setAssistModal('hint')}
          onBack={() => onNavigate('daily')}
        />

        <div className="px-4 py-5 space-y-4 flex-1 flex flex-col justify-between">
          {/* Clues */}
          <div className="text-[12px] font-bold opacity-75">
            <p>1 Across: Popular hot beverage in Spain (CAFE)</p>
            <p className="mt-0.5">5 Across: Close companion (AMIGO)</p>
          </div>

          {/* 5x5 Grid */}
          <div className="my-auto flex justify-center">
            <div className="grid grid-cols-5 gap-1.5 p-3 rounded-[24px] bg-[#120F32] shadow-md">
              {cwGrid.map((row, r) =>
                row.map((cell, c) => {
                  const isBlocked = cell === '#';
                  const isSelected =
                    !cwCompleted && cwCell.r === r && cwCell.c === c;
                  if (isBlocked) {
                    return (
                      <div
                        key={`${r}-${c}`}
                        className="w-12 h-12 rounded-xl bg-[#120F32]"
                      />
                    );
                  }
                  return (
                    <button
                      key={`${r}-${c}`}
                      type="button"
                      onClick={() => setCwCell({ r, c })}
                      className={`w-12 h-12 rounded-xl text-[18px] font-extrabold flex items-center justify-center transition-all cursor-pointer ${
                        cwCompleted
                          ? 'bg-[#19C3B1] text-[#1F1B4D] animate-tile-pop'
                          : isSelected
                          ? 'bg-[#FF6B2C] text-white shadow-xs'
                          : 'bg-white text-[#1F1B4D]'
                      }`}
                    >
                      {cell}
                    </button>
                  );
                })
              )}
            </div>
          </div>

          {/* Controls */}
          {cwCompleted ? (
            <div className="space-y-2">
              <HiFiButton
                fullWidth
                size="lg"
                variant="primary"
                onClick={goToCrosswordReview}
                icon={<ArrowRight className="w-4 h-4" />}
              >
                Continue to Review
              </HiFiButton>
              <HiFiButton
                fullWidth
                size="sm"
                variant="outline"
                onClick={() => setCwCompleted(false)}
                icon={<RotateCcw className="w-3.5 h-3.5" />}
              >
                Edit Grid
              </HiFiButton>
            </div>
          ) : (
            <div className="space-y-2.5">
              <div className="flex justify-center gap-1">
                {[
                  'C',
                  'A',
                  'F',
                  'E',
                  'O',
                  'R',
                  'T',
                  'S',
                  'L',
                  'M',
                  'I',
                  'G',
                ].map((letter) => (
                  <button
                    key={letter}
                    type="button"
                    onClick={() => handleCwKey(letter)}
                    className={`flex-1 h-10 rounded-xl text-[12px] font-extrabold cursor-pointer border border-current/15 ${
                      darkMode
                        ? 'bg-[#221E52] text-[#FFF8EC]'
                        : 'bg-white text-[#1F1B4D]'
                    }`}
                  >
                    {letter}
                  </button>
                ))}
              </div>

              <button
                type="button"
                onClick={() => {
                  setCwGrid(CROSSWORD_SOLUTION);
                  setCwCompleted(true);
                  triggerCelebrationOnce('game-crossword', '¡Crucigrama Resuelto! 🎉');
                }}
                className="w-full btn-3d-aqua py-3 rounded-2xl text-[14px] font-extrabold cursor-pointer min-h-[46px]"
              >
                Check & Solve
              </button>
            </div>
          )}
        </div>

        <GameAssistModal
          isOpen={assistModal !== null}
          mode={assistModal}
          title="Mini Crossword"
          howToPlaySteps={[
            'Tap any square in the 5×5 grid.',
            'Fill in the Across and Down Spanish words.',
          ]}
          hintText='1 Across: "CAFE" · 5 Across: "AMIGO" · 1 Down: "CORTA".'
          hintActionLabel="Solve Full Grid"
          onApplyHint={() => {
            setCwGrid(CROSSWORD_SOLUTION);
            setCwCompleted(true);
            triggerCelebrationOnce('game-crossword', '¡Crucigrama Resuelto! 🎉');
          }}
          onClose={() => setAssistModal(null)}
        />
      </div>
    );
  }

  // ----------------------------------------------------------------------------
  // 4. EXERCISE 1: FILL IN THE BLANK
  // ----------------------------------------------------------------------------
  if (activeView === 'exercise-fill-blank') {
    const questions = [
      {
        promptBefore: 'El café estaba muy caliente;',
        promptAfter: ', sabía delicioso.',
        translation: 'The coffee was very hot; however, it tasted delicious.',
        options: ['sin embargo', 'además', 'mientras'],
      },
      {
        promptBefore: 'Nos encanta disfrutar de',
        promptAfter: 'después de almorzar.',
        translation: 'We love enjoying table talk after lunch.',
        options: ['la sobremesa', 'la cuenta', 'el reclamo'],
      },
    ];

    const q = questions[fitbIndex % questions.length];

    const handleSelectOption = (idx: number) => {
      setFitbChoice(idx);
      if (idx !== 0) {
        setFitbShaking(true);
        setTimeout(() => setFitbShaking(false), 350);
        triggerEncouragement();
      } else if (fitbIndex === 1) {
        triggerCelebrationOnce('exercise-fill-blank', '¡Drill Completado! 🎉');
      }
    };

    return (
      <div className="flex flex-col flex-1 relative">
        {showConfetti && (
          <ConfettiBurst
            message={confettiMessage || '¡Correcto! 🎉'}
            onDone={() => setShowConfetti(false)}
          />
        )}
        {encouragementMsg && (
          <MascotEncouragementToast
            message={encouragementMsg}
            onClose={() => setEncouragementMsg(null)}
          />
        )}
        <GameHeaderBar
          title={`Fill in the Blank · ${difficulty}`}
          onOpenHowToPlay={() => setAssistModal('how-to')}
          onOpenHint={() => setAssistModal('hint')}
          onBack={() => onNavigate('daily')}
        />

        <div className="px-4 py-6 space-y-6 flex-1 flex flex-col justify-between">
          <div className="space-y-6">
            <div className="space-y-2 py-2">
              <div className="flex items-center justify-between">
                <span className="type-caption text-[#FF6B2C]">
                  {fitbIndex + 1} / 2
                </span>
                <AudioButton
                  text={`${q.promptBefore} ${q.options[0]} ${q.promptAfter}`}
                  size="sm"
                />
              </div>

              <p className="type-h1 leading-snug">
                “{q.promptBefore}{' '}
                <span className="underline decoration-[#FF6B2C] text-[#FF6B2C]">
                  {fitbChoice !== null ? q.options[fitbChoice] : '______'}
                </span>{' '}
                {q.promptAfter}”
              </p>

              <p className="text-[13px] opacity-60 font-medium">{q.translation}</p>
            </div>

            <div
              className={`space-y-2.5 ${fitbShaking ? 'animate-tile-shake' : ''}`}
            >
              {q.options.map((opt, idx) => {
                const selected = fitbChoice === idx;
                return (
                  <button
                    key={opt}
                    type="button"
                    onClick={() => handleSelectOption(idx)}
                    className={`w-full p-4 rounded-2xl border text-left flex items-center justify-between cursor-pointer min-h-[46px] select-none transition-all ${
                      selected
                        ? 'btn-3d-secondary'
                        : darkMode
                        ? 'bg-[#221E52] text-[#FFF8EC] border-white/10'
                        : 'bg-white text-[#1F1B4D] border-[#1F1B4D]/15'
                    }`}
                  >
                    <span className="text-[15px] font-bold">{opt}</span>
                    {selected && <Check className="w-4 h-4 text-[#3DDC84]" />}
                  </button>
                );
              })}
            </div>
          </div>

          <HiFiButton
            fullWidth
            size="lg"
            variant="primary"
            onClick={() => {
              if (fitbIndex === 0) {
                setFitbIndex(1);
                setFitbChoice(null);
              } else {
                onFinishSession({
                  sourceId: 'exercise-fill-blank',
                  title: 'Fill in the Blank',
                  subtitle: difficulty,
                  scoreLabel: '100 pts',
                  accuracy: '100%',
                  timeSpent: '1m 20s',
                  streakEarned: true,
                  spanishTipTitle: 'Sin embargo',
                  spanishTipBody:
                    '"Sin embargo" (however) links contrasting ideas between clauses.',
                  wordsPracticed: [DAILY_SPANISH_VOCAB[3], DAILY_SPANISH_VOCAB[0]],
                  xpEarned: 25,
                  pointsScore: 100,
                });
              }
            }}
          >
            {fitbIndex === 0 ? 'Next Question' : 'Finish Drill'}
          </HiFiButton>
        </div>

        <GameAssistModal
          isOpen={assistModal !== null}
          mode={assistModal}
          title="Fill in the Blank"
          howToPlaySteps={['Tap the Spanish word that fits the sentence.']}
          hintText={`Correct answer: "${q.options[0]}".`}
          hintActionLabel="Select Answer"
          onApplyHint={() => setFitbChoice(0)}
          onClose={() => setAssistModal(null)}
        />
      </div>
    );
  }

  // ----------------------------------------------------------------------------
  // 5. EXERCISE 2: SENTENCE BUILDER
  // ----------------------------------------------------------------------------
  if (activeView === 'exercise-sentence-builder') {
    const remainingWords = builderTarget.filter(
      (w) => !builderPicked.includes(w)
    );

    return (
      <div className="flex flex-col flex-1 relative">
        {showConfetti && (
          <ConfettiBurst
            message={confettiMessage || '¡Oración Perfecta! 🎉'}
            onDone={() => setShowConfetti(false)}
          />
        )}

        <GameHeaderBar
          title={`Sentence Builder · ${difficulty}`}
          onOpenHowToPlay={() => setAssistModal('how-to')}
          onOpenHint={() => setAssistModal('hint')}
          onBack={() => onNavigate('daily')}
        />

        <div className="px-4 py-6 space-y-6 flex-1 flex flex-col justify-between">
          <div className="space-y-6">
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <span className="type-caption text-[#FF6B2C]">Translate</span>
                <AudioButton
                  text="Nos encanta charlar en la sobremesa"
                  size="sm"
                />
              </div>
              <p className="type-h1 leading-snug">
                “We love chatting during table talk.”
              </p>
            </div>

            {/* Drop Area */}
            <div
              className={`min-h-[100px] p-4 rounded-[22px] border-2 border-dashed flex flex-wrap gap-2 items-center ${
                darkMode ? 'border-white/20' : 'border-[#1F1B4D]/25'
              }`}
            >
              {builderPicked.length === 0 ? (
                <span className="text-[13px] opacity-40 font-bold">
                  Tap words below in order...
                </span>
              ) : (
                builderPicked.map((token) => (
                  <button
                    key={token}
                    type="button"
                    onClick={() =>
                      setBuilderPicked(builderPicked.filter((t) => t !== token))
                    }
                    className="btn-3d-primary px-3.5 py-1.5 rounded-xl text-[14px] font-extrabold cursor-pointer animate-tile-pop"
                  >
                    {token}
                  </button>
                ))
              )}
            </div>

            {/* Word Bank */}
            <div className="flex flex-wrap gap-2">
              {remainingWords.map((token) => (
                <button
                  key={token}
                  type="button"
                  onClick={() => {
                    const next = [...builderPicked, token];
                    setBuilderPicked(next);
                    if (next.length === builderTarget.length) {
                      triggerCelebrationOnce('exercise-sentence-builder', '¡Oración Perfecta! 🎉');
                    }
                  }}
                  className={`px-3.5 py-2 rounded-xl border text-[14px] font-extrabold cursor-pointer transition-all active:translate-y-0.5 ${
                    darkMode
                      ? 'bg-[#221E52] text-[#FFF8EC] border-white/15'
                      : 'bg-white text-[#1F1B4D] border-[#1F1B4D]/15 shadow-xs'
                  }`}
                >
                  {token}
                </button>
              ))}
            </div>
          </div>

          <HiFiButton
            fullWidth
            size="lg"
            variant="primary"
            onClick={() => {
              triggerCelebrationOnce('exercise-sentence-builder', '¡Oración Perfecta! 🎉');
              onFinishSession({
                sourceId: 'exercise-sentence-builder',
                title: 'Sentence Builder',
                subtitle: difficulty,
                scoreLabel: '100 pts',
                accuracy: '95%',
                timeSpent: '1m 50s',
                streakEarned: true,
                spanishTipTitle: 'Nos encanta + Infinitive',
                spanishTipBody:
                  '"Nos encanta" is followed directly by an infinitive verb ("charlar").',
                wordsPracticed: [DAILY_SPANISH_VOCAB[2], DAILY_SPANISH_VOCAB[0]],
                xpEarned: 25,
                pointsScore: 100,
              });
            }}
          >
            Check Sentence
          </HiFiButton>
        </div>

        <GameAssistModal
          isOpen={assistModal !== null}
          mode={assistModal}
          title="Sentence Builder"
          howToPlaySteps={['Tap Spanish words in order to build the sentence.']}
          hintText="Nos encanta charlar en la sobremesa."
          hintActionLabel="Auto-Complete"
          onApplyHint={() => {
            setBuilderPicked(builderTarget);
            triggerCelebrationOnce('exercise-sentence-builder', '¡Oración Completada! 🎉');
          }}
          onClose={() => setAssistModal(null)}
        />
      </div>
    );
  }

  // ----------------------------------------------------------------------------
  // 6. EXERCISE 3: DEFINITION MATCH
  // ----------------------------------------------------------------------------
  const handlePairCheck = (es: string | null, en: string | null) => {
    if (!es || !en) return;
    const found = initialMatchPairs.find((p) => p.es === es && p.en === en);
    if (found && !matchedEs.includes(es)) {
      const next = [...matchedEs, es];
      setMatchedEs(next);
      setPickedEs(null);
      setPickedEn(null);
      if (next.length === initialMatchPairs.length) {
        triggerCelebrationOnce('exercise-definition-match', '¡Todas las Parejas Emparejadas! 🎉');
      }
    } else {
      setMatchShaking(true);
      setTimeout(() => setMatchShaking(false), 350);
      setPickedEs(null);
      setPickedEn(null);
      triggerEncouragement();
    }
  };

  return (
    <div className="flex flex-col flex-1 relative">
      {showConfetti && (
        <ConfettiBurst
          message={confettiMessage || '¡Parejas Emparejadas! 🎉'}
          onDone={() => setShowConfetti(false)}
        />
      )}
      {encouragementMsg && (
        <MascotEncouragementToast
          message={encouragementMsg}
          onClose={() => setEncouragementMsg(null)}
        />
      )}

      <GameHeaderBar
        title={`Definition Match · ${difficulty}`}
        onOpenHowToPlay={() => setAssistModal('how-to')}
        onOpenHint={() => setAssistModal('hint')}
        onBack={() => onNavigate('daily')}
      />

      <div className="px-4 py-6 space-y-5 flex-1 flex flex-col justify-between">
        <div
          className={`grid grid-cols-2 gap-2.5 ${
            matchShaking ? 'animate-tile-shake' : ''
          }`}
        >
          {/* Spanish Column */}
          <div className="space-y-2">
            {initialMatchPairs.map((pair) => {
              const isMatched = matchedEs.includes(pair.es);
              const isSelected = pickedEs === pair.es;
              return (
                <button
                  key={pair.es}
                  type="button"
                  disabled={isMatched}
                  onClick={() => {
                    setPickedEs(pair.es);
                    handlePairCheck(pair.es, pickedEn);
                  }}
                  className={`w-full h-12 px-3 rounded-2xl border text-[13px] font-extrabold text-left flex items-center justify-between transition-all cursor-pointer min-h-[44px] ${
                    isMatched
                      ? 'opacity-25 border-current/10'
                      : isSelected
                      ? 'btn-3d-primary'
                      : darkMode
                      ? 'bg-[#221E52] text-[#FFF8EC] border-white/10'
                      : 'bg-white text-[#1F1B4D] border-[#1F1B4D]/15'
                  }`}
                >
                  <span className="truncate">{pair.es}</span>
                </button>
              );
            })}
          </div>

          {/* English Column */}
          <div className="space-y-2">
            {initialMatchPairs.map((pair) => {
              const isMatched = matchedEs.includes(pair.en);
              const isSelected = pickedEn === pair.en;
              return (
                <button
                  key={pair.en}
                  type="button"
                  disabled={isMatched}
                  onClick={() => {
                    setPickedEn(pair.en);
                    handlePairCheck(pickedEs, pair.en);
                  }}
                  className={`w-full h-12 px-3 rounded-2xl border text-[12px] font-bold text-left flex items-center justify-between transition-all cursor-pointer min-h-[44px] ${
                    isMatched
                      ? 'opacity-25 border-current/10'
                      : isSelected
                      ? 'btn-3d-secondary'
                      : darkMode
                      ? 'bg-[#221E52] text-[#FFF8EC] border-white/10'
                      : 'bg-white text-[#1F1B4D] border-[#1F1B4D]/15'
                  }`}
                >
                  <span className="truncate">{pair.en}</span>
                </button>
              );
            })}
          </div>
        </div>

        <HiFiButton
          fullWidth
          size="lg"
          variant="primary"
          onClick={() => {
            triggerCelebrationOnce('exercise-definition-match', '¡Parejas Emparejadas! 🎉');
            onFinishSession({
              sourceId: 'exercise-definition-match',
              title: 'Definition Match',
              subtitle: difficulty,
              scoreLabel: '100 pts',
              accuracy: '100%',
              timeSpent: '1m 08s',
              streakEarned: true,
              spanishTipTitle: 'Acogedor & Saborear',
              spanishTipBody:
                '"Acogedor" (cozy) and "saborear" (to savor) are now in your active review pool.',
              wordsPracticed: DAILY_SPANISH_VOCAB.slice(6, 10),
              xpEarned: 25,
              pointsScore: 100,
            });
          }}
        >
          Check Pairs
        </HiFiButton>
      </div>

      <GameAssistModal
        isOpen={assistModal !== null}
        mode={assistModal}
        title="Definition Match"
        howToPlaySteps={[
          'Tap a Spanish word on the left, then its English match on the right.',
        ]}
        hintText='"Acogedor" = cozy · "Saborear" = to savor.'
        hintActionLabel="Match Next Pair"
        onApplyHint={() => {
          const nextUnmatched = initialMatchPairs.find(
            (p) => !matchedEs.includes(p.es)
          );
          if (nextUnmatched) {
            const nextList = [...matchedEs, nextUnmatched.es];
            setMatchedEs(nextList);
            if (nextList.length === initialMatchPairs.length) {
              triggerCelebrationOnce('exercise-definition-match', '¡Todas las Parejas Emparejadas! 🎉');
            }
          }
        }}
        onClose={() => setAssistModal(null)}
      />
    </div>
  );
}
