import React, { useState } from 'react';
import {
  LoFiTopBar,
  LoFiButton,
  LoFiCard,
  LoFiTabBar,
  LoFiToggle,
  FillerText,
} from '../components/common/LoFiElements';
import { WifiOff, RefreshCw, AlertTriangle, LogOut, Check } from 'lucide-react';

export function Flow08ProfileSettings({
  activeScreen,
  onNavigate,
  onSwitchTab,
  onSignOut,
}: {
  activeScreen: string;
  onNavigate: (screenId: string) => void;
  onSwitchTab: (tab: 'home' | 'practice' | 'progress' | 'profile') => void;
  onSignOut: () => void;
}) {
  // Settings toggles state
  const [reminders, setReminders] = useState(true);
  const [autoAudio, setAutoAudio] = useState(true);
  const [haptics, setHaptics] = useState(true);
  const [highContrast, setHighContrast] = useState(false);
  const [reduceMotion, setReduceMotion] = useState(false);

  // Active confirmation modal
  const [activeModal, setActiveModal] = useState<'leave' | 'language' | 'signout' | null>(null);
  const [offlineSyncing, setOfflineSyncing] = useState(false);

  // 8A: Profile & Settings Screen
  if (activeScreen === '8A') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50 relative">
        <LoFiTopBar
          title="Profile & Settings"
          subtitle="Flow 08 · Screen 8A"
        />

        <div className="flex-1 px-4 py-4 space-y-4 max-w-md mx-auto w-full">
          {/* User Account Tile */}
          <div className="p-4 bg-white rounded-xl border border-neutral-200 flex items-center justify-between shadow-2xs">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-full border-2 border-neutral-400 bg-neutral-100 flex items-center justify-center font-mono font-bold text-neutral-800 text-sm">
                MR
              </div>
              <div>
                <h3 className="text-sm font-bold text-neutral-900">
                  <FillerText semantic="Maria Rivera" lorem="Discipulus Exemplar" />
                </h3>
                <span className="text-xs text-neutral-500 font-mono block">
                  maria.user@domain.com
                </span>
              </div>
            </div>
            <button className="text-xs font-semibold text-neutral-700 border border-neutral-300 px-2.5 py-1 rounded hover:bg-neutral-100 cursor-pointer">
              Edit
            </button>
          </div>

          {/* Preferences Section */}
          <div className="space-y-1">
            <span className="text-xs font-bold uppercase text-neutral-600 px-1 tracking-wider">
              Curriculum & Goals
            </span>
            <div className="bg-white rounded-xl border border-neutral-200 divide-y divide-neutral-100 text-xs">
              <div className="p-3 flex items-center justify-between">
                <div>
                  <span className="font-semibold text-neutral-800 block">Proficiency Level</span>
                  <span className="text-neutral-500 text-[11px]">Beginner Track (Calibrated)</span>
                </div>
                <button
                  onClick={() => setActiveModal('language')}
                  className="text-neutral-700 underline font-medium cursor-pointer"
                >
                  Adjust
                </button>
              </div>
              <div className="p-3 flex items-center justify-between">
                <div>
                  <span className="font-semibold text-neutral-800 block">Daily Target Goal</span>
                  <span className="text-neutral-500 text-[11px]">10 minutes / day</span>
                </div>
                <button className="text-neutral-700 underline font-medium cursor-pointer">
                  Change
                </button>
              </div>
              <div className="p-3 flex items-center justify-between">
                <div>
                  <span className="font-semibold text-neutral-800 block">Target Language</span>
                  <span className="text-neutral-500 text-[11px]">Language Alpha (Active)</span>
                </div>
                <button
                  onClick={() => setActiveModal('language')}
                  className="text-neutral-700 underline font-medium cursor-pointer"
                >
                  Switch
                </button>
              </div>
            </div>
          </div>

          {/* Audio & Haptic Toggles */}
          <div className="space-y-1">
            <span className="text-xs font-bold uppercase text-neutral-600 px-1 tracking-wider">
              Audio & Haptic Feedback
            </span>
            <div className="bg-white rounded-xl border border-neutral-200 p-1">
              <LoFiToggle
                checked={reminders}
                onChange={setReminders}
                label="Practice notifications"
                description="Daily alert at 8:00 AM"
              />
              <div className="border-t border-neutral-100" />
              <LoFiToggle
                checked={autoAudio}
                onChange={setAutoAudio}
                label="Auto-play pronunciation"
                description="Play audio on new flashcard reveal"
              />
              <div className="border-t border-neutral-100" />
              <LoFiToggle
                checked={haptics}
                onChange={setHaptics}
                label="Haptic vibrations"
                description="Tactile pulse on correct word match"
              />
            </div>
          </div>

          {/* Accessibility */}
          <div className="space-y-1">
            <span className="text-xs font-bold uppercase text-neutral-600 px-1 tracking-wider">
              Accessibility & Display
            </span>
            <div className="bg-white rounded-xl border border-neutral-200 p-1">
              <LoFiToggle
                checked={highContrast}
                onChange={setHighContrast}
                label="High contrast borders"
                description="Enhanced card boundaries for low-vision support"
              />
              <div className="border-t border-neutral-100" />
              <LoFiToggle
                checked={reduceMotion}
                onChange={setReduceMotion}
                label="Reduce motion"
                description="Minimize slide and scale animations"
              />
            </div>
          </div>

          {/* Quick links to System States & Modals */}
          <div className="p-3 bg-neutral-200/70 rounded-xl space-y-2 text-xs">
            <span className="font-mono uppercase font-bold text-neutral-600 text-[10px] block">
              Wireframe Review Shortcuts
            </span>
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={() => onNavigate('8B')}
                className="p-2 rounded bg-white border border-neutral-300 text-left hover:border-neutral-500 cursor-pointer"
              >
                <span className="font-bold text-neutral-900 block">Screen 8B</span>
                <span className="text-neutral-500 text-[11px]">System States</span>
              </button>
              <button
                onClick={() => onNavigate('8C')}
                className="p-2 rounded bg-white border border-neutral-300 text-left hover:border-neutral-500 cursor-pointer"
              >
                <span className="font-bold text-neutral-900 block">Screen 8C</span>
                <span className="text-neutral-500 text-[11px]">Confirmation Patterns</span>
              </button>
            </div>
          </div>

          {/* Sign Out Action */}
          <div className="pt-2">
            <LoFiButton
              fullWidth
              size="md"
              variant="outline"
              onClick={() => setActiveModal('signout')}
              icon={<LogOut className="w-4 h-4 text-neutral-600" />}
            >
              <FillerText semantic="Sign Out of Session" lorem="Claudere Sessionem" />
            </LoFiButton>
          </div>
        </div>

        {/* Global Modals overlay for 8A */}
        {activeModal === 'signout' && (
          <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl border border-neutral-300 p-5 max-w-sm w-full space-y-4 shadow-xl">
              <h3 className="text-base font-bold text-neutral-900">
                <FillerText semantic="Sign out of account?" lorem="Claudere sessionem?" />
              </h3>
              <p className="text-xs text-neutral-600">
                <FillerText
                  semantic="Downloaded offline word cards will be preserved on this device. Synced progress remains safe."
                  lorem="Documenta salva manebunt in hoc apparatu."
                />
              </p>
              <div className="grid grid-cols-2 gap-2 pt-2">
                <LoFiButton variant="outline" size="md" onClick={() => setActiveModal(null)}>
                  <FillerText semantic="Cancel" lorem="Abrogare" />
                </LoFiButton>
                <LoFiButton
                  variant="primary"
                  size="md"
                  onClick={() => {
                    setActiveModal(null);
                    onSignOut();
                  }}
                >
                  <FillerText semantic="Sign Out" lorem="Claudere" />
                </LoFiButton>
              </div>
            </div>
          </div>
        )}

        {activeModal === 'language' && (
          <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl border border-neutral-300 p-5 max-w-sm w-full space-y-4 shadow-xl">
              <h3 className="text-base font-bold text-neutral-900">
                <FillerText semantic="Change Target Language?" lorem="Mutare Linguam?" />
              </h3>
              <p className="text-xs text-neutral-600">
                <FillerText
                  semantic="Switching to a new language starts a separate learning profile. Existing streak and vocabulary remain saved."
                  lorem="Novum consilium incipietur sine damno pristinorum."
                />
              </p>
              <div className="grid grid-cols-2 gap-2 pt-2">
                <LoFiButton variant="outline" size="md" onClick={() => setActiveModal(null)}>
                  <FillerText semantic="Cancel" lorem="Abrogare" />
                </LoFiButton>
                <LoFiButton
                  variant="primary"
                  size="md"
                  onClick={() => setActiveModal(null)}
                >
                  <FillerText semantic="Confirm Switch" lorem="Confirmare" />
                </LoFiButton>
              </div>
            </div>
          </div>
        )}

        <LoFiTabBar activeTab="profile" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  // 8B: System States Screen
  if (activeScreen === '8B') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="System States"
          subtitle="Flow 08 · Screen 8B"
          onBack={() => onNavigate('8A')}
        />

        <div className="flex-1 px-4 py-5 space-y-5 max-w-md mx-auto w-full">
          {/* Offline Banner & Alert Pattern */}
          <div className="space-y-2">
            <span className="text-xs font-bold uppercase text-neutral-600 tracking-wider">
              Pattern A: Offline Network State
            </span>
            <div className="p-4 rounded-xl border border-neutral-300 bg-white space-y-3 shadow-xs">
              <div className="flex items-center gap-2 text-neutral-900">
                <div className="w-8 h-8 rounded-full bg-neutral-100 flex items-center justify-center shrink-0">
                  <WifiOff className="w-4 h-4 text-neutral-800" />
                </div>
                <div>
                  <h4 className="text-xs font-bold">
                    <FillerText semantic="You're Currently Offline" lorem="Sine Connexione" />
                  </h4>
                  <span className="text-[11px] text-neutral-500">
                    Local word caches are ready to practice
                  </span>
                </div>
              </div>
              <p className="text-xs text-neutral-600">
                <FillerText
                  semantic="Your daily flashcards are available offline. Leaderboard ranks will synchronize once connected."
                  lorem="Pensa localia parata sunt. Tabula ducum postea renovabitur."
                />
              </p>
              <div className="grid grid-cols-2 gap-2 pt-1">
                <LoFiButton size="sm" variant="outline">
                  <FillerText semantic="Keep Practicing" lorem="Pergere" />
                </LoFiButton>
                <LoFiButton
                  size="sm"
                  variant="primary"
                  onClick={() => {
                    setOfflineSyncing(true);
                    setTimeout(() => setOfflineSyncing(false), 1500);
                  }}
                  icon={<RefreshCw className={`w-3.5 h-3.5 ${offlineSyncing ? 'animate-spin' : ''}`} />}
                >
                  <FillerText semantic={offlineSyncing ? 'Checking...' : 'Retry Connection'} lorem="Iterum" />
                </LoFiButton>
              </div>
            </div>
          </div>

          {/* Syncing Loader Pattern */}
          <div className="space-y-2">
            <span className="text-xs font-bold uppercase text-neutral-600 tracking-wider">
              Pattern B: Daily Set Syncing Loader
            </span>
            <div className="p-5 rounded-xl border border-neutral-300 bg-white text-center space-y-3 shadow-xs">
              <div className="w-10 h-10 rounded-full border-2 border-neutral-300 border-t-neutral-900 animate-spin mx-auto" />
              <div>
                <h4 className="text-xs font-bold text-neutral-900">
                  <FillerText semantic="Preparing Today's Set..." lorem="Pensa Hodierna Parantur..." />
                </h4>
                <p className="text-xs text-neutral-500 mt-0.5">
                  <FillerText
                    semantic="Synchronizing your 12 focus words, audio assets, and 3 daily puzzles."
                    lorem="Vocabula et aenigmata renovantur."
                  />
                </p>
              </div>
              <span className="text-[10px] text-neutral-400 font-mono block">
                Estimated sync: 1.2s · 48kb transferred
              </span>
            </div>
          </div>

          <LoFiButton
            fullWidth
            size="md"
            variant="outline"
            onClick={() => onNavigate('8A')}
          >
            <FillerText semantic="Back to Profile Settings" lorem="Revertere" />
          </LoFiButton>
        </div>

        <LoFiTabBar activeTab="profile" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  // 8C: Confirmation Patterns Screen
  if (activeScreen === '8C') {
    return (
      <div className="flex flex-col min-h-full bg-neutral-50">
        <LoFiTopBar
          title="Confirmation Patterns"
          subtitle="Flow 08 · Screen 8C"
          onBack={() => onNavigate('8A')}
        />

        <div className="flex-1 px-4 py-5 space-y-4 max-w-md mx-auto w-full">
          <div className="space-y-1">
            <h2 className="text-sm font-bold text-neutral-900 uppercase tracking-wider">
              <FillerText semantic="Standard Modal Dialog Patterns" lorem="Exemplaria Dialogorum" />
            </h2>
            <p className="text-xs text-neutral-500">
              Trigger any modal below to evaluate placement, backdrop scrim, and action hierarchy.
            </p>
          </div>

          {/* Trigger Buttons */}
          <div className="space-y-2.5">
            <div className="p-3.5 rounded-xl border border-neutral-200 bg-white flex items-center justify-between shadow-2xs">
              <div>
                <h4 className="text-xs font-bold text-neutral-900">
                  <FillerText semantic="Pattern 1: Leave Active Game" lorem="Exire e Ludo" />
                </h4>
                <span className="text-[11px] text-neutral-500">Preserves game progress</span>
              </div>
              <LoFiButton size="sm" variant="outline" onClick={() => setActiveModal('leave')}>
                Trigger
              </LoFiButton>
            </div>

            <div className="p-3.5 rounded-xl border border-neutral-200 bg-white flex items-center justify-between shadow-2xs">
              <div>
                <h4 className="text-xs font-bold text-neutral-900">
                  <FillerText semantic="Pattern 2: Switch Curriculum" lorem="Mutare Linguam" />
                </h4>
                <span className="text-[11px] text-neutral-500">Multi-profile warning</span>
              </div>
              <LoFiButton size="sm" variant="outline" onClick={() => setActiveModal('language')}>
                Trigger
              </LoFiButton>
            </div>

            <div className="p-3.5 rounded-xl border border-neutral-200 bg-white flex items-center justify-between shadow-2xs">
              <div>
                <h4 className="text-xs font-bold text-neutral-900">
                  <FillerText semantic="Pattern 3: Account Sign Out" lorem="Claudere Sessionem" />
                </h4>
                <span className="text-[11px] text-neutral-500">Session termination</span>
              </div>
              <LoFiButton size="sm" variant="outline" onClick={() => setActiveModal('signout')}>
                Trigger
              </LoFiButton>
            </div>
          </div>

          {/* Active Modal Display */}
          {activeModal === 'leave' && (
            <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
              <div className="bg-white rounded-2xl border border-neutral-300 p-5 max-w-sm w-full space-y-4 shadow-xl">
                <div className="w-10 h-10 rounded-full bg-neutral-100 flex items-center justify-center">
                  <AlertTriangle className="w-5 h-5 text-neutral-900" />
                </div>
                <h3 className="text-base font-bold text-neutral-900">
                  <FillerText semantic="Leave this game session?" lorem="Exire e ludo currente?" />
                </h3>
                <p className="text-xs text-neutral-600">
                  <FillerText
                    semantic="Your current puzzle attempts will be saved. You can resume anytime before resets at midnight."
                    lorem="Status servabitur usque ad mediam noctem."
                  />
                </p>
                <div className="grid grid-cols-2 gap-2 pt-2">
                  <LoFiButton variant="outline" size="md" onClick={() => setActiveModal(null)}>
                    <FillerText semantic="Keep Playing" lorem="Pergere" />
                  </LoFiButton>
                  <LoFiButton
                    variant="primary"
                    size="md"
                    onClick={() => {
                      setActiveModal(null);
                      onNavigate('8A');
                    }}
                  >
                    <FillerText semantic="Leave Game" lorem="Exire" />
                  </LoFiButton>
                </div>
              </div>
            </div>
          )}

          {activeModal === 'language' && (
            <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
              <div className="bg-white rounded-2xl border border-neutral-300 p-5 max-w-sm w-full space-y-4 shadow-xl">
                <h3 className="text-base font-bold text-neutral-900">
                  <FillerText semantic="Change Target Language?" lorem="Mutare Linguam?" />
                </h3>
                <p className="text-xs text-neutral-600">
                  <FillerText
                    semantic="Starting a new language creates a distinct curriculum track. Your existing progress remains safely archived."
                    lorem="Novus gradus incipietur sine damno pristini."
                  />
                </p>
                <div className="grid grid-cols-2 gap-2 pt-2">
                  <LoFiButton variant="outline" size="md" onClick={() => setActiveModal(null)}>
                    <FillerText semantic="Cancel" lorem="Abrogare" />
                  </LoFiButton>
                  <LoFiButton variant="primary" size="md" onClick={() => setActiveModal(null)}>
                    <FillerText semantic="Confirm Switch" lorem="Confirmare" />
                  </LoFiButton>
                </div>
              </div>
            </div>
          )}

          {activeModal === 'signout' && (
            <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
              <div className="bg-white rounded-2xl border border-neutral-300 p-5 max-w-sm w-full space-y-4 shadow-xl">
                <h3 className="text-base font-bold text-neutral-900">
                  <FillerText semantic="Sign out of account?" lorem="Claudere sessionem?" />
                </h3>
                <p className="text-xs text-neutral-600">
                  <FillerText
                    semantic="Offline cached exercises will stay on this device. Sign back in anytime to sync."
                    lorem="Exercitia localia manebunt."
                  />
                </p>
                <div className="grid grid-cols-2 gap-2 pt-2">
                  <LoFiButton variant="outline" size="md" onClick={() => setActiveModal(null)}>
                    <FillerText semantic="Cancel" lorem="Abrogare" />
                  </LoFiButton>
                  <LoFiButton
                    variant="primary"
                    size="md"
                    onClick={() => {
                      setActiveModal(null);
                      onSignOut();
                    }}
                  >
                    <FillerText semantic="Sign Out" lorem="Claudere" />
                  </LoFiButton>
                </div>
              </div>
            </div>
          )}
        </div>

        <LoFiTabBar activeTab="profile" onSelectTab={onSwitchTab} />
      </div>
    );
  }

  return null;
}
