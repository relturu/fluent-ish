import React, { useState } from 'react';
import { Share2, Heart, Check, Send, Flame, Crown, Copy, X } from 'lucide-react';
import { FriendHighlight, LeaderboardEntry, UserStats } from '../types';
import {
  HiFiButton,
  PageTopBar,
  StreakIndicator,
  AudioButton,
  useTheme,
} from '../components/common/HiFiElements';

export function Page02Friends({
  highlights,
  onAddHighlight,
  onToggleLike,
  userStats,
  onOpenRules,
}: {
  highlights: FriendHighlight[];
  onAddHighlight: (item: FriendHighlight) => void;
  onToggleLike: (id: string) => void;
  userStats?: UserStats;
  onOpenRules?: () => void;
}) {
  const { darkMode } = useTheme();
  const [boardScope, setBoardScope] = useState<'friends' | 'global'>('friends');
  const [userFillIn, setUserFillIn] = useState('');
  const [justPosted, setJustPosted] = useState(false);
  const [sharePreviewItem, setSharePreviewItem] =
    useState<FriendHighlight | null>(null);
  const [copiedCard, setCopiedCard] = useState(false);

  const friendsLeaderboard: LeaderboardEntry[] = [
    {
      rank: 1,
      name: 'Maya Lin',
      handle: '@maya',
      initials: 'ML',
      streak: 21,
      points: 1380,
      accuracy: '94%',
    },
    {
      rank: 2,
      name: 'Sofía (You)',
      handle: '@sofia',
      initials: 'SM',
      streak: 14,
      points: 1245,
      accuracy: '89%',
      isUser: true,
    },
    {
      rank: 3,
      name: 'Lucas Chen',
      handle: '@lucas',
      initials: 'LC',
      streak: 12,
      points: 1190,
      accuracy: '91%',
    },
    {
      rank: 4,
      name: 'Elena Vance',
      handle: '@elena',
      initials: 'EV',
      streak: 9,
      points: 1040,
      accuracy: '86%',
    },
  ];

  const globalLeaderboard: LeaderboardEntry[] = [
    {
      rank: 1,
      name: 'Diego Morales',
      handle: '@diego',
      initials: 'DM',
      streak: 64,
      points: 2410,
      accuracy: '97%',
    },
    {
      rank: 2,
      name: 'Hannah Kim',
      handle: '@hannah',
      initials: 'HK',
      streak: 49,
      points: 2280,
      accuracy: '95%',
    },
    {
      rank: 3,
      name: 'Maya Lin',
      handle: '@maya',
      initials: 'ML',
      streak: 21,
      points: 1380,
      accuracy: '94%',
    },
    {
      rank: 4,
      name: 'Sofía (You)',
      handle: '@sofia',
      initials: 'SM',
      streak: 14,
      points: 1245,
      accuracy: '89%',
      isUser: true,
    },
  ];

  const activeList =
    boardScope === 'friends' ? friendsLeaderboard : globalLeaderboard;

  // Podium 1-2-3 resolution
  const top1 = activeList.find((p) => p.rank === 1);
  const top2 = activeList.find((p) => p.rank === 2);
  const top3 = activeList.find((p) => p.rank === 3);
  const restList = activeList.filter((p) => p.rank > 3);
  const userInTop3 = [top1, top2, top3].some((p) => p?.isUser);
  const userEntry = activeList.find((p) => p.isUser);

  const handlePostFillIn = (e: React.FormEvent) => {
    e.preventDefault();
    if (!userFillIn.trim()) return;

    const fullSpanishSentence = `En nuestra sobremesa nunca falta ${userFillIn.trim()}.`;
    const newPost: FriendHighlight = {
      id: `post-${Date.now()}`,
      userName: 'Sofía',
      userHandle: '@sofia',
      avatarInitials: 'SM',
      avatarBg: '#FF6B2C',
      type: 'fill-in',
      timestamp: 'Now',
      badgeText: 'Daily Fill-In',
      contentEs: fullSpanishSentence,
      contentEn: '',
      likes: 1,
      likedByMe: true,
      isCurrentUser: true,
    };

    onAddHighlight(newPost);
    setUserFillIn('');
    setJustPosted(true);
    setTimeout(() => setJustPosted(false), 2000);
  };

  const handleCopyCard = () => {
    setCopiedCard(true);
    setTimeout(() => setCopiedCard(false), 2000);
  };

  return (
    <div className="flex flex-col flex-1">
      <PageTopBar
        title="Friends"
        rightAction={
          <div className="flex items-center gap-2 select-none">
            <StreakIndicator
              streakCount={userStats?.streakCount ?? 14}
              streakCountedToday={userStats?.streakCountedToday ?? false}
              onClick={onOpenRules}
            />
          </div>
        }
      />

      <div className="px-4 py-5 space-y-7">
        {/* 1. Competitive Leaderboard with Clear Centerpiece Podium */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <h2 className="type-h2">Leaderboard</h2>
              <span className="text-[10px] font-extrabold text-[#FF6B2C] px-2.5 py-0.5 rounded-full bg-[#FF6B2C]/15 border border-[#FF6B2C]/25 uppercase tracking-wider">
                Weekly Cup
              </span>
            </div>
            <div className="flex gap-1 bg-current/5 p-1 rounded-xl">
              {(['friends', 'global'] as const).map((tab) => (
                <button
                  key={tab}
                  type="button"
                  onClick={() => setBoardScope(tab)}
                  className={`px-3 py-1 rounded-lg text-[11px] font-extrabold capitalize cursor-pointer transition-colors ${
                    boardScope === tab
                      ? 'bg-[#FF6B2C] text-white shadow-xs'
                      : 'opacity-60 hover:opacity-100'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>

          {/* THE PODIUM (Clear Centerpiece) */}
          <div
            className={`p-5 rounded-[26px] border shadow-xs space-y-2 transition-colors ${
              darkMode
                ? 'bg-[#221E52] border-white/10'
                : 'bg-white border-[#1F1B4D]/10'
            }`}
          >
            <div className="flex items-end justify-center gap-2.5 pt-4 pb-1">
              {/* #2 SILVER (LEFT) */}
              {top2 && (
                <div className="flex-1 flex flex-col items-center text-center">
                  <div className="mb-2 flex flex-col items-center">
                    <div
                      className={`w-10 h-10 rounded-2xl flex items-center justify-center text-[12px] font-extrabold shadow-sm ${
                        top2.isUser
                          ? 'bg-[#FF6B2C] text-white ring-2 ring-[#FF6B2C] ring-offset-2 ring-offset-current/5'
                          : 'bg-[#CBD5E1] text-[#1F1B4D]'
                      }`}
                    >
                      {top2.initials}
                    </div>
                    <span className="text-[12px] font-bold truncate max-w-[85px] mt-1 block">
                      {top2.name.split(' ')[0]}
                      {top2.isUser && ' (You)'}
                    </span>
                    <span className="text-[11px] font-extrabold text-[#7B5CFF] tabular-nums">
                      {top2.points} XP
                    </span>
                  </div>

                  {/* Silver Block */}
                  <div
                    className="w-full h-24 rounded-t-2xl bg-gradient-to-b from-[#E2E8F0] to-[#CBD5E1] dark:from-[#4A5568] dark:to-[#2D3748] border-t-2 border-x-2 border-white/40 flex flex-col items-center justify-center animate-podium-rise shadow-sm"
                  >
                    <span className="text-[20px] font-extrabold text-[#475569] dark:text-[#E2E8F0]">
                      2
                    </span>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-[#475569]/80 dark:text-[#CBD5E1]/80">
                      Silver
                    </span>
                  </div>
                </div>
              )}

              {/* #1 GOLD (CENTER & TALLEST) */}
              {top1 && (
                <div className="flex-1 flex flex-col items-center text-center -mt-3">
                  <div className="mb-2 flex flex-col items-center">
                    <div className="flex items-center justify-center mb-1">
                      <Crown className="w-5 h-5 text-[#FFC93C] fill-current drop-shadow-xs" />
                    </div>
                    <div
                      className={`w-12 h-12 rounded-2xl flex items-center justify-center text-[14px] font-extrabold shadow-md ${
                        top1.isUser
                          ? 'bg-[#FF6B2C] text-white ring-2 ring-[#FF6B2C] ring-offset-2 ring-offset-current/5'
                          : 'bg-[#FFC93C] text-[#1F1B4D]'
                      }`}
                    >
                      {top1.initials}
                    </div>
                    <span className="text-[13px] font-extrabold truncate max-w-[95px] mt-1 block">
                      {top1.name.split(' ')[0]}
                      {top1.isUser && ' (You)'}
                    </span>
                    <span className="text-[12px] font-extrabold text-[#FF6B2C] tabular-nums">
                      {top1.points} XP
                    </span>
                  </div>

                  {/* Gold Block (Tallest) */}
                  <div
                    className="w-full h-32 rounded-t-2xl bg-gradient-to-b from-[#FFD700] to-[#FFC93C] dark:from-[#D4A317] dark:to-[#9E770E] border-t-2 border-x-2 border-white/50 flex flex-col items-center justify-center animate-podium-rise shadow-md"
                  >
                    <span className="text-[24px] font-extrabold text-[#1F1B4D]">
                      1
                    </span>
                    <span className="text-[10px] font-extrabold uppercase tracking-wider text-[#1F1B4D]/80">
                      Gold
                    </span>
                  </div>
                </div>
              )}

              {/* #3 BRONZE (RIGHT) */}
              {top3 && (
                <div className="flex-1 flex flex-col items-center text-center">
                  <div className="mb-2 flex flex-col items-center">
                    <div
                      className={`w-10 h-10 rounded-2xl flex items-center justify-center text-[12px] font-extrabold shadow-sm ${
                        top3.isUser
                          ? 'bg-[#FF6B2C] text-white ring-2 ring-[#FF6B2C] ring-offset-2 ring-offset-current/5'
                          : 'bg-[#ED8936] text-white'
                      }`}
                    >
                      {top3.initials}
                    </div>
                    <span className="text-[12px] font-bold truncate max-w-[85px] mt-1 block">
                      {top3.name.split(' ')[0]}
                      {top3.isUser && ' (You)'}
                    </span>
                    <span className="text-[11px] font-extrabold text-[#19C3B1] tabular-nums">
                      {top3.points} XP
                    </span>
                  </div>

                  {/* Bronze Block */}
                  <div
                    className="w-full h-20 rounded-t-2xl bg-gradient-to-b from-[#ED8936] to-[#DD6B20] dark:from-[#C05621] dark:to-[#9C4221] border-t-2 border-x-2 border-white/40 flex flex-col items-center justify-center animate-podium-rise shadow-sm"
                  >
                    <span className="text-[18px] font-extrabold text-white">
                      3
                    </span>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-white/80">
                      Bronze
                    </span>
                  </div>
                </div>
              )}
            </div>

            {/* Standings List Below Podium */}
            <div className="space-y-1.5 pt-3 border-t border-current/10">
              {restList.map((peer) => {
                const isUser = peer.isUser;
                return (
                  <div
                    key={peer.handle}
                    className={`py-2 px-3.5 rounded-xl border flex items-center justify-between gap-3 transition-colors ${
                      isUser
                        ? 'bg-[#FF6B2C]/15 border-[#FF6B2C] font-extrabold shadow-xs'
                        : darkMode
                        ? 'bg-[#17143A]/60 border-white/10'
                        : 'bg-[#FFF8EC]/60 border-[#1F1B4D]/10'
                    }`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <span className="text-[12px] font-extrabold opacity-60 w-4 text-center">
                        {peer.rank}
                      </span>
                      <div className="w-8 h-8 rounded-xl bg-current/10 flex items-center justify-center text-[11px] font-extrabold shrink-0">
                        {peer.initials}
                      </div>
                      <div className="min-w-0">
                        <span className="text-[13px] font-bold truncate block">
                          {peer.name}
                        </span>
                        <span className="text-[11px] opacity-60">{peer.handle}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      {isUser && (
                        <span className="px-2 py-0.5 rounded-md bg-[#FF6B2C] text-white text-[10px] font-extrabold uppercase">
                          YOU
                        </span>
                      )}
                      <span className="text-[13px] font-extrabold tabular-nums">
                        {peer.points} XP
                      </span>
                    </div>
                  </div>
                );
              })}

              {/* Pin Sofía if she is not in top 3 and not already in restList */}
              {!userInTop3 && userEntry && !restList.some((p) => p.isUser) && (
                <div className="py-2.5 px-3.5 rounded-xl border-2 border-[#FF6B2C] bg-[#FF6B2C]/15 flex items-center justify-between gap-3 shadow-sm mt-2">
                  <div className="flex items-center gap-3">
                    <span className="text-[12px] font-extrabold text-[#FF6B2C] w-4 text-center">
                      {userEntry.rank}
                    </span>
                    <div className="w-8 h-8 rounded-xl bg-[#FF6B2C] text-white flex items-center justify-center text-[11px] font-extrabold">
                      {userEntry.initials}
                    </div>
                    <div>
                      <span className="text-[13px] font-extrabold block">
                        {userEntry.name}
                      </span>
                      <span className="text-[11px] opacity-65">{userEntry.handle}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="px-2 py-0.5 rounded-md bg-[#FF6B2C] text-white text-[10px] font-extrabold uppercase">
                      YOU
                    </span>
                    <span className="text-[13px] font-extrabold text-[#FF6B2C] tabular-nums">
                      {userEntry.points} XP
                    </span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </section>

        {/* 2. Interactive Sentence Fill-In Prompt */}
        <section
          className={`p-4 rounded-[22px] border space-y-3 shadow-xs transition-colors ${
            darkMode
              ? 'bg-[#221E52] border-white/10'
              : 'bg-white border-[#1F1B4D]/10'
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="type-caption text-[#FF6B2C] block">
              Daily Spanish Prompt
            </span>
            <span className="text-[11px] opacity-60 font-bold">La Sobremesa</span>
          </div>

          <p className="text-[14px] font-bold leading-snug">
            “En nuestra sobremesa nunca falta{' '}
            <span className="underline decoration-[#FF6B2C] decoration-2">
              {userFillIn.trim() || '__________'}
            </span>
            .”
          </p>

          <form onSubmit={handlePostFillIn} className="flex gap-2">
            <input
              type="text"
              value={userFillIn}
              onChange={(e) => setUserFillIn(e.target.value)}
              placeholder="e.g., buen café, risas..."
              className={`flex-1 h-10 px-3.5 rounded-xl border text-[13px] font-medium focus:outline-none ${
                darkMode
                  ? 'bg-[#17143A] border-white/15 text-[#FFF8EC] placeholder-white/40'
                  : 'bg-[#FFF8EC] border-[#1F1B4D]/15 text-[#1F1B4D] placeholder-[#1F1B4D]/40'
              }`}
            />
            <button
              type="submit"
              disabled={!userFillIn.trim()}
              className="btn-3d-primary px-4 py-2 rounded-xl text-[13px] font-extrabold flex items-center gap-1 shadow-xs cursor-pointer min-h-[44px]"
            >
              <Send className="w-3.5 h-3.5" />
              <span>Share</span>
            </button>
          </form>

          {justPosted && (
            <div className="text-[12px] font-bold text-[#3DDC84] flex items-center gap-1">
              <Check className="w-3.5 h-3.5 stroke-[3]" />
              <span>Shared to your friend feed!</span>
            </div>
          )}
        </section>

        {/* 3. Friends Activity Feed */}
        <section className="space-y-3 pb-4">
          <h2 className="type-h2">Friend Highlights</h2>

          <div className="space-y-3">
            {highlights.map((item) => (
              <div
                key={item.id}
                className={`p-4 rounded-[22px] border space-y-2.5 shadow-xs transition-colors ${
                  darkMode
                    ? 'bg-[#221E52] border-white/10'
                    : 'bg-white border-[#1F1B4D]/10'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div
                      className="w-8 h-8 rounded-xl flex items-center justify-center text-white text-[11px] font-extrabold"
                      style={{ backgroundColor: item.avatarBg || '#7B5CFF' }}
                    >
                      {item.avatarInitials}
                    </div>
                    <div>
                      <span className="text-[13px] font-bold block leading-none">
                        {item.userName}
                      </span>
                      <span className="text-[11px] opacity-60">
                        {item.userHandle} · {item.timestamp}
                      </span>
                    </div>
                  </div>

                  <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-md bg-current/10 uppercase">
                    {item.badgeText}
                  </span>
                </div>

                <p className="text-[14px] font-medium leading-snug">
                  {item.contentEs}
                </p>

                <div className="flex items-center justify-between pt-2 border-t border-current/10 text-[12px]">
                  <button
                    type="button"
                    onClick={() => onToggleLike(item.id)}
                    className={`flex items-center gap-1.5 font-bold cursor-pointer transition-colors min-h-[44px] px-1 ${
                      item.likedByMe ? 'text-[#FF5C6C]' : 'opacity-65 hover:opacity-100'
                    }`}
                  >
                    <Heart
                      className={`w-4 h-4 ${
                        item.likedByMe ? 'fill-current' : ''
                      }`}
                    />
                    <span className="tabular-nums">{item.likes}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setSharePreviewItem(item)}
                    className="flex items-center gap-1 opacity-65 hover:opacity-100 font-bold cursor-pointer min-h-[44px] px-2"
                  >
                    <Share2 className="w-3.5 h-3.5" />
                    <span>Card</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* Share Card Modal */}
      {sharePreviewItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div
            className={`w-full max-w-sm rounded-[26px] p-5 space-y-4 border shadow-2xl ${
              darkMode
                ? 'bg-[#221E52] border-white/15 text-[#FFF8EC]'
                : 'bg-white border-[#1F1B4D]/15 text-[#1F1B4D]'
            }`}
          >
            <div className="flex items-center justify-between">
              <h3 className="text-[15px] font-bold">Share Highlight</h3>
              <button
                type="button"
                onClick={() => setSharePreviewItem(null)}
                className="w-8 h-8 rounded-lg bg-current/10 flex items-center justify-center cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-4 rounded-2xl bg-[#FF6B2C]/10 border border-[#FF6B2C]/30 space-y-2 text-center">
              <span className="text-[11px] font-extrabold uppercase text-[#FF6B2C] tracking-wide block">
                Fluent•ish Daily
              </span>
              <p className="text-[15px] font-extrabold">
                “{sharePreviewItem.contentEs}”
              </p>
              <span className="text-[12px] opacity-70 block">
                by {sharePreviewItem.userName}
              </span>
            </div>

            <HiFiButton
              fullWidth
              variant="primary"
              onClick={handleCopyCard}
              icon={
                copiedCard ? (
                  <Check className="w-4 h-4" />
                ) : (
                  <Copy className="w-4 h-4" />
                )
              }
            >
              {copiedCard ? 'Copied Card!' : 'Copy Share Card'}
            </HiFiButton>
          </div>
        </div>
      )}
    </div>
  );
}
