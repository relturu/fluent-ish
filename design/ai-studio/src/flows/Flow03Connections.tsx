import React, { useState } from 'react';
import {
  LoFiTopBar,
  LoFiButton,
  LoFiCard,
  FillerText,
} from '../components/common/LoFiElements';
import { Volume2, ArrowRight, RotateCcw } from 'lucide-react';

interface CategoryGroup {
  id: string;
  title: string;
  description: string;
  words: string[];
  shade: string;
}

const PUZZLE_GROUPS: CategoryGroup[] = [
  {
    id: 'g1',
    title: 'Group 01 · Lorem Ipsum Dolor',
    description: 'Consectetur adipiscing elit sed do eiusmod',
    words: ['LOREM', 'IPSUM', 'DOLOR', 'AMET'],
    shade: 'bg-neutral-100 border-neutral-300 text-neutral-900',
  },
  {
    id: 'g2',
    title: 'Group 02 · Tempor Incididunt',
    description: 'Labore et dolore magna aliqua minim',
    words: ['CONSECT', 'ADIPIS', 'ELIT', 'TEMPOR'],
    shade: 'bg-neutral-200 border-neutral-400 text-neutral-900',
  },
  {
    id: 'g3',
    title: 'Group 03 · Quis Nostrud',
    description: 'Ullamco laboris nisi ut aliquip commodo',
    words: ['INCIDID', 'LABORE', 'MAGNA', 'ALIQUA'],
    shade: 'bg-neutral-300 border-neutral-500 text-neutral-950 font-bold',
  },
  {
    id: 'g4',
    title: 'Group 04 · Duis Aute Irure',
    description: 'Dolor in reprehenderit in voluptate velit',
    words: ['VENIAM', 'NOSTRUD', 'ULLAMCO', 'COMDO'],
    shade: 'bg-black border-neutral-900 text-white font-bold',
  },
];

export function Flow03Connections({
  activeScreen,
  onNavigate,
  onFinishFlow,
  onNextGame,
}: {
  activeScreen: string;
  onNavigate: (screenId: string) => void;
  onFinishFlow: () => void;
  onNextGame: () => void;
}) {
  const [selectedWords, setSelectedWords] = useState<string[]>([]);
  const [solvedGroups, setSolvedGroups] = useState<CategoryGroup[]>([]);
  const [mistakesRemaining, setMistakesRemaining] = useState(4);
  const [feedbackMsg, setFeedbackMsg] = useState<string | null>(null);
  const [audioPlaying, setAudioPlaying] = useState(false);

  // All 16 words shuffled
  const allWords = [
    'LOREM', 'CONSECT', 'INCIDID', 'VENIAM',
    'IPSUM', 'ADIPIS', 'LABORE', 'NOSTRUD',
    'DOLOR', 'ELIT', 'MAGNA', 'ULLAMCO',
    'AMET', 'TEMPOR', 'ALIQUA', 'COMDO',
  ];

  // Remaining unsolved words
  const solvedWordSet = new Set(solvedGroups.flatMap((g) => g.words));
  const unsolvedWords = allWords.filter((w) => !solvedWordSet.has(w));

  const handleTileClick = (word: string) => {
    if (selectedWords.includes(word)) {
      setSelectedWords(selectedWords.filter((w) => w !== word));
      setFeedbackMsg(null);
    } else {
      if (selectedWords.length < 4) {
        setSelectedWords([...selectedWords, word]);
        setFeedbackMsg(null);
      }
    }
  };

  const handleDeselectAll = () => {
    setSelectedWords([]);
    setFeedbackMsg(null);
  };

  const handleSubmit = () => {
    if (selectedWords.length !== 4) return;

    // Check if selectedWords matches any unsolved group
    const matchedGroup = PUZZLE_GROUPS.find((group) => {
      if (solvedGroups.some((sg) => sg.id === group.id)) return false;
      return group.words.every((w) => selectedWords.includes(w));
    });

    if (matchedGroup) {
      const newSolved = [...solvedGroups, matchedGroup];
      setSolvedGroups(newSolved);
      setSelectedWords([]);
      setFeedbackMsg('Group found!');
      if (newSolved.length === 4) {
        setTimeout(() => onNavigate('3D'), 400);
      }
    } else {
      // Mistake
      setMistakesRemaining((prev) => Math.max(0, prev - 1));
      setFeedbackMsg('Not quite. These words belong to different categories.');
      if (mistakesRemaining - 1 <= 0) {
        setTimeout(() => onNavigate('3C'), 300);
      }
    }
  };

  const handleAutoSolveAll = () => {
    setSolvedGroups(PUZZLE_GROUPS);
    setSelectedWords([]);
    onNavigate('3D');
  };

  // 3A: Vocabulary Flashcard Intro
  if (activeScreen === '3A') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Daily Set Intro"
          subtitle="Vocabulary Preview · 4 of 12"
          onBack={onFinishFlow}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="space-y-1">
              <span className="text-[10px] font-mono uppercase bg-neutral-200 text-neutral-700 px-2 py-0.5 rounded">
                Pre-Game Review
              </span>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="Today's Vocabulary Set" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500">
                <FillerText
                  semantic="Review these terms carefully. They will appear in today's 3 challenges."
                  tier="tertiary"
                />
              </p>
            </div>

            {/* Flashcard Component */}
            <div className="p-5 rounded-2xl border-2 border-neutral-300 bg-white space-y-4 shadow-xs">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="text-2xl font-bold font-mono text-neutral-900 tracking-tight">
                    LOREM
                  </h3>
                  <p className="text-xs text-neutral-500 italic mt-0.5 font-mono">
                    /ˈlɔː.rəm/ · lorem filler
                  </p>
                </div>
                <button
                  onClick={() => setAudioPlaying(!audioPlaying)}
                  aria-label="Hear pronunciation"
                  className={`w-10 h-10 rounded-full border border-neutral-300 flex items-center justify-center cursor-pointer transition-colors ${
                    audioPlaying ? 'bg-black text-white' : 'bg-neutral-100 text-neutral-700 hover:bg-neutral-200'
                  }`}
                >
                  <Volume2 className="w-5 h-5" />
                </button>
              </div>

              <div className="p-3 bg-neutral-100 rounded-lg border border-neutral-200 text-xs space-y-1">
                <span className="text-[10px] uppercase font-mono text-neutral-500 block font-semibold">
                  Meaning
                </span>
                <p className="text-neutral-900 font-medium">
                  <FillerText
                    semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit."
                    tier="secondary"
                  />
                </p>
              </div>

              <div className="text-xs space-y-1">
                <span className="text-[10px] uppercase font-mono text-neutral-500 block font-semibold">
                  Sample Sentence
                </span>
                <p className="text-neutral-700 italic">
                  &ldquo;Lorem ipsum dolor sit amet, consectetur adipiscing.&rdquo;
                </p>
                <p className="text-neutral-500 text-[11px]">
                  <FillerText
                    semantic="Lorem ipsum dolor sit amet, sed do eiusmod tempor."
                    tier="tertiary"
                  />
                </p>
              </div>
            </div>

            {/* How Connections works reminder note */}
            <div className="p-3 rounded-lg border border-neutral-200 bg-neutral-100/70 text-xs text-neutral-600 space-y-1">
              <span className="font-semibold block uppercase text-[10px] text-neutral-700">
                Puzzle Instructions
              </span>
              <p>
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod tempor incididunt."
                  tier="tertiary"
                />
              </p>
            </div>
          </div>

          <div className="pt-4 space-y-2">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('3B')}
            >
              <FillerText semantic="Start Connections Game" tier="primary" />
            </LoFiButton>
            <div className="flex justify-between text-xs text-neutral-500 px-1">
              <button
                onClick={() => onNavigate('3B')}
                className="underline hover:text-black cursor-pointer"
              >
                Skip preview
              </button>
              <span className="font-mono">1 / 4 cards</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // 3B: Interactive 4x4 Connections Grid
  if (activeScreen === '3B') {
    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar
          title="Daily Connections"
          subtitle="Find 4 Groups of 4"
          onBack={() => onNavigate('3A')}
          rightAction={
            <button
              onClick={handleAutoSolveAll}
              className="text-xs font-mono text-neutral-600 underline hover:text-black cursor-pointer"
            >
              Auto-Solve
            </button>
          }
        />

        <div className="flex-1 px-4 py-4 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-3">
            {/* Instruction Banner */}
            <div className="text-center space-y-1">
              <p className="text-xs text-neutral-600">
                <FillerText
                  semantic="Select four words that share a common connection."
                  tier="secondary"
                />
              </p>
              {feedbackMsg && (
                <div className="p-2 rounded-lg bg-neutral-100 border border-neutral-300 text-xs font-medium text-neutral-900 animate-fade-in">
                  {feedbackMsg}
                </div>
              )}
            </div>

            {/* Solved Category Banners Stacked at Top (Strictly Grayscale) */}
            <div className="space-y-1.5">
              {solvedGroups.map((g) => (
                <div
                  key={g.id}
                  className={`p-3 rounded-lg border text-center transition-all ${g.shade}`}
                >
                  <p className="text-xs font-bold uppercase tracking-wider font-mono">
                    <FillerText semantic={g.title} tier="primary" />
                  </p>
                  <p className="text-xs font-semibold tracking-wide mt-0.5">
                    {g.words.join(' · ')}
                  </p>
                </div>
              ))}
            </div>

            {/* 4x4 Grid for Remaining Unsolved Words */}
            {unsolvedWords.length > 0 && (
              <div className="grid grid-cols-4 gap-2 pt-1">
                {unsolvedWords.map((word) => {
                  const isSelected = selectedWords.includes(word);
                  return (
                    <button
                      key={word}
                      onClick={() => handleTileClick(word)}
                      className={`h-16 px-1 rounded-xl border text-center font-mono font-bold text-xs flex items-center justify-center transition-all cursor-pointer select-none ${
                        isSelected
                          ? 'border-black bg-black text-white scale-[0.98] shadow-xs'
                          : 'border-neutral-300 bg-neutral-50 text-neutral-900 hover:border-neutral-600 hover:bg-neutral-100 active:scale-95'
                      }`}
                    >
                      <span className="truncate max-w-full leading-tight">{word}</span>
                    </button>
                  );
                })}
              </div>
            )}

            {/* Mistakes indicator */}
            <div className="flex items-center justify-center gap-2 pt-2">
              <span className="text-xs text-neutral-500 font-mono">Mistakes remaining:</span>
              <div className="flex gap-1.5">
                {[0, 1, 2, 3].map((dot) => (
                  <div
                    key={dot}
                    className={`w-2.5 h-2.5 rounded-full border transition-colors ${
                      dot < mistakesRemaining
                        ? 'bg-black border-black'
                        : 'bg-neutral-200 border-neutral-300'
                    }`}
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Action Row */}
          <div className="pt-4 space-y-2">
            <div className="grid grid-cols-2 gap-2">
              <LoFiButton
                variant="outline"
                size="md"
                onClick={handleDeselectAll}
                disabled={selectedWords.length === 0}
              >
                <FillerText semantic="Deselect All" tier="primary" />
              </LoFiButton>
              <LoFiButton
                variant="primary"
                size="md"
                onClick={handleSubmit}
                disabled={selectedWords.length !== 4}
              >
                <FillerText semantic={`Submit (${selectedWords.length}/4)`} tier="primary" />
              </LoFiButton>
            </div>

            <p className="text-[11px] text-center text-neutral-400">
              <FillerText
                semantic="Tap words to select or deselect. Solve all 4 groups to advance."
                tier="tertiary"
              />
            </p>
          </div>
        </div>
      </div>
    );
  }

  // 3C: Partial Match / Error Screen
  if (activeScreen === '3C') {
    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar
          title="Connections · Attempt"
          subtitle="Mistake Alert State"
          onBack={() => onNavigate('3B')}
        />

        <div className="flex-1 px-4 py-6 flex flex-col justify-between max-w-md mx-auto w-full text-center space-y-6">
          <div className="space-y-4 my-auto">
            <div className="w-14 h-14 rounded-full border-2 border-black bg-neutral-100 flex items-center justify-center mx-auto text-xl font-bold font-mono text-black">
              !
            </div>
            <h2 className="text-xl font-bold text-neutral-900">
              <FillerText semantic="Not quite — keep trying" tier="primary" />
            </h2>
            <p className="text-xs text-neutral-500 max-w-xs mx-auto">
              <FillerText
                semantic="Those four words do not form a single category. Look for grammatical roles or thematic links."
                tier="tertiary"
              />
            </p>

            <div className="p-4 rounded-xl border border-neutral-300 bg-neutral-50 text-left space-y-2">
              <span className="text-[10px] font-mono uppercase text-neutral-500 block font-semibold">
                Hint & Category Clue
              </span>
              <p className="text-xs text-neutral-700">
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod."
                  tier="secondary"
                />
              </p>
            </div>
          </div>

          <div className="space-y-2">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('3B')}
            >
              <FillerText semantic="Return to Board" tier="primary" />
            </LoFiButton>
            <LoFiButton
              fullWidth
              size="md"
              variant="outline"
              onClick={handleAutoSolveAll}
            >
              <FillerText semantic="Reveal All Groups (Skip)" tier="primary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 3D: Puzzle Complete Screen
  if (activeScreen === '3D') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Connections Solved"
          subtitle="Flow 03 · Screen 3D"
          rightAction={
            <button
              onClick={() => onNavigate('3E')}
              className="text-xs font-mono text-neutral-700 underline hover:text-black cursor-pointer"
            >
              Results
            </button>
          }
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="text-center space-y-1">
              <span className="text-[10px] font-mono uppercase bg-neutral-200 text-neutral-700 px-2 py-0.5 rounded">
                Puzzle Complete
              </span>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="All 4 Groups Solved" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500">
                <FillerText
                  semantic="You found all 4 groups with clear mastery of the connections."
                  tier="tertiary"
                />
              </p>
            </div>

            {/* 4 Solved Grayscale Category Bands */}
            <div className="space-y-2">
              {PUZZLE_GROUPS.map((g) => (
                <div
                  key={g.id}
                  className={`p-3.5 rounded-xl border text-center ${g.shade} shadow-2xs`}
                >
                  <span className="text-[11px] font-bold uppercase tracking-wider block font-mono">
                    <FillerText semantic={g.title} tier="primary" />
                  </span>
                  <p className="text-xs mt-1 font-semibold tracking-wide">
                    {g.words.join('  ·  ')}
                  </p>
                </div>
              ))}
            </div>

            {/* Score Metrics */}
            <div className="grid grid-cols-3 gap-2 text-center text-xs">
              <div className="p-2.5 bg-white border border-neutral-200 rounded-lg">
                <span className="text-neutral-400 block text-[10px] uppercase font-semibold">Solved</span>
                <span className="text-base font-bold font-mono text-neutral-900">4 / 4</span>
              </div>
              <div className="p-2.5 bg-white border border-neutral-200 rounded-lg">
                <span className="text-neutral-400 block text-[10px] uppercase font-semibold">Mistakes</span>
                <span className="text-base font-bold font-mono text-neutral-900">
                  {4 - mistakesRemaining}
                </span>
              </div>
              <div className="p-2.5 bg-white border border-neutral-200 rounded-lg">
                <span className="text-neutral-400 block text-[10px] uppercase font-semibold">Time</span>
                <span className="text-base font-bold font-mono text-neutral-900">02:18</span>
              </div>
            </div>
          </div>

          <div className="pt-4 space-y-2">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('3E')}
            >
              <FillerText semantic="Review Vocabulary & Results" tier="primary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 3E: Results & Review Screen
  if (activeScreen === '3E') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Connections Results"
          subtitle="Flow 03 · Screen 3E"
          onBack={() => onNavigate('3D')}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            {/* Header summary */}
            <div className="p-4 rounded-xl border border-neutral-200 bg-white text-center space-y-1 shadow-2xs">
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="4 groups found" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500">
                <FillerText
                  semantic="Strong grouping and recall across today's focus vocabulary."
                  tier="tertiary"
                />
              </p>
              <div className="flex justify-center gap-6 pt-3 text-xs border-t border-neutral-100 mt-2 font-mono">
                <div>
                  <span className="text-neutral-400 block text-[10px]">Time</span>
                  <span className="font-bold text-neutral-900">02:18</span>
                </div>
                <div>
                  <span className="text-neutral-400 block text-[10px]">Accuracy</span>
                  <span className="font-bold text-neutral-900">94%</span>
                </div>
                <div>
                  <span className="text-neutral-400 block text-[10px]">Points</span>
                  <span className="font-bold text-neutral-900">+12</span>
                </div>
              </div>
            </div>

            {/* Reinforced Vocabulary List */}
            <div className="space-y-2">
              <h3 className="text-xs font-bold uppercase text-neutral-700 px-1 tracking-wider">
                <FillerText semantic="Reinforced Vocabulary" tier="secondary" />
              </h3>
              <div className="bg-white rounded-xl border border-neutral-200 divide-y divide-neutral-100">
                {[
                  { word: 'LOREM', def: 'Lorem ipsum dolor sit amet' },
                  { word: 'IPSUM', def: 'Consectetur adipiscing elit' },
                  { word: 'DOLOR', def: 'Sed do eiusmod tempor incid' },
                ].map((item, idx) => (
                  <div key={idx} className="p-3 flex items-center justify-between text-xs">
                    <div>
                      <span className="font-mono font-bold text-neutral-900 block">{item.word}</span>
                      <span className="text-neutral-500 text-[11px] font-mono">{item.def}</span>
                    </div>
                    <button className="px-2.5 py-1 text-[11px] rounded border border-neutral-300 hover:bg-neutral-100 font-medium text-neutral-800 cursor-pointer">
                      Add to Review
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="pt-4 space-y-2">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={onNextGame}
              icon={<ArrowRight className="w-4 h-4" />}
            >
              <FillerText semantic="Next Game: Word Guess" tier="primary" />
            </LoFiButton>
            <div className="grid grid-cols-2 gap-2">
              <LoFiButton
                size="md"
                variant="outline"
                onClick={onFinishFlow}
              >
                <FillerText semantic="Return to Home" tier="secondary" />
              </LoFiButton>
              <LoFiButton
                size="md"
                variant="secondary"
                onClick={() => onNavigate('3B')}
                icon={<RotateCcw className="w-3.5 h-3.5" />}
              >
                <FillerText semantic="Play Again" tier="secondary" />
              </LoFiButton>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
