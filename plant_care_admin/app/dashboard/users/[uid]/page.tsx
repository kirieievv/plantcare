"use client";

import { use, useEffect, useState } from "react";
import {
  fetchUserById,
  fetchPlantsByUser,
  fetchAiUsageByUser,
  fetchHealthChecksByUser,
  fetchMailLogsByEmail,
  fetchFcmTokensByUser,
  fetchPushNotifications,
  summarizeAiUsage,
  updateUserSubscriptionStatus,
  updateUserReminderChannels,
  type AdminUser,
  type AdminPlant,
  type AiUsageRecord,
  type AiCostSummary,
  type HealthCheck,
  type MailLog,
  type FcmToken,
  type PushNotification,
  type SubscriptionStatus,
} from "@/lib/firestore";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import {
  ArrowLeft,
  Leaf,
  MapPin,
  Clock,
  Calendar,
  Sparkles,
  HeartPulse,
  Mail,
  Smartphone,
  CheckCircle2,
  XCircle,
  DollarSign,
  Activity,
  Droplets,
  AlertTriangle,
  Trash2,
  Bell,
} from "lucide-react";
import { format, formatDistanceToNow } from "date-fns";
import Link from "next/link";

function fmtDate(d?: Date) {
  if (!d) return "—";
  return format(d, "MMM d, yyyy HH:mm");
}

function fmtShort(d?: Date) {
  if (!d) return "—";
  return format(d, "MMM d, yyyy");
}

/** The six languages the app ships. Anything else is shown as its raw code
 *  rather than hidden, so a locale we did not expect is visible instead of
 *  looking like no language at all. */
const LANGUAGE_NAMES: Record<string, string> = {
  en: "English",
  ru: "Русский",
  uk: "Українська",
  de: "Deutsch",
  es: "Español",
  fr: "Français",
};

function languageLabel(code?: string) {
  if (!code) return "—";
  return LANGUAGE_NAMES[code] ?? code;
}

function healthBadge(status?: string) {
  if (status === "ok")
    return (
      <Badge className="bg-green-100 text-green-700 text-xs">Healthy</Badge>
    );
  if (status === "issue")
    return (
      <Badge variant="destructive" className="text-xs">
        Issue
      </Badge>
    );
  return (
    <Badge variant="outline" className="text-xs">
      —
    </Badge>
  );
}

function waterBadge(state?: string, muted?: boolean) {
  if (muted)
    return (
      <Badge variant="secondary" className="text-xs">
        Muted
      </Badge>
    );
  if (state === "overdue")
    return (
      <Badge variant="destructive" className="text-xs">
        Overdue
      </Badge>
    );
  if (state === "due")
    return (
      <Badge className="bg-yellow-100 text-yellow-700 text-xs">Due</Badge>
    );
  return (
    <Badge className="bg-green-100 text-green-700 text-xs">On track</Badge>
  );
}

function deliveryBadge(state?: string) {
  if (!state)
    return (
      <Badge variant="secondary" className="text-xs gap-1">
        <Clock className="h-3 w-3" />
        Pending
      </Badge>
    );
  if (state === "SUCCESS")
    return (
      <Badge className="bg-green-100 text-green-700 text-xs gap-1">
        <CheckCircle2 className="h-3 w-3" />
        Sent
      </Badge>
    );
  if (state === "ERROR")
    return (
      <Badge variant="destructive" className="text-xs gap-1">
        <XCircle className="h-3 w-3" />
        Error
      </Badge>
    );
  return (
    <Badge variant="outline" className="text-xs">
      {state}
    </Badge>
  );
}

const TYPE_LABELS: Record<string, string> = {
  health_check: "Health Check",
  chat: "Chat",
  watering_email: "Watering Email",
  plant_analysis: "Plant Analysis",
  plant_identification: "Plant ID",
  seasonal_tips: "Seasonal Tips",
};

function StatMini({
  icon: Icon,
  value,
  label,
  color,
}: {
  icon: React.ElementType;
  value: string | number;
  label: string;
  color: string;
}) {
  return (
    <div className="flex items-center gap-3 rounded-lg border p-3">
      <div
        className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${color}`}
      >
        <Icon className="h-4 w-4" />
      </div>
      <div className="min-w-0">
        <p className="text-lg font-bold leading-tight">{value}</p>
        <p className="text-xs text-muted-foreground truncate">{label}</p>
      </div>
    </div>
  );
}

export default function UserDetailPage({
  params,
}: {
  params: Promise<{ uid: string }>;
}) {
  const { uid } = use(params);
  const [user, setUser] = useState<AdminUser | null>(null);
  const [plants, setPlants] = useState<AdminPlant[]>([]);
  const [aiRecords, setAiRecords] = useState<AiUsageRecord[]>([]);
  const [aiSummary, setAiSummary] = useState<AiCostSummary | null>(null);
  const [healthChecks, setHealthChecks] = useState<HealthCheck[]>([]);
  const [mailLogs, setMailLogs] = useState<MailLog[]>([]);
  const [fcmTokens, setFcmTokens] = useState<FcmToken[]>([]);
  const [pushNotifications, setPushNotifications] = useState<PushNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [activeTab, setActiveTab] = useState<
    "plants" | "health" | "ai" | "emails" | "push"
  >("plants");
  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [updatingReminders, setUpdatingReminders] = useState<"email" | "push" | null>(null);

  async function handleStatusChange(newStatus: SubscriptionStatus) {
    if (!user) return;
    setUpdatingStatus(true);
    try {
      await updateUserSubscriptionStatus(uid, newStatus);
      setUser((u) => u ? { ...u, subscriptionStatus: newStatus } : u);
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : String(e));
    } finally {
      setUpdatingStatus(false);
    }
  }

  async function handleToggleReminder(channel: "email" | "push") {
    if (!user) return;
    const current = channel === "email" ? user.emailReminders : user.pushReminders;
    const newValue = current === false ? true : false;
    setUpdatingReminders(channel);
    try {
      await updateUserReminderChannels(uid, { [channel]: newValue });
      setUser((u) => u ? {
        ...u,
        emailReminders: channel === "email" ? newValue : u.emailReminders,
        pushReminders: channel === "push" ? newValue : u.pushReminders,
      } : u);
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : String(e));
    } finally {
      setUpdatingReminders(null);
    }
  }

  useEffect(() => {
    let cancelled = false;
    setLoading(true);

    fetchUserById(uid).then((u) => {
      if (cancelled || !u) {
        if (!cancelled && !u) setError("User not found");
        setLoading(false);
        return;
      }
      setUser(u);

      Promise.all([
        fetchPlantsByUser(uid),
        fetchAiUsageByUser(uid),
        fetchHealthChecksByUser(uid),
        fetchMailLogsByEmail(u.email),
        fetchFcmTokensByUser(uid),
        fetchPushNotifications(uid),
      ])
        .then(([p, ai, hc, ml, ft, pn]) => {
          if (cancelled) return;
          setPlants(p);
          setAiRecords(ai);
          setAiSummary(summarizeAiUsage(ai));
          setHealthChecks(hc);
          setMailLogs(ml);
          setFcmTokens(ft);
          setPushNotifications(pn);
        })
        .catch((e) => !cancelled && setError(e.message))
        .finally(() => !cancelled && setLoading(false));
    });

    return () => {
      cancelled = true;
    };
  }, [uid]);

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
      </div>
    );
  }

  if (error)
    return <p className="text-sm text-destructive p-4">{error}</p>;
  if (!user)
    return (
      <p className="text-sm text-muted-foreground p-4">User not found.</p>
    );

  const initials =
    user.name
      .split(" ")
      .map((w) => w[0])
      .join("")
      .toUpperCase()
      .slice(0, 2) || user.email[0].toUpperCase();

  const daysSinceRegistration = user.createdAt
    ? Math.floor(
        (Date.now() - user.createdAt.getTime()) / (1000 * 60 * 60 * 24)
      )
    : null;

  const activePlants = plants.filter((p) => !p.deletedAt);
  const deletedPlants = plants.filter((p) => p.deletedAt);
  const overduePlants = activePlants.filter(
    (p) => p.notificationState === "overdue"
  ).length;
  const mutedPlants = activePlants.filter((p) => p.muted).length;
  const emailsSent = mailLogs.filter(
    (l) => l.delivery?.state === "SUCCESS"
  ).length;
  const emailErrors = mailLogs.filter(
    (l) => l.delivery?.state === "ERROR"
  ).length;

  const hcByPlant: Record<string, number> = {};
  for (const hc of healthChecks) {
    hcByPlant[hc.plantId] = (hcByPlant[hc.plantId] || 0) + 1;
  }
  const aiByPlant: Record<string, { cost: number; tokens: number }> = {};
  for (const r of aiRecords) {
    if (!r.plantId) continue;
    if (!aiByPlant[r.plantId])
      aiByPlant[r.plantId] = { cost: 0, tokens: 0 };
    aiByPlant[r.plantId].cost += r.costUsd ?? 0;
    aiByPlant[r.plantId].tokens += r.totalTokens;
  }

  const tabItems = [
    { key: "plants" as const, label: "Plants", count: plants.length, icon: Leaf },
    { key: "health" as const, label: "Health Checks", count: healthChecks.length, icon: HeartPulse },
    { key: "ai" as const, label: "AI Usage", count: aiRecords.length, icon: Sparkles },
    { key: "emails" as const, label: "Emails", count: mailLogs.length, icon: Mail },
    { key: "push" as const, label: "Push", count: fcmTokens.length, icon: Smartphone },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link href="/dashboard/users">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <h1 className="text-2xl font-bold">User Profile</h1>
      </div>

      {/* Profile + Activity cards */}
      <div className="grid gap-4 md:grid-cols-3">
        {/* Profile card */}
        <Card className="md:col-span-1">
          <CardContent className="pt-6">
            <div className="flex flex-col items-center text-center gap-3">
              <Avatar className="h-16 w-16">
                <AvatarFallback className="bg-green-100 text-green-700 text-xl font-bold">
                  {initials}
                </AvatarFallback>
              </Avatar>
              <div className="space-y-1">
                <p className="text-lg font-semibold">{user.name || "—"}</p>
                <p className="text-sm text-muted-foreground">{user.email}</p>
                {user.deletedAt && (
                  <Badge
                    variant="outline"
                    className="border-red-400 text-red-700 text-xs"
                  >
                    Account deleted
                  </Badge>
                )}
                {user.bio && (
                  <p className="text-sm text-muted-foreground italic">
                    &ldquo;{user.bio}&rdquo;
                  </p>
                )}
              </div>
              <div className="flex flex-wrap justify-center gap-2 text-xs text-muted-foreground">
                {user.location && (
                  <span className="flex items-center gap-1">
                    <MapPin className="h-3 w-3" /> {user.location}
                  </span>
                )}
                {user.timezone && (
                  <span className="flex items-center gap-1">
                    <Clock className="h-3 w-3" /> {user.timezone}
                  </span>
                )}
              </div>
              <div className="w-full border-t pt-3 mt-1 space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Registered</span>
                  <span>{fmtShort(user.createdAt)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Last login</span>
                  <span>
                    {user.lastLogin
                      ? formatDistanceToNow(user.lastLogin, {
                          addSuffix: true,
                        })
                      : "—"}
                  </span>
                </div>
                {daysSinceRegistration !== null && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Member for</span>
                    <span>{daysSinceRegistration} days</span>
                  </div>
                )}
                {user.deletedAt && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Deleted</span>
                    <span className="text-red-700">{fmtShort(user.deletedAt)}</span>
                  </div>
                )}
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Language</span>
                  <span>{languageLabel(user.language)}</span>
                </div>
                <div className="flex justify-between items-center gap-2">
                  <span className="text-muted-foreground shrink-0">City</span>
                  {user.geo?.city ? (
                    <span className="text-right">
                      {user.geo.city}
                      {user.geo.country ? `, ${user.geo.country}` : ""}
                      {/* Where it came from decides whether a wrong city is the
                          user's own doing or ours, which is the first thing
                          worth knowing when a schedule looks off. */}
                      <span className="text-muted-foreground text-xs ml-1">
                        {user.geo.source === "manual"
                          ? "· set by user"
                          : user.geo.source === "ip"
                          ? "· from IP"
                          : ""}
                      </span>
                    </span>
                  ) : (
                    <span className="text-muted-foreground text-xs">—</span>
                  )}
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">UID</span>
                  <span className="font-mono text-xs text-muted-foreground">
                    {uid.slice(0, 12)}…
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Email verified</span>
                  {user.emailVerified === true ? (
                    <Badge variant="secondary" className="bg-green-100 text-green-700 text-xs">
                      ✓ Verified
                    </Badge>
                  ) : (
                    <span className="text-muted-foreground text-xs">—</span>
                  )}
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Email reminders</span>
                  {user.emailReminders === null || user.emailReminders === undefined ? (
                    <span className="text-muted-foreground text-xs">—</span>
                  ) : (
                    <button
                      onClick={() => handleToggleReminder("email")}
                      disabled={updatingReminders === "email"}
                      className="focus:outline-none"
                    >
                      <Badge
                        variant="secondary"
                        className={`text-xs cursor-pointer transition-opacity ${updatingReminders === "email" ? "opacity-50" : ""} ${user.emailReminders ? "bg-green-100 text-green-700 hover:bg-green-200" : "bg-red-100 text-red-600 hover:bg-red-200"}`}
                      >
                        {user.emailReminders ? "ON" : "OFF"}
                      </Badge>
                    </button>
                  )}
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Push reminders</span>
                  {user.pushReminders === null || user.pushReminders === undefined ? (
                    <span className="text-muted-foreground text-xs">—</span>
                  ) : (
                    <button
                      onClick={() => handleToggleReminder("push")}
                      disabled={updatingReminders === "push"}
                      className="focus:outline-none"
                    >
                      <Badge
                        variant="secondary"
                        className={`text-xs cursor-pointer transition-opacity ${updatingReminders === "push" ? "opacity-50" : ""} ${user.pushReminders ? "bg-green-100 text-green-700 hover:bg-green-200" : "bg-red-100 text-red-600 hover:bg-red-200"}`}
                      >
                        {user.pushReminders ? "ON" : "OFF"}
                      </Badge>
                    </button>
                  )}
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted-foreground">Subscription</span>
                  <Select
                    value={user.subscriptionStatus || "trial"}
                    onValueChange={(v) => handleStatusChange(v as SubscriptionStatus)}
                    disabled={updatingStatus}
                  >
                    <SelectTrigger className="h-7 w-auto text-sm border-0 p-0 shadow-none focus:ring-0 justify-end gap-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent align="end">
                      <SelectItem value="trial">Trial</SelectItem>
                      <SelectItem value="active">Premium</SelectItem>
                      <SelectItem value="expired">Expired</SelectItem>
                      <SelectItem value="grandfathered">Forever Premium</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Stats grid */}
        <div className="md:col-span-2 grid grid-cols-2 lg:grid-cols-3 gap-3">
          <StatMini
            icon={Leaf}
            value={`${activePlants.length}${deletedPlants.length > 0 ? ` / ${deletedPlants.length} del` : ""}`}
            label={`Plants${deletedPlants.length > 0 ? " (active / deleted)" : ""}`}
            color="bg-green-100 text-green-600"
          />
          <StatMini
            icon={HeartPulse}
            value={healthChecks.length}
            label="Health checks"
            color="bg-blue-100 text-blue-600"
          />
          <StatMini
            icon={DollarSign}
            value={aiSummary ? `$${aiSummary.totalCostUsd.toFixed(4)}` : "$0"}
            label="AI spend"
            color="bg-purple-100 text-purple-600"
          />
          <StatMini
            icon={Sparkles}
            value={
              aiSummary ? aiSummary.totalTokens.toLocaleString() : "0"
            }
            label="AI tokens"
            color="bg-orange-100 text-orange-600"
          />
          <StatMini
            icon={Mail}
            value={`${emailsSent}${emailErrors > 0 ? ` / ${emailErrors} err` : ""}`}
            label={`Emails sent${mailLogs.length > 0 ? ` (${mailLogs.length} total)` : ""}`}
            color="bg-sky-100 text-sky-600"
          />
          <StatMini
            icon={Smartphone}
            value={fcmTokens.length}
            label="Push devices"
            color="bg-pink-100 text-pink-600"
          />
          {overduePlants > 0 && (
            <StatMini
              icon={Droplets}
              value={overduePlants}
              label="Overdue watering"
              color="bg-red-100 text-red-600"
            />
          )}
          {mutedPlants > 0 && (
            <StatMini
              icon={AlertTriangle}
              value={mutedPlants}
              label="Muted plants"
              color="bg-yellow-100 text-yellow-600"
            />
          )}
          <StatMini
            icon={Activity}
            value={
              healthChecks.length && plants.length
                ? (healthChecks.length / plants.length).toFixed(1)
                : "0"
            }
            label="Avg checks/plant"
            color="bg-emerald-100 text-emerald-600"
          />
        </div>
      </div>

      {/* Tab navigation */}
      <div className="flex gap-1 border-b">
        {tabItems.map((t) => (
          <button
            key={t.key}
            onClick={() => setActiveTab(t.key)}
            className={`flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium transition-colors border-b-2 -mb-px ${
              activeTab === t.key
                ? "border-green-600 text-green-700"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            <t.icon className="h-4 w-4" />
            {t.label}
            <Badge
              variant="secondary"
              className="ml-1 h-5 px-1.5 text-xs"
            >
              {t.count}
            </Badge>
          </button>
        ))}
      </div>

      {/* ── Plants tab ──────────────────────────────────────── */}
      {activeTab === "plants" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              Plants ({activePlants.length} active{deletedPlants.length > 0 ? `, ${deletedPlants.length} deleted` : ""})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {plants.length === 0 ? (
              <p className="p-6 text-sm text-muted-foreground text-center">
                No plants yet.
              </p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Plant
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Species
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Health
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Watering
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-center">
                      Checks
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">
                      AI Cost
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Next due
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Added
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {plants.map((p) => {
                    const checks = hcByPlant[p.id] || 0;
                    const ai = aiByPlant[p.id];
                    const deleted = !!p.deletedAt;
                    return (
                      <TableRow key={p.id} className={`hover:bg-muted/50 ${deleted ? "opacity-50 bg-red-50/30" : ""}`}>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            {p.imageUrl ? (
                              <img
                                src={p.imageUrl}
                                alt={p.name}
                                className={`h-8 w-8 rounded-md object-cover ${deleted ? "grayscale" : ""}`}
                              />
                            ) : (
                              <div className={`h-8 w-8 rounded-md flex items-center justify-center ${deleted ? "bg-red-100" : "bg-green-100"}`}>
                                {deleted ? (
                                  <Trash2 className="h-4 w-4 text-red-400" />
                                ) : (
                                  <Leaf className="h-4 w-4 text-green-600" />
                                )}
                              </div>
                            )}
                            <div>
                              <span className={`font-medium text-sm ${deleted ? "line-through text-muted-foreground" : ""}`}>
                                {p.name}
                              </span>
                              {deleted && (
                                <p className="text-xs text-red-500">
                                  Deleted {p.deletedAt ? format(p.deletedAt, "MMM d, yyyy") : ""}
                                </p>
                              )}
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {p.species || "—"}
                        </TableCell>
                        <TableCell>
                          {deleted ? (
                            <Badge variant="destructive" className="text-xs">Deleted</Badge>
                          ) : (
                            healthBadge(p.healthStatus)
                          )}
                        </TableCell>
                        <TableCell>
                          {deleted ? (
                            <span className="text-muted-foreground text-xs">—</span>
                          ) : (
                            waterBadge(p.notificationState, p.muted)
                          )}
                        </TableCell>
                        <TableCell className="text-center text-sm">
                          {checks > 0 ? (
                            <span className="font-medium">{checks}</span>
                          ) : (
                            <span className="text-muted-foreground">—</span>
                          )}
                        </TableCell>
                        <TableCell className="text-right text-xs">
                          {ai ? (
                            <span className="font-mono">
                              ${ai.cost.toFixed(4)}
                              <span className="ml-1 text-muted-foreground">
                                ({ai.tokens.toLocaleString()})
                              </span>
                            </span>
                          ) : (
                            <span className="text-muted-foreground">—</span>
                          )}
                        </TableCell>
                        <TableCell className="text-xs">
                          {p.nextDueAt
                            ? format(p.nextDueAt, "MMM d, HH:mm")
                            : "—"}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {fmtShort(p.createdAt)}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      )}

      {/* ── Health Checks tab ───────────────────────────────── */}
      {activeTab === "health" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <HeartPulse className="h-4 w-4 text-blue-500" />
              Health Checks ({healthChecks.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {healthChecks.length === 0 ? (
              <p className="p-6 text-sm text-muted-foreground text-center">
                No health checks yet.
              </p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Plant
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Status
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">
                      Cost
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Date
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {healthChecks.map((hc) => {
                    const aiMatch = aiRecords.find(
                      (r) =>
                        r.type === "health_check" &&
                        r.plantId === hc.plantId &&
                        r.timestamp &&
                        hc.createdAt &&
                        Math.abs(
                          r.timestamp.getTime() - hc.createdAt.getTime()
                        ) < 300_000
                    );
                    return (
                      <TableRow key={hc.id} className="hover:bg-muted/50">
                        <TableCell className="text-sm">
                          {hc.plantName || hc.plantId.slice(0, 12) + "…"}
                        </TableCell>
                        <TableCell>{healthBadge(hc.status)}</TableCell>
                        <TableCell className="text-right text-xs">
                          {aiMatch ? (
                            <span className="font-mono">
                              ${aiMatch.costUsd?.toFixed(4) ?? "?"}
                              <span className="ml-1 text-muted-foreground">
                                ({aiMatch.totalTokens.toLocaleString()})
                              </span>
                            </span>
                          ) : (
                            <span className="text-muted-foreground">—</span>
                          )}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {fmtDate(hc.createdAt)}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      )}

      {/* ── AI Usage tab ────────────────────────────────────── */}
      {activeTab === "ai" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-purple-500" />
              AI Usage — $
              {aiSummary?.totalCostUsd.toFixed(4) ?? "0"} total (
              {aiSummary?.totalTokens.toLocaleString() ?? "0"} tokens)
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {aiRecords.length === 0 ? (
              <p className="p-6 text-sm text-muted-foreground text-center">
                No AI usage records.
              </p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Type
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Model
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Plant
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">
                      In
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">
                      Out
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">
                      Cost
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Date
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {aiRecords.map((r) => {
                    const plant = r.plantId
                      ? plants.find((p) => p.id === r.plantId)
                      : null;
                    return (
                      <TableRow key={r.id} className="hover:bg-muted/50">
                        <TableCell>
                          <Badge variant="outline" className="text-xs">
                            {TYPE_LABELS[r.type] ?? r.type}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {r.model}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {plant?.name || (r.plantId ? r.plantId.slice(0, 10) + "…" : "—")}
                        </TableCell>
                        <TableCell className="text-right text-xs">
                          {r.inputTokens.toLocaleString()}
                        </TableCell>
                        <TableCell className="text-right text-xs">
                          {r.outputTokens.toLocaleString()}
                        </TableCell>
                        <TableCell className="text-right text-xs font-mono">
                          {r.costUsd != null
                            ? `$${r.costUsd.toFixed(5)}`
                            : "—"}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {r.timestamp
                            ? format(r.timestamp, "MMM d, HH:mm")
                            : "—"}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      )}

      {/* ── Emails tab ──────────────────────────────────────── */}
      {activeTab === "emails" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Mail className="h-4 w-4 text-sky-500" />
              Email Notifications ({mailLogs.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {mailLogs.length === 0 ? (
              <p className="p-6 text-sm text-muted-foreground text-center">
                No emails sent to this user.
              </p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Subject
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Status
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Attempts
                    </TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                      Date
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {mailLogs.map((log) => (
                    <TableRow key={log.id} className="hover:bg-muted/50">
                      <TableCell className="text-sm max-w-xs truncate">
                        {log.subject || "—"}
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-col gap-1">
                          {deliveryBadge(log.delivery?.state)}
                          {log.delivery?.error && (
                            <p className="text-xs text-destructive max-w-[220px] break-words leading-tight">
                              {log.delivery.error}
                            </p>
                          )}
                        </div>
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {log.delivery?.attempts ?? "—"}
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {fmtDate(log.createdAt)}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      )}

      {/* ── Push Tokens tab ─────────────────────────────────── */}
      {activeTab === "push" && (
        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Smartphone className="h-4 w-4 text-pink-500" />
                Push Devices ({fcmTokens.length})
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {fcmTokens.length === 0 ? (
                <p className="p-6 text-sm text-muted-foreground text-center">
                  No push tokens registered.
                </p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                        Token (truncated)
                      </TableHead>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                        Platform
                      </TableHead>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                        Registered
                      </TableHead>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">
                        Updated
                      </TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {fcmTokens.map((t) => (
                      <TableRow key={t.id} className="hover:bg-muted/50">
                        <TableCell className="font-mono text-xs text-muted-foreground">
                          {t.token.slice(0, 24)}…
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline" className="text-xs">
                            {t.platform || "iOS"}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {fmtShort(t.createdAt)}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {fmtShort(t.updatedAt)}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Bell className="h-4 w-4 text-pink-500" />
                Notification History ({pushNotifications.length})
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {pushNotifications.length === 0 ? (
                <p className="p-6 text-sm text-muted-foreground text-center">
                  No push notifications sent yet (logging started after Jul 29, 2026).
                </p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground w-36">Date</TableHead>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground w-28">Plant</TableHead>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground w-20">Stage</TableHead>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground w-32">Delivered</TableHead>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Title</TableHead>
                      <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Body</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {pushNotifications.map((n) => (
                      <TableRow key={n.id} className="hover:bg-muted/50 align-top">
                        <TableCell className="text-xs text-muted-foreground whitespace-nowrap">
                          {fmtShort(n.sentAt)}
                        </TableCell>
                        <TableCell className="text-xs font-medium">
                          {n.plantName || "—"}
                        </TableCell>
                        <TableCell>
                          <Badge
                            variant="outline"
                            className={`text-xs ${n.stage === "first_reminder" ? "border-green-400 text-green-700" : "border-orange-400 text-orange-700"}`}
                          >
                            {n.stage === "first_reminder" ? "pre" : n.stage === "followup_reminder" ? "post" : n.stage || "—"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {n.successCount > 0 ? (
                            <span className="text-xs text-muted-foreground whitespace-nowrap">
                              {n.successCount} {n.successCount === 1 ? "device" : "devices"}
                              {n.failureCount > 0 ? `, ${n.failureCount} failed` : ""}
                            </span>
                          ) : (
                            <Badge
                              variant="outline"
                              className="text-xs border-red-400 text-red-700 max-w-[160px] truncate"
                              title={n.error || undefined}
                            >
                              {n.error || "not delivered"}
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-xs font-medium max-w-[200px]">
                          {n.title}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground max-w-[300px]">
                          {n.body}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
