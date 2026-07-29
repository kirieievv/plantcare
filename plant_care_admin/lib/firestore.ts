import {
  collection,
  getDocs,
  getDoc,
  setDoc,
  updateDoc,
  doc,
  query,
  orderBy,
  limit,
  where,
  Timestamp,
  getCountFromServer,
  startAfter,
  DocumentSnapshot,
} from "firebase/firestore";
import { db } from "./firebase";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface AdminUser {
  uid: string;
  email: string;
  name: string;
  bio?: string;
  location?: string;
  createdAt?: Date;
  lastLogin?: Date;
  timezone?: string;
  plantCount?: number;
  aiCostUsd?: number;
  aiTotalTokens?: number;
  subscriptionStatus?: string;
  subscriptionExpiresAt?: Date;
  emailReminders?: boolean | null;
  pushReminders?: boolean | null;
  emailVerified?: boolean | null;
}

export interface AdminPlant {
  id: string;
  name: string;
  species: string;
  userId: string;
  userEmail?: string;
  userName?: string;
  imageUrl?: string;
  createdAt?: Date;
  lastWateredAt?: Date;
  nextDueAt?: Date;
  healthStatus?: string;
  wateringFrequency?: number;
  notificationState?: string;
  muted?: boolean;
  deletedAt?: Date;
}

export interface StatsOverview {
  totalUsers: number;
  totalPlants: number;
  newUsersToday: number;
  newUsersThisWeek: number;
  activeToday: number;
  activeThisWeek: number;
  plantsWithIssues: number;
  mutedPlants: number;
}

export interface MailLog {
  id: string;
  to: string;
  subject?: string;
  createdAt?: Date;
  delivery?: {
    state?: string;
    attempts?: number;
    error?: string;
  };
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function toDate(v: unknown): Date | undefined {
  if (!v) return undefined;
  if (v instanceof Timestamp) return v.toDate();
  if (v instanceof Date) return v;
  if (typeof v === "string") {
    const d = new Date(v);
    return isNaN(d.getTime()) ? undefined : d;
  }
  return undefined;
}

// ─── Users ───────────────────────────────────────────────────────────────────

export async function fetchUsers(): Promise<AdminUser[]> {
  const snap = await getDocs(
    query(collection(db, "users"), orderBy("createdAt", "desc"))
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      uid: data.uid || d.id,
      email: data.email || "",
      name: data.name || "",
      bio: data.bio,
      location: data.location,
      createdAt: toDate(data.createdAt),
      lastLogin: toDate(data.lastLogin),
      timezone: data.timezone,
      subscriptionStatus: (data.subscriptionStatus as string) || "trial",
      subscriptionExpiresAt: toDate(data.subscriptionExpiresAt),
      emailReminders: data.wateringReminderChannels != null
        ? (data.wateringReminderChannels.email !== false)
        : null,
      pushReminders: data.wateringReminderChannels != null
        ? (data.wateringReminderChannels.push !== false)
        : null,
      emailVerified: data.emailVerified === true ? true
        : data.emailVerified === false ? false
        : null,
    };
  });
}

export async function fetchUserById(uid: string): Promise<AdminUser | null> {
  const snap = await getDoc(doc(db, "users", uid));
  if (!snap.exists()) return null;
  const data = snap.data();
  return {
    uid: data.uid || snap.id,
    email: data.email || "",
    name: data.name || "",
    bio: data.bio,
    location: data.location,
    createdAt: toDate(data.createdAt),
    lastLogin: toDate(data.lastLogin),
    timezone: data.timezone,
    emailReminders: data.wateringReminderChannels != null
      ? (data.wateringReminderChannels.email !== false)
      : null,
    pushReminders: data.wateringReminderChannels != null
      ? (data.wateringReminderChannels.push !== false)
      : null,
    emailVerified: data.emailVerified === true ? true
      : data.emailVerified === false ? false
      : null,
  };
}

// ─── Plants ──────────────────────────────────────────────────────────────────

export async function fetchPlants(pageSize = 100, after?: DocumentSnapshot): Promise<AdminPlant[]> {
  let q = query(
    collection(db, "plants"),
    orderBy("createdAt", "desc"),
    limit(pageSize)
  );
  if (after) q = query(q, startAfter(after));
  const snap = await getDocs(q);
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      name: data.name || "",
      species: data.species || "",
      userId: data.userId || "",
      imageUrl: data.imageUrl,
      createdAt: toDate(data.createdAt),
      lastWateredAt: toDate(data.lastWateredAt || data.lastWatered),
      nextDueAt: toDate(data.nextDueAt || data.nextWatering),
      healthStatus: data.healthStatus,
      wateringFrequency: data.wateringIntervalDays || data.wateringFrequency,
      notificationState: data.notificationState,
      muted: data.muted === true,
    };
  });
}

export async function fetchPlantsByUser(userId: string): Promise<AdminPlant[]> {
  const snap = await getDocs(
    query(collection(db, "plants"), where("userId", "==", userId))
  );
  const plants = snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      name: data.name || "",
      species: data.species || "",
      userId: data.userId || "",
      imageUrl: data.imageUrl,
      createdAt: toDate(data.createdAt),
      lastWateredAt: toDate(data.lastWateredAt || data.lastWatered),
      nextDueAt: toDate(data.nextDueAt || data.nextWatering),
      healthStatus: data.healthStatus,
      wateringFrequency: data.wateringIntervalDays || data.wateringFrequency,
      notificationState: data.notificationState,
      muted: data.muted === true,
      deletedAt: toDate(data.deletedAt),
    };
  });
  plants.sort((a, b) => {
    if (a.deletedAt && !b.deletedAt) return 1;
    if (!a.deletedAt && b.deletedAt) return -1;
    return (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0);
  });
  return plants;
}

// ─── Stats ───────────────────────────────────────────────────────────────────

export async function fetchStats(): Promise<StatsOverview> {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfWeek = new Date(startOfToday);
  startOfWeek.setDate(startOfToday.getDate() - 7);

  const todayTs = Timestamp.fromDate(startOfToday);
  const weekTs = Timestamp.fromDate(startOfWeek);

  const [
    totalUsersSnap,
    totalPlantsSnap,
    newUsersTodaySnap,
    newUsersWeekSnap,
    activeTodaySnap,
    activeWeekSnap,
    plantsIssuesSnap,
    mutedPlantsSnap,
  ] = await Promise.all([
    getCountFromServer(collection(db, "users")),
    getCountFromServer(collection(db, "plants")),
    getCountFromServer(query(collection(db, "users"), where("createdAt", ">=", todayTs))),
    getCountFromServer(query(collection(db, "users"), where("createdAt", ">=", weekTs))),
    getCountFromServer(query(collection(db, "users"), where("lastLogin", ">=", todayTs))),
    getCountFromServer(query(collection(db, "users"), where("lastLogin", ">=", weekTs))),
    getCountFromServer(query(collection(db, "plants"), where("healthStatus", "==", "issue"))),
    getCountFromServer(query(collection(db, "plants"), where("muted", "==", true))),
  ]);

  return {
    totalUsers: totalUsersSnap.data().count,
    totalPlants: totalPlantsSnap.data().count,
    newUsersToday: newUsersTodaySnap.data().count,
    newUsersThisWeek: newUsersWeekSnap.data().count,
    activeToday: activeTodaySnap.data().count,
    activeThisWeek: activeWeekSnap.data().count,
    plantsWithIssues: plantsIssuesSnap.data().count,
    mutedPlants: mutedPlantsSnap.data().count,
  };
}

export async function fetchNewUsersLast30Days(): Promise<{ date: string; count: number }[]> {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 29);
  cutoff.setHours(0, 0, 0, 0);

  const snap = await getDocs(
    query(collection(db, "users"), where("createdAt", ">=", Timestamp.fromDate(cutoff)))
  );

  const counts: Record<string, number> = {};
  snap.docs.forEach((d) => {
    const created = toDate(d.data().createdAt);
    if (!created) return;
    const key = created.toISOString().slice(0, 10);
    counts[key] = (counts[key] || 0) + 1;
  });

  const result: { date: string; count: number }[] = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    result.push({ date: key, count: counts[key] || 0 });
  }
  return result;
}

// ─── AI Usage ────────────────────────────────────────────────────────────────

export interface AiUsageRecord {
  id: string;
  userId: string | null;
  plantId: string | null;
  type: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  costUsd: number | null;
  timestamp?: Date;
}

export interface AiCostSummary {
  totalCostUsd: number;
  totalTokens: number;
  byType: Record<string, { cost: number; tokens: number; count: number }>;
}

export interface AiTotals {
  totalCalls: number;
  totalCostUsd: number;
  totalTokens: number;
}

export interface AiDailyRecord {
  date: string;
  totalCalls: number;
  totalCostUsd: number;
  totalTokens: number;
  byType: Record<string, { calls: number; cost: number; tokens: number }>;
}

/** Accurate all-time totals from system/ai_totals document (updated by saveAiUsage via increment). */
export async function fetchAiTotals(): Promise<AiTotals> {
  const snap = await getDoc(doc(db, "system", "ai_totals"));
  if (!snap.exists()) return { totalCalls: 0, totalCostUsd: 0, totalTokens: 0 };
  const data = snap.data();
  return {
    totalCalls: data.totalCalls ?? 0,
    totalCostUsd: data.totalCostUsd ?? 0,
    totalTokens: data.totalTokens ?? 0,
  };
}

/** Daily aggregates from ai_usage_daily collection (written by Firebase Function). */
export async function fetchAiDailyStats(days = 30): Promise<AiDailyRecord[]> {
  const snap = await getDocs(
    query(collection(db, "ai_usage_daily"), orderBy("date", "asc"), limit(90))
  );

  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days + 1);
  const cutoffStr = cutoff.toISOString().slice(0, 10);

  const byDate: Record<string, AiDailyRecord> = {};
  snap.docs.forEach((d) => {
    if (d.id >= cutoffStr) {
      const data = d.data();
      byDate[d.id] = {
        date: d.id,
        totalCalls: data.totalCalls ?? 0,
        totalCostUsd: data.totalCostUsd ?? 0,
        totalTokens: data.totalTokens ?? 0,
        byType: data.byType ?? {},
      };
    }
  });

  const result: AiDailyRecord[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    result.push(byDate[key] ?? { date: key, totalCalls: 0, totalCostUsd: 0, totalTokens: 0, byType: {} });
  }
  return result;
}

export async function fetchAiUsage(limitN = 500): Promise<AiUsageRecord[]> {
  const snap = await getDocs(
    query(collection(db, "ai_usage"), orderBy("timestamp", "desc"), limit(limitN))
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: data.userId ?? null,
      plantId: data.plantId ?? null,
      type: data.type || "unknown",
      model: data.model || "",
      inputTokens: data.inputTokens || 0,
      outputTokens: data.outputTokens || 0,
      totalTokens: data.totalTokens || 0,
      costUsd: data.costUsd ?? null,
      timestamp: toDate(data.timestamp),
    };
  });
}

export async function fetchAiUsageByUser(userId: string): Promise<AiUsageRecord[]> {
  const snap = await getDocs(
    query(
      collection(db, "ai_usage"),
      where("userId", "==", userId),
    )
  );
  const records = snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: data.userId ?? null,
      plantId: data.plantId ?? null,
      type: data.type || "unknown",
      model: data.model || "",
      inputTokens: data.inputTokens || 0,
      outputTokens: data.outputTokens || 0,
      totalTokens: data.totalTokens || 0,
      costUsd: data.costUsd ?? null,
      timestamp: toDate(data.timestamp),
    };
  });
  records.sort((a, b) => (b.timestamp?.getTime() ?? 0) - (a.timestamp?.getTime() ?? 0));
  return records;
}

export function summarizeAiUsage(records: AiUsageRecord[]): AiCostSummary {
  const byType: AiCostSummary["byType"] = {};
  let totalCostUsd = 0;
  let totalTokens = 0;
  for (const r of records) {
    const cost = r.costUsd ?? 0;
    totalCostUsd += cost;
    totalTokens += r.totalTokens;
    if (!byType[r.type]) byType[r.type] = { cost: 0, tokens: 0, count: 0 };
    byType[r.type].cost += cost;
    byType[r.type].tokens += r.totalTokens;
    byType[r.type].count += 1;
  }
  return { totalCostUsd, totalTokens, byType };
}

export async function fetchAiCostPerUser(): Promise<Map<string, { cost: number; tokens: number }>> {
  const snap = await getDocs(collection(db, "ai_usage"));
  const map = new Map<string, { cost: number; tokens: number }>();
  for (const d of snap.docs) {
    const data = d.data();
    const uid = data.userId;
    if (!uid || uid === "system") continue;
    const prev = map.get(uid) || { cost: 0, tokens: 0 };
    prev.cost += data.costUsd ?? 0;
    prev.tokens += data.totalTokens ?? 0;
    map.set(uid, prev);
  }
  return map;
}

// ─── Health Checks ───────────────────────────────────────────────────────────

export interface HealthCheck {
  id: string;
  userId: string;
  plantId: string;
  plantName?: string;
  status?: string;
  createdAt?: Date;
  imageUrl?: string;
}

export async function fetchHealthChecks(limitN = 200): Promise<HealthCheck[]> {
  const snap = await getDocs(
    query(collection(db, "health_checks"), orderBy("createdAt", "desc"), limit(limitN))
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: data.userId || "",
      plantId: data.plantId || "",
      plantName: data.plantName,
      status: data.status,
      createdAt: toDate(data.createdAt),
      imageUrl: data.imageUrl,
    };
  });
}

export async function fetchHealthChecksByUser(userId: string): Promise<HealthCheck[]> {
  const snap = await getDocs(
    query(
      collection(db, "health_checks"),
      where("userId", "==", userId),
    )
  );
  const records = snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: data.userId || "",
      plantId: data.plantId || "",
      plantName: data.plantName,
      status: data.status,
      createdAt: toDate(data.createdAt),
      imageUrl: data.imageUrl,
    };
  });
  records.sort((a, b) => (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0));
  return records;
}

export async function fetchMailLogsByEmail(email: string): Promise<MailLog[]> {
  const snap = await getDocs(
    query(collection(db, "mail"), where("to", "==", email))
  );
  const records = snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      to: data.to || "",
      subject: data.message?.subject || data.subject || "",
      createdAt: toDate(data.delivery?.startTime || data.createdAt),
      delivery: data.delivery,
    };
  });
  records.sort((a, b) => (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0));
  return records;
}

export async function fetchFcmTokensByUser(userId: string): Promise<FcmToken[]> {
  const snap = await getDocs(
    query(collection(db, "fcm_tokens"), where("userId", "==", userId))
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: data.userId || "",
      token: data.token || d.id,
      createdAt: toDate(data.createdAt),
      updatedAt: toDate(data.updatedAt),
      platform: data.platform,
    };
  });
}

// ─── Seasonal Tips ────────────────────────────────────────────────────────────

export interface SeasonalTipWeek {
  weekKey: string;
  weekStart?: string;
  season?: string;
  month?: string;
  generatedAt?: Date;
  model?: string;
  usage?: { prompt_tokens: number; completion_tokens: number; total_tokens: number };
  estimatedCostUsd?: number | null;
  tips: SeasonalTip[];
}

export interface SeasonalTip {
  index: number;
  en: string;
  de: string;
  es: string;
  fr: string;
  category: string;
}

export async function fetchSeasonalTipWeeks(limitN = 12): Promise<SeasonalTipWeek[]> {
  const snap = await getDocs(
    query(collection(db, "seasonal_tips"), orderBy("generatedAt", "desc"), limit(limitN))
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      weekKey: d.id,
      weekStart: data.weekStart,
      season: data.season,
      month: data.month,
      generatedAt: toDate(data.generatedAt),
      model: data.model,
      usage: data.usage,
      estimatedCostUsd: data.estimatedCostUsd ?? null,
      tips: (data.tips || []).map((t: Record<string, unknown>, i: number) => ({
        index: typeof t.index === "number" ? t.index : i,
        en: (t.en as string) || "",
        de: (t.de as string) || "",
        es: (t.es as string) || "",
        fr: (t.fr as string) || "",
        category: (t.category as string) || "general",
      })),
    };
  });
}

export async function fetchSeasonalTipWeek(weekKey: string): Promise<SeasonalTipWeek | null> {
  const snap = await getDoc(doc(db, "seasonal_tips", weekKey));
  if (!snap.exists()) return null;
  const data = snap.data();
  return {
    weekKey: snap.id,
    weekStart: data.weekStart,
    season: data.season,
    month: data.month,
    generatedAt: toDate(data.generatedAt),
    model: data.model,
    usage: data.usage,
    estimatedCostUsd: data.estimatedCostUsd ?? null,
    tips: (data.tips || []).map((t: Record<string, unknown>, i: number) => ({
      index: typeof t.index === "number" ? t.index : i,
      en: (t.en as string) || "",
      de: (t.de as string) || "",
      es: (t.es as string) || "",
      fr: (t.fr as string) || "",
      category: (t.category as string) || "general",
    })),
  };
}

// ─── Subscription Config ─────────────────────────────────────────────────────

export interface SubscriptionConfig {
  trial_days: number;
  trial_plant_limit: number;
  subscription_plant_limit: number;
  grandfathered_cutoff_date: string;
}

export type SubscriptionStatus = "trial" | "active" | "expired" | "grandfathered";

export async function fetchSubscriptionConfig(): Promise<SubscriptionConfig> {
  const snap = await getDoc(doc(db, "app_config", "subscription"));
  if (!snap.exists()) {
    return {
      trial_days: 14,
      trial_plant_limit: 1,
      subscription_plant_limit: 10,
      grandfathered_cutoff_date: new Date().toISOString(),
    };
  }
  return snap.data() as SubscriptionConfig;
}

export async function saveSubscriptionConfig(config: SubscriptionConfig): Promise<void> {
  await setDoc(doc(db, "app_config", "subscription"), config);
}

export async function fetchUserSubscriptionStatus(uid: string): Promise<{
  status: SubscriptionStatus;
  expiresAt?: Date;
} | null> {
  const snap = await getDoc(doc(db, "users", uid));
  if (!snap.exists()) return null;
  const data = snap.data();
  return {
    status: (data.subscriptionStatus as SubscriptionStatus) || "trial",
    expiresAt: toDate(data.subscriptionExpiresAt),
  };
}

export async function updateUserSubscriptionStatus(
  uid: string,
  status: SubscriptionStatus
): Promise<void> {
  await updateDoc(doc(db, "users", uid), { subscriptionStatus: status });
}

export async function updateUserReminderChannels(
  uid: string,
  channels: { email?: boolean; push?: boolean }
): Promise<void> {
  const update: Record<string, boolean> = {};
  if (channels.email !== undefined) update["wateringReminderChannels.email"] = channels.email;
  if (channels.push !== undefined) update["wateringReminderChannels.push"] = channels.push;
  await updateDoc(doc(db, "users", uid), update);
}

export async function fetchUsersBySubscriptionStatus(
  status: SubscriptionStatus | "all",
  limitN = 200
): Promise<AdminUser[]> {
  const q = status === "all"
    ? query(collection(db, "users"), orderBy("createdAt", "desc"), limit(limitN))
    : query(collection(db, "users"), where("subscriptionStatus", "==", status), limit(limitN));
  const snap = await getDocs(q);
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      uid: data.uid || d.id,
      email: data.email || "",
      name: data.name || "",
      bio: data.bio,
      location: data.location,
      createdAt: toDate(data.createdAt),
      lastLogin: toDate(data.lastLogin),
      timezone: data.timezone,
      subscriptionStatus: (data.subscriptionStatus as SubscriptionStatus) || "trial",
      subscriptionExpiresAt: toDate(data.subscriptionExpiresAt),
    };
  });
}

// ─── Push Tokens ─────────────────────────────────────────────────────────────

export interface FcmToken {
  id: string;
  userId: string;
  token: string;
  userEmail?: string;
  userName?: string;
  createdAt?: Date;
  updatedAt?: Date;
  platform?: string;
}

export async function fetchFcmTokens(): Promise<FcmToken[]> {
  const snap = await getDocs(collection(db, "fcm_tokens"));
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: data.userId || "",
      token: data.token || d.id,
      createdAt: toDate(data.createdAt),
      updatedAt: toDate(data.updatedAt),
      platform: data.platform,
    };
  });
}

// ─── Mail Logs ────────────────────────────────────────────────────────────────

export async function fetchMailLogs(pageSize = 50): Promise<MailLog[]> {
  const snap = await getDocs(
    query(collection(db, "mail"), orderBy("delivery.startTime", "desc"), limit(pageSize))
  );

  if (snap.empty) {
    const snap2 = await getDocs(
      query(collection(db, "mail"), limit(pageSize))
    );
    return snap2.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        to: data.to || "",
        subject: data.message?.subject || data.subject || "",
        createdAt: toDate(data.delivery?.startTime || data.createdAt),
        delivery: data.delivery,
      };
    });
  }

  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      to: data.to || "",
      subject: data.message?.subject || data.subject || "",
      createdAt: toDate(data.delivery?.startTime || data.createdAt),
      delivery: data.delivery,
    };
  });
}

// ─── Push Notifications History ──────────────────────────────────────────────

export interface PushNotification {
  id: string;
  userId: string;
  plantId: string | null;
  plantName: string | null;
  title: string;
  body: string;
  stage: string | null;
  successCount: number;
  sentAt?: Date;
}

export async function fetchPushNotifications(userId: string): Promise<PushNotification[]> {
  const snap = await getDocs(
    query(
      collection(db, "push_notifications"),
      where("userId", "==", userId),
      orderBy("sentAt", "desc"),
      limit(100)
    )
  );
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: data.userId || userId,
      plantId: data.plantId || null,
      plantName: data.plantName || null,
      title: data.title || "",
      body: data.body || "",
      stage: data.stage || null,
      successCount: data.successCount ?? 1,
      sentAt: toDate(data.sentAt),
    };
  });
}
