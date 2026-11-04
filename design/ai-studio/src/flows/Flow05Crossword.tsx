import React, { useState } from 'react';
import {
  LoFiTopBar,
  LoFiButton,
  LoFiCard,
  FillerText,
} from '../components/common/LoFiElements';
import { HelpCircle, Eye, Check, ArrowRight, Delete } from 'lucide-react';

export function Flow05Crossword({
  activeScreen,
  onNavigate,
  onFinishSet,
  onFinishFlow,
}: {
  activeScreen: string;
  onNavigate: (screenId: string) => void;
  onFinishSet: () => void;
  onFinishFlow: () => void;
}) {
  const [grid, setGrid] = useState<string[][]>([
    ['C', 'A', 'S', 'A', '#'],
    ['A', '#', 'U', '#', 'M'],
    ['M', 'E', 'J', 'O', 'R'],
    ['I', '#', 'E', '#', 'A'],
    ['N', 'O', 'T', 'A', 'S'],
  ]);

  const [activeCell, setActiveCell] = useState<{ r: number; c: number }>({ r: 0, c: 0 });
  const [showHintModal, setShowHintModal] = useState(false);

  const clues = [
    { num: '1A', text: 'Lorem ipsum dolor sit amet', answer: 'CASA' },
    { num: '3A', text: 'Consectetur adipiscing elit', answer: 'MEJOR' },
    { num: '5A', text: 'Sed do eiusmod tempor incid', answer: 'NOTAS' },
    { num: '1D', text: 'Duis aute irure dolor in reprehenderit', answer: 'CAMIN' },
  ];

  const handleCellClick = (r: number, c: number) => {
    if (grid[r][c] === '#') return;
    setActiveCell({ r, c });
  };

  const handleLetterInput = (char: string) => {
    const { r, c } = activeCell;
    if (grid[r][c] === '#') return;

    const newGrid = grid.map((row, ri) =>
      row.map((cell, ci) => (ri === r && ci === c ? char : cell))
    );
    setGrid(newGrid);

    if (c + 1 < 5 && grid[r][c + 1] !== '#') {
      setActiveCell({ r, c: c + 1 });
    }
  };

  const handleDelete = () => {
    const { r, c } = activeCell;
    const newGrid = grid.map((row, ri) =>
      row.map((cell, ci) => (ri === r && ci === c ? '' : cell))
    );
    setGrid(newGrid);
  };

  const handleAutoSolve = () => {
    setGrid([
      ['C', 'A', 'S', 'A', '#'],
      ['A', '#', 'U', '#', 'M'],
      ['M', 'E', 'J', 'O', 'R'],
      ['I', '#', 'E', '#', 'A'],
      ['N', 'O', 'T', 'A', 'S'],
    ]);
    onNavigate('5D');
  };

  // 5A: Learning Intro
  if (activeScreen === '5A') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Daily Crossword Intro"
          subtitle="Word Preview"
          onBack={onFinishFlow}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="space-y-1">
              <span className="text-[10px] font-mono uppercase bg-neutral-200 text-neutral-700 px-2 py-0.5 rounded">
                Puzzle 03 · Final Daily Game
              </span>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="Words for the Crossword" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500">
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit."
                  tier="tertiary"
                />
              </p>
            </div>

            {/* Word Preview List */}
            <div className="p-4 rounded-xl border border-neutral-300 bg-white space-y-3 shadow-xs">
              <div className="border-b border-neutral-100 pb-2">
                <span className="text-sm font-mono font-bold text-neutral-900 block">LOREM</span>
                <span className="text-xs text-neutral-500 font-mono">Lorem ipsum dolor sit amet</span>
              </div>
              <div className="border-b border-neutral-100 pb-2">
                <span className="text-sm font-mono font-bold text-neutral-900 block">IPSUM</span>
                <span className="text-xs text-neutral-500 font-mono">Consectetur adipiscing elit</span>
              </div>
              <div>
                <span className="text-sm font-mono font-bold text-neutral-900 block">DOLOR</span>
                <span className="text-xs text-neutral-500 font-mono">Sed do eiusmod tempor incid</span>
              </div>
            </div>

            <div className="p-3 rounded-lg border border-neutral-200 bg-neutral-100/70 text-xs text-neutral-600">
              <span className="font-semibold block uppercase text-[10px] text-neutral-700">
                Controls Notice
              </span>
              <p>
                <FillerText
                  semantic="Tap a cell or clue, type letters on the keyboard, and use Hint or Reveal if stuck."
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
              onClick={() => onNavigate('5B')}
            >
              <FillerText semantic="Play Mini Crossword" tier="primary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 5B: Mini Crossword Gameplay
  if (activeScreen === '5B') {
    return (
      <div className="flex flex-col min-h-full bg-white relative">
        <LoFiTopBar
          title="Mini Crossword"
          subtitle="5x5 Daily Grid"
          onBack={() => onNavigate('5A')}
          rightAction={
            <button
              onClick={handleAutoSolve}
              className="text-xs font-mono text-neutral-600 underline hover:text-black cursor-pointer"
            >
              Solve
            </button>
          }
        />

        <div className="flex-1 px-3 py-3 flex flex-col justify-between max-w-md mx-auto w-full">
          {/* Active Clue Banner */}
          <div className="p-2.5 rounded-lg border border-neutral-300 bg-neutral-100 flex items-center justify-between text-xs">
            <div>
              <span className="font-mono font-bold text-neutral-900 mr-2">1 Across:</span>
              <span className="text-neutral-700">
                <FillerText semantic="Home or residential dwelling" tier="secondary" />
              </span>
            </div>
            <span className="font-mono text-[10px] bg-neutral-200 px-1.5 py-0.5 rounded text-neutral-700">
              4 letters
            </span>
          </div>

          {/* 5x5 Interactive Crossword Grid */}
          <div className="my-auto py-2 flex justify-center">
            <div className="grid grid-cols-5 gap-1.5 p-2 bg-neutral-200 rounded-xl border border-neutral-300 shadow-xs">
              {grid.map((row, r) =>
                row.map((cell, c) => {
                  const isBlock = cell === '#';
                  const isSelected = activeCell.r === r && activeCell.c === c;

                  if (isBlock) {
                    return (
                      <div
                        key={`${r}-${c}`}
                        className="w-11 h-11 bg-black rounded-md"
                      />
                    );
                  }

                  return (
                    <button
                      key={`${r}-${c}`}
                      onClick={() => handleCellClick(r, c)}
                      className={`w-11 h-11 rounded-md font-mono text-base font-bold flex items-center justify-center transition-all cursor-pointer border ${
                        isSelected
                          ? 'bg-neutral-100 border-black ring-2 ring-black text-black scale-105'
                          : 'bg-white border-neutral-300 text-neutral-900 hover:bg-neutral-50'
                      }`}
                    >
                      {cell}
                    </button>
                  );
                })
              )}
            </div>
          </div>

          {/* Grid Actions: Check, Reveal, Hint */}
          <div className="grid grid-cols-3 gap-2 py-1">
            <LoFiButton
              size="sm"
              variant="outline"
              onClick={() => onNavigate('5D')}
              icon={<Check className="w-3.5 h-3.5" />}
            >
              <FillerText semantic="Check" tier="primary" />
            </LoFiButton>
            <LoFiButton
              size="sm"
              variant="outline"
              onClick={() => onNavigate('5C')}
              icon={<Eye className="w-3.5 h-3.5" />}
            >
              <FillerText semantic="Reveal" tier="secondary" />
            </LoFiButton>
            <LoFiButton
              size="sm"
              variant="secondary"
              onClick={() => onNavigate('5C')}
              icon={<HelpCircle className="w-3.5 h-3.5" />}
            >
              <FillerText semantic="Hint" tier="secondary" />
            </LoFiButton>
          </div>

          {/* Mini Keyboard */}
          <div className="space-y-1 pt-1 bg-neutral-100 p-2 rounded-xl border border-neutral-200">
            {[
              ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
              ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
              ['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'],
            ].map((row, i) => (
              <div key={i} className="flex justify-center gap-1">
                {row.map((k) => (
                  <button
                    key={k}
                    onClick={() => (k === 'DEL' ? handleDelete() : handleLetterInput(k))}
                    className={`min-h-[38px] rounded-md font-mono font-bold text-xs flex items-center justify-center border border-neutral-300 bg-white text-neutral-900 hover:bg-neutral-200 cursor-pointer ${
                      k === 'DEL' ? 'px-2 bg-neutral-200' : 'flex-1 max-w-[32px]'
                    }`}
                  >
                    {k === 'DEL' ? <Delete className="w-3.5 h-3.5" /> : k}
                  </button>
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // 5C: Reveal & Hint Sheet (Dedicated Assisted View)
  if (activeScreen === '5C') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-100 relative">
        <LoFiTopBar
          title="Daily Crossword"
          subtitle="5C · Reveal & Hint Sheet"
          onBack={() => onNavigate('5B')}
        />

        <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full relative">
          {/* Dimmed Background: Crossword Grid Context */}
          <div className="p-3 opacity-30 pointer-events-none select-none">
            <div className="p-2.5 rounded-lg border border-neutral-300 bg-neutral-200 flex items-center justify-between text-xs mb-2">
              <span className="font-mono font-bold text-neutral-900">1 Across: Lorem ipsum dolor sit amet</span>
              <span className="font-mono text-[10px] bg-neutral-300 px-1.5 py-0.5 rounded text-neutral-800">4 letters</span>
            </div>
            <div className="flex justify-center py-1">
              <div className="grid grid-cols-5 gap-1 p-2 bg-neutral-300 rounded-xl border border-neutral-400">
                {grid.map((row, r) =>
                  row.map((cell, c) => (
                    <div
                      key={`${r}-${c}`}
                      className={`w-9 h-9 rounded font-mono text-xs font-bold flex items-center justify-center border ${
                        cell === '#'
                          ? 'bg-black border-black'
                          : 'bg-white border-neutral-400 text-neutral-900'
                      }`}
                    >
                      {cell === '#' ? '' : cell}
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>

          {/* Scrim Overlay */}
          <div className="absolute inset-0 bg-black/20 pointer-events-none" />

          {/* Bottom Sheet Card */}
          <div className="relative z-10 bg-white rounded-t-3xl border-t-2 border-x-2 border-neutral-300 p-5 shadow-2xl space-y-4 mt-auto">
            {/* Grab Handle */}
            <div className="w-12 h-1.5 bg-neutral-300 rounded-full mx-auto" />

            <div className="flex items-center justify-between border-b border-neutral-100 pb-2">
              <span className="text-[10px] font-mono uppercase bg-neutral-200 text-neutral-800 px-2 py-0.5 rounded font-bold">
                Clue Assistance
              </span>
              <span className="text-xs font-mono text-neutral-500">1 Across · 4 Letters</span>
            </div>

            <div>
              <h3 className="text-base font-bold text-neutral-900">
                <FillerText semantic="Reveal Answer or Hint for Clue?" tier="primary" />
              </h3>
              <p className="text-xs text-neutral-600 font-mono mt-1 leading-relaxed">
                Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod tempor incididunt.
              </p>
            </div>

            {/* Active Clue Info Box */}
            <div className="p-3 bg-neutral-50 rounded-xl border border-neutral-200 text-xs font-mono space-y-1.5">
              <div className="flex justify-between items-center text-neutral-500 text-[10px] font-semibold uppercase">
                <span>Active Target</span>
                <span>Latin Root</span>
              </div>
              <div className="text-neutral-900 font-bold">1 Across: Lorem ipsum dolor sit amet</div>
              <div className="text-neutral-700 bg-white p-1.5 rounded border border-neutral-200 text-center font-bold tracking-widest">
                [ C · A · S · A ]
              </div>
            </div>

            {/* Assistance Options */}
            <div className="space-y-2">
              <button
                onClick={() => {
                  // Fill first letter
                  const newGrid = grid.map((row, ri) =>
                    row.map((cell, ci) => (ri === 0 && ci === 0 ? 'C' : cell))
                  );
                  setGrid(newGrid);
                  onNavigate('5B');
                }}
                className="w-full p-3 rounded-xl border border-neutral-300 bg-neutral-50 hover:bg-neutral-100 text-left transition-colors cursor-pointer"
              >
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-bold text-neutral-900">Option 1: Reveal First Letter</h4>
                  <span className="text-[10px] font-mono bg-white border border-neutral-300 px-2 py-0.5 rounded font-bold text-black">
                    Letter 'C'
                  </span>
                </div>
                <p className="text-[11px] text-neutral-600 font-mono mt-0.5">
                  Lorem ipsum dolor sit amet helper.
                </p>
              </button>

              <button
                onClick={() => {
                  // Fill entire word CASA
                  const newGrid = grid.map((row, ri) =>
                    row.map((cell, ci) => {
                      if (ri === 0 && ci === 0) return 'C';
                      if (ri === 0 && ci === 1) return 'A';
                      if (ri === 0 && ci === 2) return 'S';
                      if (ri === 0 && ci === 3) return 'A';
                      return cell;
                    })
                  );
                  setGrid(newGrid);
                  onNavigate('5B');
                }}
                className="w-full p-3 rounded-xl border border-neutral-300 bg-neutral-50 hover:bg-neutral-100 text-left transition-colors cursor-pointer"
              >
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-bold text-neutral-900">Option 2: Solve Entire Word</h4>
                  <span className="text-[10px] font-mono bg-black text-white px-2 py-0.5 rounded font-bold">
                    [ CASA ]
                  </span>
                </div>
                <p className="text-[11px] text-neutral-600 font-mono mt-0.5">
                  Consectetur adipiscing elit sed do eiusmod.
                </p>
              </button>
            </div>

            <div className="pt-2 space-y-2">
              <LoFiButton
                fullWidth
                size="md"
                variant="primary"
                onClick={() => onNavigate('5B')}
              >
                <FillerText semantic="Return to Mini Crossword Board" tier="primary" />
              </LoFiButton>
              <LoFiButton
                fullWidth
                size="sm"
                variant="outline"
                onClick={() => onNavigate('5D')}
              >
                <FillerText semantic="Proceed to Completion Results" tier="primary" />
              </LoFiButton>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // 5D: Crossword Result / Completion
  if (activeScreen === '5D') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Crossword Complete"
          subtitle="Flow 05 · Screen 5D"
          onBack={() => onNavigate('5B')}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="p-4 rounded-xl border border-neutral-200 bg-white text-center space-y-1 shadow-2xs">
              <span className="text-[10px] font-mono uppercase bg-neutral-200 text-neutral-700 px-2 py-0.5 rounded">
                All Clues Solved
              </span>
              <h2 className="text-xl font-bold text-neutral-900 pt-1">
                <FillerText semantic="Crossword Complete" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500">
                <FillerText
                  semantic="You finished all across and down clues in today's language crossword."
                  tier="tertiary"
                />
              </p>

              <div className="flex justify-center gap-6 pt-3 text-xs border-t border-neutral-100 mt-2 font-mono">
                <div>
                  <span className="text-neutral-400 block text-[10px]">Solved</span>
                  <span className="font-bold text-neutral-900">7 / 8</span>
                </div>
                <div>
                  <span className="text-neutral-400 block text-[10px]">Time</span>
                  <span className="font-bold text-neutral-900">04:38</span>
                </div>
                <div>
                  <span className="text-neutral-400 block text-[10px]">Accuracy</span>
                  <span className="font-bold text-neutral-900">88%</span>
                </div>
              </div>
            </div>

            {/* Solved Clues Breakdown */}
            <div className="space-y-2">
              <h3 className="text-xs font-bold uppercase text-neutral-700 px-1 tracking-wider">
                <FillerText semantic="Solved Clues Recap" tier="secondary" />
              </h3>
              <div className="bg-white rounded-xl border border-neutral-200 divide-y divide-neutral-100 text-xs">
                {clues.map((c, i) => (
                  <div key={i} className="p-3 flex items-center justify-between">
                    <div>
                      <span className="font-mono font-bold text-neutral-900 block">
                        {c.num} · {c.answer}
                      </span>
                      <span className="text-neutral-500 text-[11px]">{c.text}</span>
                    </div>
                    <span className="text-[11px] font-mono text-neutral-600 bg-neutral-100 px-2 py-0.5 rounded">
                      Solv.
                    </span>
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
              onClick={onFinishSet}
              icon={<ArrowRight className="w-4 h-4" />}
            >
              <FillerText semantic="Finish Daily Set (Summary)" tier="primary" />
            </LoFiButton>
            <LoFiButton
              fullWidth
              size="md"
              variant="outline"
              onClick={onFinishFlow}
            >
              <FillerText semantic="Return to Home Dashboard" tier="secondary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
