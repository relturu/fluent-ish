import React, { useState } from 'react';
import {
  LoFiTopBar,
  LoFiButton,
  LoFiCard,
  LoFiTabBar,
  FillerText,
} from '../components/common/LoFiElements';
import { ArrowRight, Check } from 'lucide-react';

export function Flow06PracticeGames({
  activeScreen,
  onNavigate,
  onSwitchTab,
}: {
  activeScreen: string;
  onNavigate: (screenId: string) => void;
  onSwitchTab: (tab: 'home' | 'practice' | 'progress' | 'profile') => void;
}) {
  const [difficulty, setDifficulty] = useState<'easy' | 'medium' | 'hard'>('easy');

  // Fill in the Blank state
  const [fitbChoice, setFitbChoice] = useState<number | null>(null);
  const [fitbChecked, setFitbChecked] = useState(false);

  // Sentence Builder state
  const initialChips = ['lorem', 'ipsum', 'dolor', 'sit', 'amet', 'sed'];
  const [selectedTokens, setSelectedTokens] = useState<string[]>([]);
  const [builderChecked, setBuilderChecked] = useState(false);

  // Definition Match state
  const initialPairs = [
    { term: 'LOREM', def: 'Lorem ipsum dolor sit', matched: false },
    { term: 'IPSUM', def: 'Consectetur adipiscing elit', matched: false },
    { term: 'DOLOR', def: 'Sed do eiusmod tempor', matched: false },
    { term: 'AMET', def: 'Incididunt ut labore', matched: false },
  ];
  const [pairs, setPairs] = useState(initialPairs);
  const [selectedTerm, setSelectedTerm] = useState<string | null>(null);
  const [selectedDef, setSelectedDef] = useState<string | null>(null);

  const handleAddToken = (token: string) => {
    setSelectedTokens([...selectedTokens, token]);
    setBuilderChecked(false);
  };

  const handleRemoveToken = (index: number) => {
    const next = [...selectedTokens];
    next.splice(index, 1);
    setSelectedTokens(next);
    setBuilderChecked(false);
  };

  const handleMatchCheck = (term: string | null, def: string | null) => {
    if (!term || !def) return;
    const target = pairs.find((p) => p.term === term);
    if (target && target.def === def) {
      setPairs(pairs.map((p) => (p.term === term ? { ...p, matched: true } : p)));
    }
    setSelectedTerm(null);
    setSelectedDef(null);
  };

  // 6A: Practice Hub Screen
  if (activeScreen === '6A') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Practice Hub"
          subtitle="Flow 06 · Screen 6A"
        />

        <div className="flex-1 px-4 py-5 space-y-4 max-w-md mx-auto w-full">
          <div className="space-y-1">
            <h2 className="text-xl font-bold text-neutral-900">
              <FillerText semantic="Choose Your Practice Game" tier="primary" />
            </h2>
            <p className="text-xs text-neutral-600 font-mono">
              <FillerText
                semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod tempor."
                tier="primary"
              />
            </p>
          </div>

          {/* Difficulty Segmented Control */}
          <div className="flex bg-neutral-200 p-1 rounded-xl">
            {(['easy', 'medium', 'hard'] as const).map((diff) => (
              <button
                key={diff}
                onClick={() => setDifficulty(diff)}
                className={`flex-1 min-h-[38px] py-1.5 text-xs font-semibold rounded-lg capitalize transition-all cursor-pointer ${
                  difficulty === diff
                    ? 'bg-white text-black shadow-xs font-bold'
                    : 'text-neutral-600 hover:text-black'
                }`}
              >
                {diff}
              </button>
            ))}
          </div>

          {/* 3 Interactive Practice Modules */}
          <div className="space-y-3">
            {/* Game 1: Fill in the Blank */}
            <div className="p-4 rounded-xl border border-neutral-200 bg-white space-y-3 shadow-2xs">
              <div>
                <h3 className="text-sm font-bold text-neutral-900">
                  <FillerText semantic="Fill in the Blank" tier="primary" />
                </h3>
                <p className="text-xs text-neutral-600 font-mono mt-0.5">
                  <FillerText
                    semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit."
                    tier="primary"
                  />
                </p>
                <div className="flex gap-2 text-[10px] text-neutral-400 mt-1 font-mono">
                  <span>10 questions</span>
                  <span>·</span>
                  <span>~3 min</span>
                </div>
              </div>
              <LoFiButton
                fullWidth
                size="md"
                variant="primary"
                onClick={() => onNavigate('6B')}
              >
                <FillerText semantic="Start Fill in the Blank" tier="primary" />
              </LoFiButton>
            </div>

            {/* Game 2: Sentence Builder */}
            <div className="p-4 rounded-xl border border-neutral-200 bg-white space-y-3 shadow-2xs">
              <div>
                <h3 className="text-sm font-bold text-neutral-900">
                  <FillerText semantic="Sentence Builder" tier="primary" />
                </h3>
                <p className="text-xs text-neutral-600 font-mono mt-0.5">
                  <FillerText
                    semantic="Sed do eiusmod tempor incididunt ut labore et dolore magna."
                    tier="primary"
                  />
                </p>
                <div className="flex gap-2 text-[10px] text-neutral-400 mt-1 font-mono">
                  <span>8 questions</span>
                  <span>·</span>
                  <span>~4 min</span>
                </div>
              </div>
              <LoFiButton
                fullWidth
                size="md"
                variant="primary"
                onClick={() => onNavigate('6C')}
              >
                <FillerText semantic="Start Sentence Builder" tier="primary" />
              </LoFiButton>
            </div>

            {/* Game 3: Definition Match */}
            <div className="p-4 rounded-xl border border-neutral-200 bg-white space-y-3 shadow-2xs">
              <div>
                <h3 className="text-sm font-bold text-neutral-900">
                  <FillerText semantic="Definition Match" tier="primary" />
                </h3>
                <p className="text-xs text-neutral-600 font-mono mt-0.5">
                  <FillerText
                    semantic="Duis aute irure dolor in reprehenderit in voluptate velit esse."
                    tier="primary"
                  />
                </p>
                <div className="flex gap-2 text-[10px] text-neutral-400 mt-1 font-mono">
                  <span>15 pairs</span>
                  <span>·</span>
                  <span>Speed test</span>
                </div>
              </div>
              <LoFiButton
                fullWidth
                size="md"
                variant="primary"
                onClick={() => onNavigate('6D')}
              >
                <FillerText semantic="Start Definition Match" tier="primary" />
              </LoFiButton>
            </div>
          </div>
        </div>

        <LoFiTabBar activeTab="practice" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  // 6B: Fill in the Blank Screen
  if (activeScreen === '6B') {
    const options = [
      { id: 0, text: 'consectetur', sub: 'lorem ipsum' },
      { id: 1, text: 'adipiscing', sub: 'dolor sit amet' },
      { id: 2, text: 'eiusmod', sub: 'tempor incididunt' },
    ];

    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Fill in the Blank"
          subtitle="Easy · Question 4 of 10"
          progress={40}
          onBack={() => onNavigate('6A')}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="p-4 rounded-xl border border-neutral-300 bg-white space-y-2 shadow-xs">
              <span className="text-[10px] uppercase font-mono text-neutral-400 block font-semibold">
                Complete the sentence
              </span>
              <p className="text-lg font-bold text-neutral-900 leading-relaxed font-mono">
                Lorem ipsum{' '}
                <span className="inline-block border-b-2 border-black px-3 text-neutral-900">
                  {fitbChoice !== null ? options[fitbChoice].text : '_________'}
                </span>{' '}
                dolor sit amet.
              </p>
              <p className="text-xs text-neutral-500 italic">
                &ldquo;Lorem ipsum dolor sit amet consectetur.&rdquo;
              </p>
            </div>

            {/* Multiple Choice Options */}
            <div className="space-y-2">
              {options.map((opt) => {
                const isSelected = fitbChoice === opt.id;
                return (
                  <button
                    key={opt.id}
                    onClick={() => {
                      setFitbChoice(opt.id);
                      setFitbChecked(false);
                    }}
                    className={`w-full p-3.5 rounded-xl border text-left flex items-center justify-between transition-colors cursor-pointer ${
                      isSelected
                        ? 'border-black bg-neutral-100 ring-1 ring-black'
                        : 'border-neutral-200 bg-white hover:border-neutral-300'
                    }`}
                  >
                    <div>
                      <span className="font-mono font-bold text-sm text-neutral-900 block">
                        {opt.text}
                      </span>
                      <span className="text-xs text-neutral-500 font-mono">{opt.sub}</span>
                    </div>
                    <div
                      className={`w-5 h-5 rounded-full border flex items-center justify-center shrink-0 ${
                        isSelected ? 'border-black bg-black text-white' : 'border-neutral-300'
                      }`}
                    >
                      {isSelected && <Check className="w-3 h-3" />}
                    </div>
                  </button>
                );
              })}
            </div>

            {/* Explanation card after checking */}
            {fitbChecked && (
              <div className="p-3.5 rounded-xl border border-neutral-300 bg-neutral-100 space-y-1 text-xs text-neutral-800">
                <span className="font-bold block uppercase text-[10px]">
                  Grammar Explanation
                </span>
                <p>
                  <FillerText
                    semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod tempor incididunt."
                    tier="tertiary"
                  />
                </p>
              </div>
            )}
          </div>

          <div className="pt-4 space-y-2">
            {!fitbChecked ? (
              <LoFiButton
                fullWidth
                size="lg"
                variant="primary"
                disabled={fitbChoice === null}
                onClick={() => setFitbChecked(true)}
              >
                <FillerText semantic="Check Answer" tier="primary" />
              </LoFiButton>
            ) : (
              <LoFiButton
                fullWidth
                size="lg"
                variant="primary"
                onClick={() => onNavigate('6C')}
                icon={<ArrowRight className="w-4 h-4" />}
              >
                <FillerText semantic="Next: Sentence Builder" tier="primary" />
              </LoFiButton>
            )}
            <LoFiButton
              fullWidth
              size="md"
              variant="outline"
              onClick={() => onNavigate('6A')}
            >
              <FillerText semantic="Exit Game" tier="secondary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 6C: Sentence Builder Screen
  if (activeScreen === '6C') {
    const remainingTokens = initialChips.filter((c) => !selectedTokens.includes(c));

    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Sentence Builder"
          subtitle="Medium · 3 of 8"
          progress={38}
          onBack={() => onNavigate('6A')}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="space-y-1">
              <span className="text-[10px] uppercase font-mono text-neutral-400 block font-semibold">
                Construct Target Sentence
              </span>
              <p className="text-base font-bold text-neutral-900 font-mono">
                &ldquo;Lorem ipsum dolor sit amet.&rdquo;
              </p>
              <p className="text-xs text-neutral-500">
                Tap chips below to assemble tokens in correct syntax order.
              </p>
            </div>

            {/* Sentence Construction Drop Area */}
            <div className="min-h-[90px] p-3.5 rounded-xl border-2 border-dashed border-neutral-300 bg-white flex flex-wrap gap-2 items-center">
              {selectedTokens.length === 0 ? (
                <span className="text-xs text-neutral-400 italic">
                  Tap word chips below to place them here...
                </span>
              ) : (
                selectedTokens.map((tok, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleRemoveToken(idx)}
                    className="min-h-[38px] px-3 py-1.5 rounded-lg bg-black text-white font-mono text-xs font-semibold cursor-pointer hover:bg-neutral-800 active:scale-95"
                  >
                    {tok} ✕
                  </button>
                ))
              )}
            </div>

            {/* Word Chips Bank */}
            <div className="space-y-2">
              <span className="text-xs font-semibold text-neutral-700 block uppercase tracking-wider">
                Word Tokens Bank (1 distractor)
              </span>
              <div className="flex flex-wrap gap-2">
                {remainingTokens.map((tok) => (
                  <button
                    key={tok}
                    onClick={() => handleAddToken(tok)}
                    className="min-h-[42px] px-4 py-2 rounded-lg border border-neutral-300 bg-white text-neutral-900 font-mono text-xs font-bold hover:bg-neutral-100 hover:border-neutral-500 active:scale-95 cursor-pointer shadow-2xs"
                  >
                    {tok}
                  </button>
                ))}
              </div>
            </div>

            {builderChecked && (
              <div className="p-3.5 rounded-xl border border-neutral-300 bg-neutral-100 text-xs text-neutral-800">
                <span className="font-bold block uppercase text-[10px]">
                  Syntax Validation
                </span>
                <p className="font-mono">
                  &ldquo;Lorem ipsum dolor sit amet.&rdquo; Valid syntax!
                </p>
              </div>
            )}
          </div>

          <div className="pt-4 space-y-2">
            <div className="grid grid-cols-2 gap-2">
              <LoFiButton
                size="md"
                variant="outline"
                onClick={() => {
                  setSelectedTokens([]);
                  setBuilderChecked(false);
                }}
              >
                <FillerText semantic="Reset Tokens" tier="secondary" />
              </LoFiButton>
              <LoFiButton
                size="md"
                variant="primary"
                onClick={() => setBuilderChecked(true)}
                disabled={selectedTokens.length === 0}
              >
                <FillerText semantic="Check Syntax" tier="primary" />
              </LoFiButton>
            </div>
            <LoFiButton
              fullWidth
              size="md"
              variant="secondary"
              onClick={() => onNavigate('6D')}
            >
              <FillerText semantic="Next: Definition Match" tier="secondary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 6D: Definition Match Screen
  if (activeScreen === '6D') {
    const allMatched = pairs.every((p) => p.matched);

    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Definition Match"
          subtitle="Medium · 4 Pairs"
          onBack={() => onNavigate('6A')}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="space-y-1">
              <h2 className="text-base font-bold text-neutral-900">
                <FillerText semantic="Match Words and Definitions" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500">
                Tap a term on the left, then tap its matching meaning on the right.
              </p>
            </div>

            {/* Two-Column Pairing Grid */}
            <div className="grid grid-cols-2 gap-2 text-xs">
              {/* Left Column: Terms */}
              <div className="space-y-2">
                <span className="text-[10px] font-mono uppercase text-neutral-400 block font-semibold">
                  Spanish Terms
                </span>
                {pairs.map((p) => {
                  const isSelected = selectedTerm === p.term;
                  return (
                    <button
                      key={p.term}
                      disabled={p.matched}
                      onClick={() => {
                        setSelectedTerm(p.term);
                        handleMatchCheck(p.term, selectedDef);
                      }}
                      className={`w-full min-h-[52px] p-2.5 rounded-xl border text-left font-mono font-bold transition-all cursor-pointer ${
                        p.matched
                          ? 'border-neutral-200 bg-neutral-100 text-neutral-400 line-through opacity-60'
                          : isSelected
                          ? 'border-black bg-black text-white'
                          : 'border-neutral-300 bg-white text-neutral-900 hover:border-neutral-500'
                      }`}
                    >
                      {p.term}
                    </button>
                  );
                })}
              </div>

              {/* Right Column: Definitions */}
              <div className="space-y-2">
                <span className="text-[10px] font-mono uppercase text-neutral-400 block font-semibold">
                  Definitions
                </span>
                {pairs.map((p) => {
                  const isSelected = selectedDef === p.def;
                  return (
                    <button
                      key={p.def}
                      disabled={p.matched}
                      onClick={() => {
                        setSelectedDef(p.def);
                        handleMatchCheck(selectedTerm, p.def);
                      }}
                      className={`w-full min-h-[52px] p-2.5 rounded-xl border text-left transition-all cursor-pointer text-[11px] leading-tight ${
                        p.matched
                          ? 'border-neutral-200 bg-neutral-100 text-neutral-400 line-through opacity-60'
                          : isSelected
                          ? 'border-black bg-black text-white'
                          : 'border-neutral-300 bg-white text-neutral-900 hover:border-neutral-500'
                      }`}
                    >
                      {p.def}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Score & Counter */}
            <div className="p-3 bg-white rounded-xl border border-neutral-200 flex justify-between items-center text-xs font-mono">
              <span className="text-neutral-500">Pairs Matched:</span>
              <span className="font-bold text-neutral-900">
                {pairs.filter((p) => p.matched).length} / {pairs.length}
              </span>
            </div>
          </div>

          <div className="pt-4 space-y-2">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('6A')}
            >
              <FillerText
                semantic={allMatched ? 'All Pairs Complete · Return to Hub' : 'Finish Session'}
                tier="primary"
              />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
