export type MainTabId = 'daily' | 'progress' | 'friends' | 'settings';

export type FlowId = string;
export type TextMode =
  | 'text-only'
  | 'hybrid-more-text'
  | 'hybrid-balanced'
  | 'hybrid-less-text'
  | 'skeleton-only';
export const FLOWS: {
  id: string;
  number: string;
  name: string;
  description: string;
  screens: { id: string; label: string; sublabel: string }[];
}[] = [];

export type ActiveViewId =
  | 'daily'
  | 'progress'
  | 'friends'
  | 'settings'
  | 'vocab-deck'
  | 'game-connections'
  | 'game-word-guess'
  | 'game-crossword'
  | 'exercise-fill-blank'
  | 'exercise-sentence-builder'
  | 'exercise-definition-match'
  | 'session-review'
  | 'onboarding';

export type DifficultyLevel = 'Easy' | 'Medium' | 'Hard';

export interface VocabWord {
  id: string;
  spanish: string;
  english: string;
  phonetic: string;
  partOfSpeech: 'Connector' | 'Café & Dining' | 'Daily Verb' | 'Culture & Idioms';
  splitType: 'review' | 'new'; // 70% review, 30% new
  mastery: number; // 0-100
  status: 'Mastered' | 'Review';
  exampleEs: string;
  exampleEn: string;
}

export interface SessionReviewData {
  sourceId: ActiveViewId;
  title: string;
  subtitle: string;
  scoreLabel: string;
  accuracy: string;
  timeSpent: string;
  streakEarned: boolean;
  spanishTipTitle: string;
  spanishTipBody: string;
  wordsPracticed: VocabWord[];
  xpEarned?: number;
  pointsScore?: number;
  isNewStreakDay?: boolean;
  leveledUp?: boolean;
  newLevel?: number;
  totalXP?: number;
}

export interface UserStats {
  totalXP: number;
  totalScore: number;
  streakCount: number;
  streakCountedToday: boolean;
  lastActiveDate: string;
}

export interface FriendHighlight {
  id: string;
  userName: string;
  userHandle: string;
  avatarInitials: string;
  avatarBg: string;
  type: 'fill-in' | 'achievement' | 'game-score';
  timestamp: string;
  badgeText: string;
  contentEs?: string;
  contentEn: string;
  likes: number;
  likedByMe?: boolean;
  isCurrentUser?: boolean;
}

export interface LeaderboardEntry {
  rank: number;
  name: string;
  handle: string;
  initials: string;
  streak: number;
  points: number;
  accuracy: string;
  isUser?: boolean;
}

// 10 Daily Spanish Words: 70% Review (7 words) + 30% New (3 words)
// Theme: "La Sobremesa & Café Culture"
export const DAILY_SPANISH_VOCAB: VocabWord[] = [
  {
    id: 'w1',
    spanish: 'la sobremesa',
    english: 'relaxed conversation at the table after a meal',
    phonetic: '/so.βɾeˈme.sa/',
    partOfSpeech: 'Culture & Idioms',
    splitType: 'review',
    mastery: 92,
    status: 'Mastered',
    exampleEs: 'En España, la sobremesa puede durar más de una hora con café.',
    exampleEn: 'In Spain, table talk after a meal can last over an hour with coffee.',
  },
  {
    id: 'w2',
    spanish: 'el cortado',
    english: 'espresso cut with a splash of warm milk',
    phonetic: '/koɾˈta.ðo/',
    partOfSpeech: 'Café & Dining',
    splitType: 'review',
    mastery: 88,
    status: 'Mastered',
    exampleEs: 'Siempre pido un cortado sin azúcar por la tarde.',
    exampleEn: 'I always order an espresso with a splash of milk without sugar in the afternoon.',
  },
  {
    id: 'w3',
    spanish: 'charlar',
    english: 'to chat, to have a casual conversation',
    phonetic: '/tʃaɾˈlaɾ/',
    partOfSpeech: 'Daily Verb',
    splitType: 'review',
    mastery: 85,
    status: 'Mastered',
    exampleEs: 'Nos encanta charlar en la terraza cuando hace sol.',
    exampleEn: 'We love chatting on the terrace when it is sunny.',
  },
  {
    id: 'w4',
    spanish: 'sin embargo',
    english: 'however, nevertheless',
    phonetic: '/sin emˈbaɾ.ɣo/',
    partOfSpeech: 'Connector',
    splitType: 'review',
    mastery: 78,
    status: 'Review',
    exampleEs: 'El café estaba muy caliente; sin embargo, sabía delicioso.',
    exampleEn: 'The coffee was very hot; however, it tasted delicious.',
  },
  {
    id: 'w5',
    spanish: 'la merienda',
    english: 'light late-afternoon snack between lunch and dinner',
    phonetic: '/meˈɾjen.da/',
    partOfSpeech: 'Café & Dining',
    splitType: 'review',
    mastery: 90,
    status: 'Mastered',
    exampleEs: 'Preparamos tostadas y té para la merienda de hoy.',
    exampleEn: 'We prepared toast and tea for today’s afternoon snack.',
  },
  {
    id: 'w6',
    spanish: 'además',
    english: 'furthermore, besides, in addition',
    phonetic: '/a.ðeˈmas/',
    partOfSpeech: 'Connector',
    splitType: 'review',
    mastery: 94,
    status: 'Mastered',
    exampleEs: 'El lugar es tranquilo y, además, tienen pan recién horneado.',
    exampleEn: 'The place is quiet and, besides, they have freshly baked bread.',
  },
  {
    id: 'w7',
    spanish: 'compartir',
    english: 'to share, to divide amongst friends',
    phonetic: '/kom.paɾˈtiɾ/',
    partOfSpeech: 'Daily Verb',
    splitType: 'review',
    mastery: 82,
    status: 'Mastered',
    exampleEs: '¿Quieres compartir una ración de churros conmigo?',
    exampleEn: 'Do you want to share an order of churros with me?',
  },
  {
    id: 'w8',
    spanish: 'acogedor',
    english: 'cozy, welcoming, warm-spirited (place)',
    phonetic: '/a.ko.xeˈðoɾ/',
    partOfSpeech: 'Culture & Idioms',
    splitType: 'new',
    mastery: 45,
    status: 'Review',
    exampleEs: 'Este rincón del café es sumamente acogedor en invierno.',
    exampleEn: 'This corner of the café is extremely cozy in winter.',
  },
  {
    id: 'w9',
    spanish: 'saborear',
    english: 'to savor, to relish a flavor slowly',
    phonetic: '/sa.βo.ɾeˈaɾ/',
    partOfSpeech: 'Daily Verb',
    splitType: 'new',
    mastery: 35,
    status: 'Review',
    exampleEs: 'Tómate tu tiempo para saborear cada sorbo de chocolate.',
    exampleEn: 'Take your time to savor every sip of hot chocolate.',
  },
  {
    id: 'w10',
    spanish: 'a pesar de',
    english: 'despite, in spite of',
    phonetic: '/a peˈsaɾ ðe/',
    partOfSpeech: 'Connector',
    splitType: 'new',
    mastery: 40,
    status: 'Review',
    exampleEs: 'Salimos a caminar a pesar de la lluvia ligera.',
    exampleEn: 'We went out for a walk despite the light rain.',
  },
];
