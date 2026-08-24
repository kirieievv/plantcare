"use client";

/**
 * The four things that can stop working without anyone finding out.
 *
 * Each has already done so. The watering pushes were dead for months — the mail
 * kept going, so no user had a reason to complain. The mail itself answered 401
 * for six days in April when the provider ran out of credits, a hundred and
 * forty-nine undelivered messages nobody saw. Both were found by hand, long
 * after the fact, by reading logs for one named user.
 *
 * So they live on the first page of the panel rather than somewhere you would
 * have to think to visit. The rule throughout is the same: red means the last
 * thing that happened was a failure. A count of failures on its own does not
 * say that — it also rises for something that broke once and recovered.
 */

import { useEffect, useState } from "react";
import {
  fetchWeatherHealth,
  fetchPushHealth,
  fetchMailHealth,
  fetchSyncHealth,
  type WeatherHealth,
  type PushHealth,
  type MailHealth,
  type SyncHealth,
} from "@/lib/firestore";

/**
 * One card, sized to sit four across above the stat tiles.
 *
 * Everything is kept to two short lines because four of these share a row: the
 * verdict has to survive being glanced at, not read. The provider's own error
 * text lives in the tooltip rather than on the card — put inline it truncates
 * away the two things actually worth seeing, how long it has been broken and
 * how many attempts went that way, and "getaddrinfo ENOTFOUND api.open-me…"
 * says less than "not answering · 30h".
 */
function HealthCard({
  label,
  verdict,
  down,
  detail,
  error,
}: {
  label: string;
  verdict: string;
  down: boolean;
  detail?: string;
  error?: string;
}) {
  return (
    <div
      className={`rounded-lg border px-3 py-2 ${
        down ? "border-red-200 bg-red-50" : "bg-card"
      }`}
    >
      <div className="flex items-center gap-1.5">
        <span
          className={`h-1.5 w-1.5 shrink-0 rounded-full ${
            down ? "bg-red-500" : "bg-green-500"
          }`}
        />
        <span
          className={`truncate text-xs font-medium ${
            down ? "text-red-800" : "text-foreground"
          }`}
        >
          {label}
        </span>
      </div>
      <p
        className={`truncate text-xs ${
          down ? "text-red-700" : "text-muted-foreground"
        }`}
        title={down && error ? error : undefined}
      >
        {verdict}
        {detail && <> · {detail}</>}
      </p>
    </div>
  );
}

function Unrecorded({ label }: { label: string }) {
  // Not the same thing as healthy, and must not be coloured like it.
  return (
    <div className="rounded-lg border bg-card px-3 py-2">
      <div className="flex items-center gap-1.5">
        <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-muted-foreground/40" />
        <span className="truncate text-xs font-medium">{label}</span>
      </div>
      <p className="truncate text-xs text-muted-foreground">nothing recorded yet</p>
    </div>
  );
}

/**
 * "38m", "7h", "3d" — four of these share a row, so "about 7 hours ago" is a
 * luxury the width cannot pay for.
 */
function ago(d: Date) {
  const mins = Math.max(0, Math.round((Date.now() - d.getTime()) / 60000));
  if (mins < 60) return `${mins}m`;
  if (mins < 60 * 48) return `${Math.round(mins / 60)}h`;
  return `${Math.round(mins / (60 * 24))}d`;
}

function PushDeliveryCard({ health }: { health: PushHealth | null }) {
  if (!health?.lastAttemptAt) return <Unrecorded label="Watering pushes" />;

  const { lastAttemptAt, lastOkAt, lastFailAt, lastDeliveredCount } = health;
  // Age is deliberately not an alarm here: reminders fall due a couple of times
  // a day and some days none do, so a quiet week is ordinary. Reddening for it
  // would train everyone to ignore this card — which is how the outage it exists
  // for went unseen in the first place.
  const down = lastFailAt != null && (lastOkAt == null || lastFailAt >= lastOkAt);

  const detail = down
    ? health.failures > 1
      ? `${health.failures} runs · ${ago(lastAttemptAt)}`
      : ago(lastAttemptAt)
    : lastDeliveredCount != null
      ? `${lastDeliveredCount} ${lastDeliveredCount === 1 ? "device" : "devices"} · ${ago(lastAttemptAt)}`
      : ago(lastAttemptAt);

  return (
    <HealthCard
      label="Watering pushes"
      verdict={down ? "reached no device" : "arriving"}
      down={down}
      detail={detail}
      error={health.lastError}
    />
  );
}

function MailDeliveryCard({ health }: { health: MailHealth | null }) {
  if (!health) return <Unrecorded label="Watering emails" />;

  const { lastOkAt, lastFailAt, consecutiveFailures } = health;
  // A run of failures, not a ratio and not the newest message alone: one address
  // that bounces between two good sends is ordinary and says nothing about the
  // provider. Three in a row with no delivery in between does.
  const down = consecutiveFailures >= 3;

  const detail = down
    ? `${consecutiveFailures} failed${lastFailAt ? ` · ${ago(lastFailAt)}` : ""}`
    : [
        lastOkAt ? ago(lastOkAt) : lastFailAt ? ago(lastFailAt) : "",
        consecutiveFailures > 0 ? `${consecutiveFailures} failed` : "",
      ]
        .filter(Boolean)
        .join(" · ");

  return (
    <HealthCard
      label="Watering emails"
      verdict={down ? "not going out" : "going out"}
      down={down}
      detail={detail}
      error={health.lastError}
    />
  );
}

function WeatherProviderCard({ health }: { health: WeatherHealth | null }) {
  if (!health) return <Unrecorded label="Weather provider" />;

  const ok = health.lastOkAt;
  const down = health.lastFailAt != null && (ok == null || health.lastFailAt > ok);

  return (
    <HealthCard
      label="Weather provider"
      verdict={down ? "not answering" : "answering"}
      down={down}
      detail={ok ? ago(ok) : undefined}
      error={health.lastError}
    />
  );
}

function BigQuerySyncCard({ health }: { health: SyncHealth | null }) {
  if (!health) return <Unrecorded label="BigQuery sync" />;

  const ok = health.lastOkAt;
  const down = health.lastFailAt != null && (ok == null || health.lastFailAt > ok);
  // Unlike the two delivery cards, this one runs on a fixed nightly schedule, so
  // a copy that succeeded and then stopped running is exactly the failure worth
  // seeing. Here age is the alarm.
  const stale =
    !down && ok != null && Date.now() - ok.getTime() > 36 * 60 * 60 * 1000;

  const detail = [
    health.lastLoadedCount != null ? `${health.lastLoadedCount} tables` : "",
    ok ? ago(ok) : "",
  ]
    .filter(Boolean)
    .join(" · ");

  return (
    <HealthCard
      label="BigQuery sync"
      verdict={down ? "failed" : stale ? "stale" : "current"}
      down={down || stale}
      detail={detail}
      error={health.lastError}
    />
  );
}

export function SystemHealth() {
  const [push, setPush] = useState<PushHealth | null>(null);
  const [mail, setMail] = useState<MailHealth | null>(null);
  const [weather, setWeather] = useState<WeatherHealth | null>(null);
  const [sync, setSync] = useState<SyncHealth | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    Promise.all([
      fetchPushHealth(),
      fetchMailHealth(),
      fetchWeatherHealth(),
      fetchSyncHealth(),
    ])
      .then(([p, m, w, s]) => {
        setPush(p);
        setMail(m);
        setWeather(w);
        setSync(s);
      })
      // A panel that cannot read these must not imply everything is fine, but it
      // is also not worth taking the dashboard down over.
      .catch(() => undefined)
      .finally(() => setReady(true));
  }, []);

  if (!ready) return null;

  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      <PushDeliveryCard health={push} />
      <MailDeliveryCard health={mail} />
      <WeatherProviderCard health={weather} />
      <BigQuerySyncCard health={sync} />
    </div>
  );
}
