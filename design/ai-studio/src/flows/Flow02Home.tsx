import React from 'react';
import {
  LoFiTopBar,
  LoFiButton,
  LoFiCard,
  LoFiTabBar,
  FillerText,
} from '../components/common/LoFiElements';
import { Play, CheckCircle2, Lock, ArrowRight } from 'lucide-react';

export function Flow02Home({
  activeScreen,
  onNavigate,
  onLaunchGame,
  onSwitchTab,
}: {
  activeScreen: string;
  onNavigate: (screenId: string) => void;
  onLaunchGame: (gameId: 'connections' | 'word-guess' | 'crossword') => void;
  onSwitchTab: (tab: 'home' | 'practice' | 'progress' | 'profile') => void;
}) {
  // 2A: Home Default Screen
  if (activeScreen === '2A') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Home Dashboard"
          subtitle="Flow 02 · Screen 2A"
          rightAction={
            <button
              onClick={() => onSwitchTab('profile')}
              aria-label="Profile"
              className="w-8 h-8 rounded-full border border-neutral-300 bg-neutral-200 flex items-center justify-center font-mono text-xs font-semibold text-neutral-800 cursor-pointer"
            >
              U
            </button>
          }
        />

        <div className="flex-1 px-4 py-5 space-y-4 max-w-md mx-auto w-full">
          {/* Greeting Card with Progress Circle */}
          <LoFiCard className="bg-white border-neutral-200 shadow-2xs">
            <div className="flex items-start justify-between">
              <div className="space-y-1">
                <p className="text-xs font-mono uppercase text-neutral-400">
                  <FillerText semantic="Oct 02 · Session 01" tier="secondary" />
                </p>
                <h2 className="text-lg font-bold text-neutral-900">
                  <FillerText semantic="Good morning, Learner" tier="primary" />
                </h2>
                <p className="text-xs text-neutral-500">
                  <FillerText
                    semantic="Your first daily set is ready. Learn the words, then play all three games."
                    tier="tertiary"
                  />
                </p>
              </div>
              <div className="w-13 h-13 rounded-full border-4 border-neutral-200 border-t-black flex items-center justify-center shrink-0">
                <span className="text-xs font-mono font-bold text-neutral-900">0/3</span>
              </div>
            </div>
          </LoFiCard>

          {/* Featured Hero: Start Daily Review */}
          <div className="rounded-xl border border-black bg-black text-white p-4 space-y-3 shadow-xs">
            <div className="space-y-1">
              <span className="text-[10px] font-mono uppercase bg-neutral-800 text-neutral-300 px-2 py-0.5 rounded">
                <FillerText semantic="Start Here" tier="secondary" />
              </span>
              <h3 className="text-base font-bold">
                <FillerText semantic="Learn Today's 10 Words" tier="primary" />
              </h3>
              <p className="text-xs text-neutral-300">
                <FillerText
                  semantic="Review pronunciation, meaning, and one useful example before starting games."
                  tier="tertiary"
                />
              </p>
            </div>
            <LoFiButton
              fullWidth
              size="md"
              variant="secondary"
              onClick={() => onLaunchGame('connections')}
              icon={<Play className="w-4 h-4 fill-black" />}
            >
              <FillerText semantic="Start Daily Review" tier="primary" />
            </LoFiButton>
          </div>

          {/* Today's Games Queue */}
          <div className="space-y-2">
            <div className="flex items-center justify-between text-xs px-1">
              <span className="font-semibold text-neutral-700 uppercase tracking-wider text-[11px]">
                <FillerText semantic="Today's Games" tier="secondary" />
              </span>
              <button
                onClick={() => onNavigate('2B')}
                className="text-neutral-500 hover:text-black underline text-[11px] cursor-pointer"
              >
                (View Completed State)
              </button>
            </div>

            {/* Game 1: Connections */}
            <div
              onClick={() => onLaunchGame('connections')}
              className="p-3.5 rounded-xl border border-neutral-200 bg-white hover:border-neutral-400 cursor-pointer flex items-center justify-between transition-colors shadow-2xs"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-neutral-100 border border-neutral-200 flex items-center justify-center font-mono text-sm font-bold text-neutral-900">
                  01
                </div>
                <div>
                  <h4 className="text-sm font-semibold text-neutral-900">
                    <FillerText semantic="Daily Connections" tier="primary" />
                  </h4>
                  <p className="text-xs text-neutral-500">
                    <FillerText semantic="Lorem ipsum dolor sit amet consectetur" tier="tertiary" />
                  </p>
                </div>
              </div>
              <span className="text-xs font-mono font-medium text-black bg-neutral-100 px-2.5 py-1 rounded-md">
                Ready
              </span>
            </div>

            {/* Game 2: Word Guess */}
            <div
              onClick={() => onLaunchGame('word-guess')}
              className="p-3.5 rounded-xl border border-neutral-200 bg-white hover:border-neutral-400 cursor-pointer flex items-center justify-between transition-colors shadow-2xs"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-neutral-100 border border-neutral-200 flex items-center justify-center font-mono text-sm font-bold text-neutral-900">
                  02
                </div>
                <div>
                  <h4 className="text-sm font-semibold text-neutral-900">
                    <FillerText semantic="Word Guess" tier="primary" />
                  </h4>
                  <p className="text-xs text-neutral-500">
                    <FillerText semantic="Sed do eiusmod tempor incididunt ut labore" tier="tertiary" />
                  </p>
                </div>
              </div>
              <span className="text-xs font-mono text-neutral-500 flex items-center gap-1">
                <Lock className="w-3.5 h-3.5" />
                Locked
              </span>
            </div>

            {/* Game 3: Mini Crossword */}
            <div
              onClick={() => onLaunchGame('crossword')}
              className="p-3.5 rounded-xl border border-neutral-200 bg-white hover:border-neutral-400 cursor-pointer flex items-center justify-between transition-colors shadow-2xs"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-neutral-100 border border-neutral-200 flex items-center justify-center font-mono text-sm font-bold text-neutral-900">
                  03
                </div>
                <div>
                  <h4 className="text-sm font-semibold text-neutral-900">
                    <FillerText semantic="Mini Crossword" tier="primary" />
                  </h4>
                  <p className="text-xs text-neutral-500">
                    <FillerText semantic="Duis aute irure dolor in reprehenderit" tier="tertiary" />
                  </p>
                </div>
              </div>
              <span className="text-xs font-mono text-neutral-500 flex items-center gap-1">
                <Lock className="w-3.5 h-3.5" />
                Locked
              </span>
            </div>
          </div>
        </div>

        <LoFiTabBar activeTab="home" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  // 2B: Daily Set Complete Screen
  if (activeScreen === '2B') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Daily Set Complete"
          subtitle="Flow 02 · Screen 2B"
          rightAction={
            <button
              onClick={() => onNavigate('2A')}
              className="text-xs font-mono text-neutral-600 hover:text-black cursor-pointer"
            >
              Reset
            </button>
          }
        />

        <div className="flex-1 px-4 py-5 space-y-4 max-w-md mx-auto w-full">
          {/* Completion Celebration Card */}
          <LoFiCard className="bg-white border-neutral-200 text-center space-y-2 py-5 shadow-2xs">
            <div className="w-12 h-12 rounded-full bg-black text-white flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <h2 className="text-lg font-bold text-neutral-900">
              <FillerText semantic="Daily Set Complete!" tier="primary" />
            </h2>
            <p className="text-xs text-neutral-500 max-w-xs mx-auto">
              <FillerText
                semantic="Great job! You finished today's review and all three daily challenges."
                tier="tertiary"
              />
            </p>
          </LoFiCard>

          {/* 3 Key Stats Box */}
          <div className="grid grid-cols-3 gap-2">
            <div className="p-3 bg-white rounded-xl border border-neutral-200 text-center">
              <span className="text-[10px] font-mono uppercase text-neutral-400 block font-semibold">Words</span>
              <span className="text-xl font-bold font-mono text-neutral-900">7</span>
              <span className="text-[10px] text-neutral-500 block">Mastered</span>
            </div>
            <div className="p-3 bg-white rounded-xl border border-neutral-200 text-center">
              <span className="text-[10px] font-mono uppercase text-neutral-400 block font-semibold">Accuracy</span>
              <span className="text-xl font-bold font-mono text-neutral-900">91%</span>
              <span className="text-[10px] text-neutral-500 block">Precision</span>
            </div>
            <div className="p-3 bg-white rounded-xl border border-neutral-200 text-center">
              <span className="text-[10px] font-mono uppercase text-neutral-400 block font-semibold">Time</span>
              <span className="text-xl font-bold font-mono text-neutral-900">8:42</span>
              <span className="text-[10px] text-neutral-500 block">Total</span>
            </div>
          </div>

          {/* Breakdown of 3 Games */}
          <div className="space-y-2">
            <h3 className="text-xs font-semibold uppercase text-neutral-600 px-1 tracking-wider">
              <FillerText semantic="Session Breakdown" tier="secondary" />
            </h3>
            <div className="bg-white rounded-xl border border-neutral-200 divide-y divide-neutral-100">
              <div className="p-3 flex items-center justify-between text-xs">
                <div>
                  <span className="font-semibold text-neutral-900 block">
                    <FillerText semantic="01 · Connections" tier="primary" />
                  </span>
                  <span className="text-neutral-500 text-[11px]">
                    <FillerText semantic="Lorem ipsum dolor sit amet" tier="secondary" />
                  </span>
                </div>
                <div className="text-right font-mono">
                  <span className="font-semibold text-neutral-900 block">02:18</span>
                  <span className="text-neutral-500 text-[11px]">94% acc</span>
                </div>
              </div>
              <div className="p-3 flex items-center justify-between text-xs">
                <div>
                  <span className="font-semibold text-neutral-900 block">
                    <FillerText semantic="02 · Word Guess" tier="primary" />
                  </span>
                  <span className="text-neutral-500 text-[11px]">
                    <FillerText semantic="Consectetur adipiscing elit" tier="secondary" />
                  </span>
                </div>
                <div className="text-right font-mono">
                  <span className="font-semibold text-neutral-900 block">01:46</span>
                  <span className="text-neutral-500 text-[11px]">88% acc</span>
                </div>
              </div>
              <div className="p-3 flex items-center justify-between text-xs">
                <div>
                  <span className="font-semibold text-neutral-900 block">
                    <FillerText semantic="03 · Mini Crossword" tier="primary" />
                  </span>
                  <span className="text-neutral-500 text-[11px]">
                    <FillerText semantic="Sed do eiusmod tempor incid" tier="secondary" />
                  </span>
                </div>
                <div className="text-right font-mono">
                  <span className="font-semibold text-neutral-900 block">04:38</span>
                  <span className="text-neutral-500 text-[11px]">90% acc</span>
                </div>
              </div>
            </div>
          </div>

          {/* Words Need Review Card */}
          <div className="p-4 rounded-xl border border-neutral-300 bg-neutral-100/70 space-y-2">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold text-neutral-900 uppercase tracking-wide">
                <FillerText semantic="3 words need another look" tier="secondary" />
              </h4>
              <span className="text-[10px] font-mono bg-neutral-200 px-2 py-0.5 rounded text-neutral-800">Actionable</span>
            </div>
            <p className="text-xs text-neutral-600">
              <FillerText
                semantic="Review difficult terms to cement retention before tomorrow's set."
                tier="tertiary"
              />
            </p>
            <LoFiButton
              size="sm"
              variant="outline"
              fullWidth
              onClick={() => onNavigate('2C')}
            >
              <FillerText semantic="Review Flagged Words" tier="primary" />
            </LoFiButton>
          </div>

          <div className="pt-2">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('2C')}
            >
              <FillerText semantic="Continue Practicing (Extra)" tier="primary" />
            </LoFiButton>
          </div>
        </div>

        <LoFiTabBar activeTab="home" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  // 2C: Continue Practicing Screen
  if (activeScreen === '2C') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Continue Practicing"
          subtitle="Flow 02 · Screen 2C"
          onBack={() => onNavigate('2B')}
        />

        <div className="flex-1 px-4 py-5 space-y-4 max-w-md mx-auto w-full">
          <div className="space-y-1">
            <h2 className="text-lg font-bold text-neutral-900">
              <FillerText semantic="Unlimited Practice Hub" tier="primary" />
            </h2>
            <p className="text-xs text-neutral-500">
              <FillerText
                semantic="Your daily set is done. Keep going at any difficulty whenever you want."
                tier="tertiary"
              />
            </p>
          </div>

          {/* Quick Practice Modes */}
          <div className="space-y-2.5">
            {[
              {
                id: 'fitb',
                title: 'Fill in the Blank',
                sub: 'Complete target sentences with correct conjugation',
                tag: '10 Qs',
              },
              {
                id: 'builder',
                title: 'Sentence Builder',
                sub: 'Arrange scrambled word tokens into syntax',
                tag: 'Grammar',
              },
              {
                id: 'match',
                title: 'Definition Match',
                sub: 'Pair Spanish terms with exact English definitions',
                tag: 'Speed',
              },
            ].map((mode) => (
              <div
                key={mode.id}
                onClick={() => onSwitchTab('practice')}
                className="p-3.5 rounded-xl border border-neutral-200 bg-white hover:border-neutral-400 cursor-pointer flex items-center justify-between transition-colors shadow-2xs"
              >
                <div className="space-y-0.5">
                  <div className="flex items-center gap-2">
                    <h4 className="text-sm font-semibold text-neutral-900">
                      <FillerText semantic={mode.title} tier="primary" />
                    </h4>
                    <span className="text-[10px] font-mono bg-neutral-100 text-neutral-700 px-1.5 py-0.5 rounded">
                      {mode.tag}
                    </span>
                  </div>
                  <p className="text-xs text-neutral-500">
                    <FillerText semantic={mode.sub} tier="tertiary" />
                  </p>
                </div>
                <ArrowRight className="w-4 h-4 text-neutral-400 shrink-0" />
              </div>
            ))}
          </div>

          {/* Practice History Card */}
          <div className="p-4 rounded-xl border border-neutral-200 bg-white space-y-3 shadow-2xs">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-bold uppercase text-neutral-700 tracking-wider">
                <FillerText semantic="Practice History Summary" tier="secondary" />
              </h4>
              <span className="text-xs font-mono text-neutral-500">This Month</span>
            </div>
            <div className="grid grid-cols-3 gap-2 text-center py-1">
              <div className="p-2 bg-neutral-50 rounded-lg">
                <span className="text-lg font-bold font-mono text-neutral-900 block">--</span>
                <span className="text-[10px] text-neutral-500">Sessions</span>
              </div>
              <div className="p-2 bg-neutral-50 rounded-lg">
                <span className="text-lg font-bold font-mono text-neutral-900 block">--%</span>
                <span className="text-[10px] text-neutral-500">Avg Acc</span>
              </div>
              <div className="p-2 bg-neutral-50 rounded-lg">
                <span className="text-lg font-bold font-mono text-neutral-900 block">--m</span>
                <span className="text-[10px] text-neutral-500">Time</span>
              </div>
            </div>
            <LoFiButton
              fullWidth
              size="sm"
              variant="outline"
              onClick={() => onSwitchTab('progress')}
            >
              <FillerText semantic="View Full Progress Notebook" tier="primary" />
            </LoFiButton>
          </div>
        </div>

        <LoFiTabBar activeTab="home" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  return null;
}
