import React, { useState } from 'react';
import {
  LoFiTopBar,
  LoFiButton,
  LoFiCard,
  FillerText,
} from '../components/common/LoFiElements';
import { Volume2, ArrowRight, RotateCcw, Delete } from 'lucide-react';

const TARGET_WORD = 'LOREMS'; // 6-letter word
const MAX_ATTEMPTS = 6;
const WORD_LENGTH = 6;

export function Flow04WordGuess({
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
  const [currentGuess, setCurrentGuess] = useState('');
  const [guesses, setGuesses] = useState<string[]>(['DOLORS', 'AMETIS']);
  const [gameStatus, setGameStatus] = useState<'playing' | 'won' | 'lost'>('playing');
  const [message, setMessage] = useState<string | null>(null);

  const keyboardRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ñ'],
    ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'],
  ];

  const handleKeyPress = (key: string) => {
    if (gameStatus !== 'playing') return;

    if (key === 'DEL') {
      setCurrentGuess((prev) => prev.slice(0, -1));
      setMessage(null);
    } else if (key === 'ENTER') {
      if (currentGuess.length !== WORD_LENGTH) {
        setMessage(`Word must be ${WORD_LENGTH} letters.`);
        return;
      }

      const newGuesses = [...guesses, currentGuess];
      setGuesses(newGuesses);

      if (currentGuess === TARGET_WORD) {
        setGameStatus('won');
        setTimeout(() => onNavigate('4C'), 500);
      } else if (newGuesses.length >= MAX_ATTEMPTS) {
        setGameStatus('lost');
        setTimeout(() => onNavigate('4D'), 500);
      } else {
        setCurrentGuess('');
      }
    } else {
      if (currentGuess.length < WORD_LENGTH) {
        setCurrentGuess((prev) => prev + key);
        setMessage(null);
      }
    }
  };

  const getLetterStatus = (letter: string, index: number, target: string) => {
    if (target[index] === letter) return 'exact'; // solid black
    if (target.includes(letter)) return 'present'; // mid neutral-500
    return 'absent'; // light neutral-200
  };

  const simulateWin = () => {
    setGuesses(['DOLORS', 'AMETIS', 'LOREMS']);
    setGameStatus('won');
    onNavigate('4C');
  };

  const simulateLoss = () => {
    setGuesses(['DOLORS', 'AMETIS', 'TEMPOR', 'CONSEC', 'MAGNAS', 'ALIQUA']);
    setGameStatus('lost');
    onNavigate('4D');
  };

  // 4A: Learning Intro
  if (activeScreen === '4A') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Daily Word Guess"
          subtitle="Learning Intro"
          onBack={onFinishFlow}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="space-y-1">
              <span className="text-[10px] font-mono uppercase bg-neutral-200 text-neutral-700 px-2 py-0.5 rounded">
                Focus Word
              </span>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="Remember this word" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500">
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit."
                  tier="tertiary"
                />
              </p>
            </div>

            {/* Word Card */}
            <div className="p-5 rounded-2xl border-2 border-neutral-300 bg-white space-y-4 shadow-xs">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="text-2xl font-bold font-mono text-neutral-900">
                    LOREMS
                  </h3>
                  <p className="text-xs text-neutral-500 italic mt-0.5 font-mono">
                    /ˈlɔː.rəmz/ · lorem filler
                  </p>
                </div>
                <button
                  aria-label="Audio"
                  className="w-10 h-10 rounded-full border border-neutral-300 bg-neutral-100 flex items-center justify-center text-neutral-700 hover:bg-neutral-200 cursor-pointer"
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
                  Contextual Sentence
                </span>
                <p className="text-neutral-700 italic">
                  &ldquo;Lorem ipsum dolor sit amet consectetur.&rdquo;
                </p>
                <p className="text-neutral-500 text-[11px]">
                  <FillerText
                    semantic="Lorem ipsum dolor sit amet, sed do eiusmod."
                    tier="tertiary"
                  />
                </p>
              </div>
            </div>

            {/* Rules */}
            <div className="p-3 rounded-lg border border-neutral-200 bg-neutral-100/70 text-xs text-neutral-600 space-y-1">
              <span className="font-semibold block uppercase text-[10px] text-neutral-700">
                How to Play
              </span>
              <p>
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore."
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
              onClick={() => onNavigate('4B')}
            >
              <FillerText semantic="Play Word Guess" tier="primary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 4B: Word Guess Gameplay
  if (activeScreen === '4B') {
    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar
          title="Daily Word Guess"
          subtitle="6-Letter Word · 6 Tries"
          onBack={() => onNavigate('4A')}
          rightAction={
            <div className="flex gap-2">
              <button
                onClick={simulateWin}
                className="text-[10px] font-mono text-neutral-600 underline hover:text-black cursor-pointer"
              >
                Win
              </button>
              <button
                onClick={simulateLoss}
                className="text-[10px] font-mono text-neutral-600 underline hover:text-black cursor-pointer"
              >
                Loss
              </button>
            </div>
          }
        />

        <div className="flex-1 px-3 py-3 flex flex-col justify-between max-w-md mx-auto w-full">
          {/* Game Board */}
          <div className="space-y-1.5 my-auto">
            {message && (
              <div className="text-center text-xs font-semibold text-neutral-900 bg-neutral-100 py-1 px-3 rounded border border-neutral-300 max-w-xs mx-auto animate-fade-in">
                {message}
              </div>
            )}

            {Array.from({ length: MAX_ATTEMPTS }).map((_, rowIndex) => {
              const guess = guesses[rowIndex];
              const isCurrentRow = rowIndex === guesses.length;

              return (
                <div key={rowIndex} className="flex justify-center gap-1.5">
                  {Array.from({ length: WORD_LENGTH }).map((__, colIndex) => {
                    let letter = '';
                    let statusClass = 'border-neutral-300 bg-white text-neutral-900';

                    if (guess) {
                      letter = guess[colIndex] || '';
                      const status = getLetterStatus(letter, colIndex, TARGET_WORD);
                      if (status === 'exact') {
                        statusClass = 'bg-black border-black text-white font-bold';
                      } else if (status === 'present') {
                        statusClass = 'bg-neutral-500 border-neutral-500 text-white font-bold';
                      } else {
                        statusClass = 'bg-neutral-200 border-neutral-200 text-neutral-500 font-bold';
                      }
                    } else if (isCurrentRow) {
                      letter = currentGuess[colIndex] || '';
                      statusClass = letter
                        ? 'border-black bg-neutral-50 text-black font-bold'
                        : 'border-neutral-300 bg-white';
                    }

                    return (
                      <div
                        key={colIndex}
                        className={`w-11 h-12 rounded-lg border-2 flex items-center justify-center font-mono text-base select-none transition-all ${statusClass}`}
                      >
                        {letter}
                      </div>
                    );
                  })}
                </div>
              );
            })}
          </div>

          {/* Grayscale Legend */}
          <div className="flex items-center justify-center gap-4 text-[10px] text-neutral-500 font-mono py-1">
            <span className="flex items-center gap-1">
              <span className="w-2.5 h-2.5 bg-black rounded-xs" /> Exact
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2.5 h-2.5 bg-neutral-500 rounded-xs" /> In word
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2.5 h-2.5 bg-neutral-200 rounded-xs" /> Absent
            </span>
          </div>

          {/* Virtual On-Screen Keyboard */}
          <div className="space-y-1.5 pt-2 pb-1 bg-neutral-100 p-2 rounded-2xl border border-neutral-200">
            {keyboardRows.map((row, rowIdx) => (
              <div key={rowIdx} className="flex justify-center gap-1">
                {row.map((key) => {
                  const isSpecial = key === 'ENTER' || key === 'DEL';
                  return (
                    <button
                      key={key}
                      onClick={() => handleKeyPress(key)}
                      className={`min-h-[42px] rounded-lg font-mono font-bold text-xs flex items-center justify-center transition-all cursor-pointer select-none border border-neutral-300 bg-white text-neutral-900 hover:bg-neutral-200 active:scale-95 ${
                        isSpecial ? 'px-2.5 text-[11px] font-semibold bg-neutral-200' : 'flex-1 max-w-[34px]'
                      }`}
                    >
                      {key === 'DEL' ? <Delete className="w-4 h-4" /> : key}
                    </button>
                  );
                })}
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // 4C: Win / Well Guessed Screen
  if (activeScreen === '4C') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Word Guess Result"
          subtitle="Solved in 3 Tries"
          onBack={() => onNavigate('4B')}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="p-4 rounded-xl border border-neutral-200 bg-white text-center space-y-1 shadow-2xs">
              <span className="text-[10px] font-mono uppercase bg-neutral-200 text-neutral-700 px-2 py-0.5 rounded">
                Solved Successfully
              </span>
              <h2 className="text-xl font-bold text-neutral-900 pt-1">
                <FillerText semantic="Well Guessed!" tier="primary" />
              </h2>
              <div className="text-2xl font-mono font-bold tracking-widest text-neutral-900 py-2">
                LOREMS
              </div>
              <p className="text-xs text-neutral-500">
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit."
                  tier="tertiary"
                />
              </p>

              <div className="flex justify-center gap-6 pt-3 text-xs border-t border-neutral-100 mt-2 font-mono">
                <div>
                  <span className="text-neutral-400 block text-[10px]">Tries</span>
                  <span className="font-bold text-neutral-900">3 / 6</span>
                </div>
                <div>
                  <span className="text-neutral-400 block text-[10px]">Time</span>
                  <span className="font-bold text-neutral-900">01:46</span>
                </div>
                <div>
                  <span className="text-neutral-400 block text-[10px]">Accuracy</span>
                  <span className="font-bold text-neutral-900">92%</span>
                </div>
              </div>
            </div>

            {/* Attempt Review Box */}
            <div className="p-3.5 rounded-xl border border-neutral-200 bg-white space-y-2">
              <span className="text-xs font-bold uppercase text-neutral-700 block tracking-wider">
                Attempt History
              </span>
              <div className="space-y-1 font-mono text-xs text-neutral-800">
                <div className="flex justify-between p-1.5 bg-neutral-50 rounded">
                  <span>1. DOLORS</span>
                  <span className="text-neutral-400">2 in word</span>
                </div>
                <div className="flex justify-between p-1.5 bg-neutral-50 rounded">
                  <span>2. AMETIS</span>
                  <span className="text-neutral-400">3 in word</span>
                </div>
                <div className="flex justify-between p-1.5 bg-neutral-100 font-bold rounded">
                  <span>3. LOREMS</span>
                  <span className="text-neutral-900">Solved!</span>
                </div>
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
              <FillerText semantic="Next Game: Mini Crossword" tier="primary" />
            </LoFiButton>
            <div className="grid grid-cols-2 gap-2">
              <LoFiButton size="md" variant="outline" onClick={onFinishFlow}>
                <FillerText semantic="Return Home" tier="secondary" />
              </LoFiButton>
              <LoFiButton size="md" variant="secondary" onClick={() => onNavigate('4B')}>
                <FillerText semantic="Play Again" tier="secondary" />
              </LoFiButton>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // 4D: Loss / Review State
  if (activeScreen === '4D') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Word Guess Review"
          subtitle="Attempts Exhausted"
          onBack={() => onNavigate('4B')}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="p-4 rounded-xl border border-neutral-300 bg-white text-center space-y-2 shadow-2xs">
              <h2 className="text-lg font-bold text-neutral-900">
                <FillerText semantic="The word was:" tier="primary" />
              </h2>
              <div className="text-3xl font-mono font-bold tracking-widest text-neutral-900">
                LOREMS
              </div>
              <p className="text-xs text-neutral-500">
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod."
                  tier="tertiary"
                />
              </p>
              <LoFiButton
                size="sm"
                variant="outline"
                icon={<Volume2 className="w-4 h-4" />}
              >
                <FillerText semantic="Hear Pronunciation" tier="secondary" />
              </LoFiButton>
            </div>

            <div className="p-3.5 rounded-xl border border-neutral-200 bg-white text-xs space-y-1.5">
              <span className="font-mono uppercase font-bold text-neutral-500 text-[10px] block">
                Grammar Context
              </span>
              <p className="text-neutral-700">
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
              onClick={onNextGame}
              icon={<ArrowRight className="w-4 h-4" />}
            >
              <FillerText semantic="Continue to Mini Crossword" tier="primary" />
            </LoFiButton>
            <LoFiButton
              fullWidth
              size="md"
              variant="outline"
              onClick={() => onNavigate('4B')}
              icon={<RotateCcw className="w-3.5 h-3.5" />}
            >
              <FillerText semantic="Retry Word Guess" tier="secondary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
