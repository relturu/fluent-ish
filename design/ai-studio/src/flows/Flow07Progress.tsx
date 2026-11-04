import React, { useState } from 'react';
import {
  LoFiTopBar,
  LoFiButton,
  LoFiCard,
  LoFiTabBar,
  LoFiInput,
  FillerText,
} from '../components/common/LoFiElements';
import { Share2, Trophy, Check, Copy } from 'lucide-react';

export function Flow07Progress({
  activeScreen,
  onNavigate,
  onSwitchTab,
}: {
  activeScreen: string;
  onNavigate: (screenId: string) => void;
  onSwitchTab: (tab: 'home' | 'practice' | 'progress' | 'profile') => void;
}) {
  const [timeframe, setTimeframe] = useState<'7' | '30' | 'all'>('30');
  const [searchQuery, setSearchQuery] = useState('');
  const [vocabTab, setVocabTab] = useState<'all' | 'review' | 'mastered'>('all');
  const [leaderboardTab, setLeaderboardTab] = useState<'friends' | 'global'>('friends');
  const [showShareModal, setShowShareModal] = useState(false);
  const [copied, setCopied] = useState(false);

  // 7A: Progress Overview Screen
  if (activeScreen === '7A') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Progress Overview"
          subtitle="Flow 07 · Screen 7A"
          rightAction={
            <button
              onClick={() => onNavigate('7C')}
              aria-label="Leaderboard"
              className="w-8 h-8 rounded-lg border border-neutral-300 bg-white flex items-center justify-center text-neutral-700 hover:bg-neutral-100 cursor-pointer"
            >
              <Trophy className="w-4 h-4" />
            </button>
          }
        />

        <div className="flex-1 px-4 py-5 space-y-4 max-w-md mx-auto w-full">
          {/* Timeframe selector */}
          <div className="flex bg-neutral-200 p-1 rounded-xl">
            {(['7', '30', 'all'] as const).map((tf) => (
              <button
                key={tf}
                onClick={() => setTimeframe(tf)}
                className={`flex-1 min-h-[36px] text-xs font-semibold rounded-lg transition-all cursor-pointer ${
                  timeframe === tf
                    ? 'bg-white text-black shadow-xs font-bold'
                    : 'text-neutral-600 hover:text-black'
                }`}
              >
                {tf === '7' ? 'Last 7 Days' : tf === '30' ? 'Last 30 Days' : 'All Time'}
              </button>
            ))}
          </div>

          {/* 3 Metric Cards */}
          <div className="grid grid-cols-3 gap-2 text-center">
            <div className="p-3 bg-white rounded-xl border border-neutral-200 shadow-2xs">
              <span className="text-[10px] font-mono uppercase text-neutral-400 block font-semibold">
                Accuracy
              </span>
              <span className="text-xl font-bold font-mono text-neutral-900">87%</span>
              <span className="text-[10px] text-neutral-500 block">Avg Precision</span>
            </div>
            <div className="p-3 bg-white rounded-xl border border-neutral-200 shadow-2xs">
              <span className="text-[10px] font-mono uppercase text-neutral-400 block font-semibold">
                Learned
              </span>
              <span className="text-xl font-bold font-mono text-neutral-900">246</span>
              <span className="text-[10px] text-neutral-500 block">Active Words</span>
            </div>
            <div className="p-3 bg-white rounded-xl border border-neutral-200 shadow-2xs">
              <span className="text-[10px] font-mono uppercase text-neutral-400 block font-semibold">
                Streak
              </span>
              <span className="text-xl font-bold font-mono text-neutral-900">14d</span>
              <span className="text-[10px] text-neutral-500 block">Consecutive</span>
            </div>
          </div>

          {/* Streak Matrix Calendar (Strictly Grayscale) */}
          <div className="p-4 rounded-xl border border-neutral-200 bg-white space-y-3 shadow-2xs">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase text-neutral-700 tracking-wider">
                <FillerText semantic="Streak Consistency Heatmap" tier="secondary" />
              </span>
              <span className="text-xs font-mono text-neutral-500">October 2026</span>
            </div>

            <div className="grid grid-cols-7 gap-1.5 text-center">
              {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d, i) => (
                <span key={i} className="text-[10px] font-mono text-neutral-400 font-semibold">
                  {d}
                </span>
              ))}
              {Array.from({ length: 28 }).map((_, i) => {
                const activityLevel = (i * 7 + 3) % 4;
                const shadeClass =
                  activityLevel === 3
                    ? 'bg-black text-white font-bold'
                    : activityLevel === 2
                    ? 'bg-neutral-500 text-white'
                    : activityLevel === 1
                    ? 'bg-neutral-200 text-neutral-800'
                    : 'bg-neutral-100 text-neutral-400';

                return (
                  <div
                    key={i}
                    className={`h-7 rounded-md font-mono text-[10px] flex items-center justify-center border border-neutral-200/80 ${shadeClass}`}
                  >
                    {i + 1}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Quick Links to Notebook & Leaderboard */}
          <div className="space-y-2">
            <LoFiButton
              fullWidth
              size="md"
              variant="outline"
              onClick={() => onNavigate('7B')}
            >
              <FillerText semantic="Open Vocabulary Notebook (246 Words)" tier="primary" />
            </LoFiButton>
            <LoFiButton
              fullWidth
              size="md"
              variant="secondary"
              onClick={() => onNavigate('7C')}
              icon={<Trophy className="w-4 h-4" />}
            >
              <FillerText semantic="View Weekly Leaderboard" tier="secondary" />
            </LoFiButton>
          </div>
        </div>

        <LoFiTabBar activeTab="progress" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  // 7B: Vocabulary Notebook Screen
  if (activeScreen === '7B') {
    const vocabItems = [
      { word: 'LOREM', type: 'lorem', meaning: 'Lorem ipsum dolor sit amet', strength: 85, tag: 'Mastered' },
      { word: 'IPSUM', type: 'ipsum', meaning: 'Consectetur adipiscing elit', strength: 60, tag: 'Review' },
      { word: 'DOLOR', type: 'dolor', meaning: 'Sed do eiusmod tempor incid', strength: 95, tag: 'Mastered' },
      { word: 'AMET', type: 'amet', meaning: 'Labore et dolore magna', strength: 90, tag: 'Mastered' },
      { word: 'CONSECT', type: 'consect', meaning: 'Ut enim ad minim veniam', strength: 40, tag: 'Review' },
    ];

    const filtered = vocabItems.filter((item) => {
      if (vocabTab === 'review' && item.tag !== 'Review') return false;
      if (vocabTab === 'mastered' && item.tag !== 'Mastered') return false;
      if (searchQuery && !item.word.toLowerCase().includes(searchQuery.toLowerCase())) return false;
      return true;
    });

    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Vocabulary Notebook"
          subtitle="246 Tracked Words"
          onBack={() => onNavigate('7A')}
        />

        <div className="flex-1 px-4 py-4 space-y-3 max-w-md mx-auto w-full">
          {/* Search Box */}
          <div className="relative">
            <LoFiInput
              placeholder="Search vocabulary..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          {/* Segmented Filter */}
          <div className="flex bg-neutral-200 p-1 rounded-xl">
            {(['all', 'review', 'mastered'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setVocabTab(tab)}
                className={`flex-1 min-h-[34px] text-xs font-semibold rounded-lg capitalize transition-all cursor-pointer ${
                  vocabTab === tab ? 'bg-white text-black shadow-xs font-bold' : 'text-neutral-600'
                }`}
              >
                {tab === 'all' ? 'All (246)' : tab === 'review' ? 'Needs Review' : 'Mastered'}
              </button>
            ))}
          </div>

          {/* Word List */}
          <div className="space-y-2">
            {filtered.map((item, i) => (
              <div
                key={i}
                className="p-3.5 bg-white rounded-xl border border-neutral-200 space-y-2 shadow-2xs"
              >
                <div className="flex items-start justify-between">
                  <div>
                    <h4 className="font-mono font-bold text-sm text-neutral-900">
                      {item.word}
                    </h4>
                    <span className="text-[11px] text-neutral-500 italic block">
                      {item.type} · {item.meaning}
                    </span>
                  </div>
                  <span
                    className={`text-[10px] font-mono px-2 py-0.5 rounded font-semibold ${
                      item.tag === 'Mastered'
                        ? 'bg-black text-white'
                        : 'bg-neutral-200 text-neutral-800'
                    }`}
                  >
                    {item.tag}
                  </span>
                </div>

                {/* Strength Meter in Grayscale */}
                <div className="space-y-1">
                  <div className="flex justify-between text-[10px] font-mono text-neutral-400">
                    <span>Recall Strength</span>
                    <span>{item.strength}%</span>
                  </div>
                  <div className="h-1.5 w-full bg-neutral-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-black rounded-full"
                      style={{ width: `${item.strength}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <LoFiTabBar activeTab="progress" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  // 7C: Leaderboard Screen
  if (activeScreen === '7C') {
    const leaderboardPeers = [
      { rank: 1, name: 'Learner Lorem', pts: 452, acc: '94%' },
      { rank: 2, name: 'Learner Ipsum', pts: 430, acc: '91%' },
      { rank: 3, name: 'Learner Dolor', pts: 425, acc: '89%' },
      { rank: 4, name: 'You (Current User)', pts: 421, acc: '87%', isUser: true },
      { rank: 5, name: 'Learner Amet', pts: 395, acc: '85%' },
      { rank: 6, name: 'Learner Consect', pts: 370, acc: '82%' },
    ];

    return (
      <div className="flex flex-col min-h-full bg-neutral-50 relative">
        <LoFiTopBar
          title="Weekly Leaderboard"
          subtitle="Beginner Tier"
          onBack={() => onNavigate('7A')}
          rightAction={
            <button
              onClick={() => setShowShareModal(true)}
              aria-label="Share"
              className="w-8 h-8 rounded-lg border border-neutral-300 bg-white flex items-center justify-center text-neutral-700 hover:bg-neutral-100 cursor-pointer"
            >
              <Share2 className="w-4 h-4" />
            </button>
          }
        />

        <div className="flex-1 px-4 py-4 space-y-3 max-w-md mx-auto w-full">
          {/* Segmented Filter */}
          <div className="flex bg-neutral-200 p-1 rounded-xl">
            {(['friends', 'global'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setLeaderboardTab(tab)}
                className={`flex-1 min-h-[36px] text-xs font-semibold rounded-lg capitalize transition-all cursor-pointer ${
                  leaderboardTab === tab ? 'bg-white text-black shadow-xs font-bold' : 'text-neutral-600'
                }`}
              >
                {tab === 'friends' ? 'Friends Cohort' : 'Global Tier'}
              </button>
            ))}
          </div>

          {/* User Rank Highlight Card */}
          <div className="p-4 rounded-xl border border-black bg-black text-white flex items-center justify-between shadow-xs">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full border-2 border-white flex items-center justify-center font-mono font-bold text-sm">
                #4
              </div>
              <div>
                <span className="text-[10px] font-mono text-neutral-300 block uppercase">
                  Your Current Standing
                </span>
                <h4 className="text-sm font-bold">Top 15% in Cohort</h4>
              </div>
            </div>
            <div className="text-right font-mono">
              <span className="text-base font-bold block">421 XP</span>
              <span className="text-[10px] text-neutral-300">87% accuracy</span>
            </div>
          </div>

          {/* Peer List */}
          <div className="bg-white rounded-xl border border-neutral-200 divide-y divide-neutral-100 overflow-hidden shadow-2xs">
            {leaderboardPeers.map((peer) => (
              <div
                key={peer.rank}
                className={`p-3 flex items-center justify-between text-xs ${
                  peer.isUser ? 'bg-neutral-100 font-semibold' : ''
                }`}
              >
                <div className="flex items-center gap-3">
                  <span className="w-5 font-mono text-center font-bold text-neutral-500">
                    {peer.rank}
                  </span>
                  <div className="w-7 h-7 rounded-full bg-neutral-200 border border-neutral-300 flex items-center justify-center font-mono text-[10px] text-neutral-700">
                    {peer.name[0]}
                  </div>
                  <span className="text-neutral-900">{peer.name}</span>
                </div>
                <div className="font-mono text-right">
                  <span className="font-bold text-neutral-800 block">{peer.pts} XP</span>
                  <span className="text-[10px] text-neutral-400">{peer.acc}</span>
                </div>
              </div>
            ))}
          </div>

          <LoFiButton
            fullWidth
            size="md"
            variant="outline"
            onClick={() => onNavigate('7D')}
            icon={<Share2 className="w-4 h-4" />}
          >
            <FillerText semantic="Share This Week's Progress" tier="primary" />
          </LoFiButton>

          {/* Quick Share Modal on 7C */}
          {showShareModal && (
            <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4">
              <div className="bg-white rounded-2xl w-full max-w-sm p-4 space-y-3 border-2 border-neutral-300 shadow-2xl">
                <div className="w-10 h-1 bg-neutral-300 rounded-full mx-auto" />
                <div className="text-center space-y-1">
                  <h4 className="font-bold text-sm text-neutral-900">Share Leaderboard Standing</h4>
                  <p className="text-xs text-neutral-500 font-mono">
                    Fluent•ish · Rank #4 · 421 XP
                  </p>
                </div>
                <div className="space-y-2 pt-1">
                  <LoFiButton
                    fullWidth
                    size="md"
                    variant="primary"
                    onClick={() => {
                      setShowShareModal(false);
                      onNavigate('7D');
                    }}
                  >
                    Open Full Social Share Sheet (7D)
                  </LoFiButton>
                  <LoFiButton
                    fullWidth
                    size="sm"
                    variant="outline"
                    onClick={() => setShowShareModal(false)}
                  >
                    Close
                  </LoFiButton>
                </div>
              </div>
            </div>
          )}
        </div>

        <LoFiTabBar activeTab="progress" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  // 7D: Share Results Sheet Screen (Dedicated View)
  if (activeScreen === '7D') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50 relative">
        <LoFiTopBar
          title="Share Weekly Progress"
          subtitle="Flow 07 · Screen 7D"
          onBack={() => onNavigate('7A')}
        />

        <div className="flex-1 px-4 py-5 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-4">
            <div className="text-center space-y-1">
              <span className="text-[10px] font-mono uppercase bg-neutral-200 text-neutral-800 px-2 py-0.5 rounded font-bold">
                Social Export
              </span>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="Share Progress Graphic" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-600 font-mono">
                <FillerText semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod." tier="primary" />
              </p>
            </div>

            {/* Share Card Graphic Preview */}
            <div className="p-5 rounded-2xl border-2 border-black bg-white text-center space-y-3 font-mono shadow-xs">
              <div className="flex items-center justify-between border-b border-neutral-100 pb-2 text-[10px] text-neutral-500 uppercase">
                <span className="font-bold text-neutral-900">Fluent•ish</span>
                <span>October 2026 Snapshot</span>
              </div>

              <div className="py-2 space-y-1">
                <div className="text-2xl font-bold text-neutral-900 tracking-wide">
                  482 XP · 14-DAY STREAK
                </div>
                <div className="text-xs text-neutral-600">
                  87% accuracy across daily language challenges
                </div>
              </div>

              {/* Latin quote filler */}
              <div className="p-3 bg-neutral-50 rounded-xl border border-neutral-200 text-xs text-neutral-700 leading-relaxed italic">
                &ldquo;Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore.&rdquo;
              </div>

              {/* Grayscale Mini Streak Bars */}
              <div className="flex justify-center items-end gap-1.5 h-10 py-1 bg-neutral-50 rounded-lg border border-neutral-100">
                {[60, 80, 45, 90, 70, 100, 85].map((h, i) => (
                  <div key={i} className="w-5 bg-neutral-200 rounded-xs flex items-end overflow-hidden h-full">
                    <div className="w-full bg-black" style={{ height: `${h}%` }} />
                  </div>
                ))}
              </div>

              <div className="flex justify-between items-center pt-1 text-[11px] text-neutral-500 border-t border-neutral-100 font-mono">
                <span>Cohort Rank #4</span>
                <span>Track: Lorem Ipsum</span>
              </div>
            </div>

            {/* Share format options */}
            <div className="space-y-1.5">
              <span className="text-[10px] uppercase font-mono text-neutral-400 font-semibold block">
                Export Format
              </span>
              <div className="grid grid-cols-3 gap-2">
                {['Image Card', 'Text Summary', 'Direct Link'].map((fmt, idx) => (
                  <button
                    key={fmt}
                    className={`py-2 px-1 text-xs rounded-lg border font-mono text-center cursor-pointer transition-colors ${
                      idx === 0
                        ? 'border-black bg-black text-white font-bold'
                        : 'border-neutral-200 bg-white text-neutral-700 hover:border-neutral-400'
                    }`}
                  >
                    {fmt}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="pt-4 space-y-2">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => {
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
              }}
              icon={copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
            >
              <FillerText
                semantic={copied ? 'Copied to Clipboard!' : 'Copy Summary Text'}
                tier="primary"
              />
            </LoFiButton>
            <LoFiButton
              fullWidth
              size="md"
              variant="outline"
              onClick={() => onNavigate('7A')}
            >
              <FillerText semantic="Return to Progress Overview" tier="primary" />
            </LoFiButton>
          </div>
        </div>

        <LoFiTabBar activeTab="progress" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  return null;
}
