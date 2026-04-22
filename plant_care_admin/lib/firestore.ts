import {
  collection,
  getDocs,
  getDoc,
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

// ─── Stats ───────────────────────────────────────────────────────────────────

export async function fetchStats(): Promise<StatsOverview> {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfWeek = new Date(startOfToday);
  startOfWeek.setDate(startOfToday.getDate() - 7);

  const todayIso = startOfToday.toISOString();
  const weekIso = startOfWeek.toISOString();

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
    getCountFromServer(query(collection(db, "users"), where("createdAt", ">=", todayIso))),
    getCountFromServer(query(collection(db, "users"), where("createdAt", ">=", weekIso))),
    getCountFromServer(query(collection(db, "users"), where("lastLogin", ">=", todayIso))),
    getCountFromServer(query(collection(db, "users"), where("lastLogin", ">=", weekIso))),
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
    query(collection(db, "users"), where("createdAt", ">=", cutoff.toISOString()))
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
