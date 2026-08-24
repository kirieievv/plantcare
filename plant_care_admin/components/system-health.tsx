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
import { formatDistanceToNow } from "date-fns";
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

/** One line. `down` is the whole verdict; everything else is detail. */
function HealthLine({
  label,
  verdict,
  down,
  detail,
  error,
}: {
  label: string;
  verdict: string;
  down: boolean;
  detail?: React.ReactNode;
  error?: string;
}) {
  return (
    <div
      className={`rounded-lg border px-4 py-3 text-sm ${
        down ? "border-red-200 bg-red-50 text-red-800" : "text-muted-foreground"
      }`}
    >
      <span className="font-medium">{label}</span> {verdict}
      {detail}
      {down && error && <div className="mt-1 font-mono text-xs">{error}</div>}
    </div>
  );
}

function Unrecorded({ label }: { label: string }) {
  // Not the same thing as healthy, and must not read like it.
  return (
    <p className="text-sm text-muted-foreground">{label} — nothing recorded yet</p>
  );
}

function ago(d: Date) {
  return formatDistanceToNow(d, { addSuffix: true });
}

function PushDeliveryLine({ health }: { health: PushHealth | null }) {
  if (!health?.lastAttemptAt) return <Unrecorded label="Watering pushes" />;

  const { lastAttemptAt, lastOkAt, lastFailAt, lastDeliveredCount } = health;
  // Age is deliberately not an alarm here: reminders fall due a couple of times
  // a day and some days none do, so a quiet week is ordinary. Reddening for it
  // would train everyone to ignore this line — which is how the outage it
  // exists for went unseen in the first place.
  const down = lastFailAt != null && (lastOkAt == null || lastFailAt >= lastOkAt);

  return (
    <HealthLine
      label="Watering pushes"
      verdict={down ? "reached no device" : "are arriving"}
      down={down}
      error={health.lastError}
      detail={
        <>
          {" "}· last attempt {ago(lastAttemptAt)}
          {!down && lastDeliveredCount != null && (
            <>
              {" "}· {lastDeliveredCount}{" "}
              {lastDeliveredCount === 1 ? "device" : "devices"}
            </>
          )}
          {down && health.failures > 1 && <> · {health.failures} runs in a row</>}
        </>
      }
    />
  );
}

function MailDeliveryLine({ health }: { health: MailHealth | null }) {
  if (!health) return <Unrecorded label="Watering emails" />;

  const { lastOkAt, lastFailAt, consecutiveFailures } = health;
  // A run of failures, not a ratio and not the newest message alone: one address
  // that bounces between two good sends is ordinary and says nothing about the
  // provider. Three in a row with no delivery in between does.
  const down = consecutiveFailures >= 3;

  return (
    <HealthLine
      label="Watering emails"
      verdict={down ? "are not going out" : "are going out"}
      down={down}
      error={health.lastError}
      detail={
        <>
          {lastOkAt && <> · last delivered {ago(lastOkAt)}</>}
          {down && <> · {consecutiveFailures} failed since</>}
          {!down && consecutiveFailures > 0 && (
            <> · {consecutiveFailures} recent failure
              {consecutiveFailures === 1 ? "" : "s"}</>
          )}
          {!lastOkAt && lastFailAt && <> · last attempt {ago(lastFailAt)}</>}
        </>
      }
    />
  );
}

function WeatherProviderLine({ health }: { health: WeatherHealth | null }) {
  if (!health) return <Unrecorded label="Weather provider" />;

  const ok = health.lastOkAt;
  const down = health.lastFailAt != null && (ok == null || health.lastFailAt > ok);

  return (
    <HealthLine
      label="Weather provider"
      verdict={down ? "is not answering" : "is answering"}
      down={down}
      error={health.lastError}
      detail={
        <>
          {ok && <> · last success {ago(ok)}</>}
          {health.failures > 0 && <> · {health.failures} failures</>}
        </>
      }
    />
  );
}

function BigQuerySyncLine({ health }: { health: SyncHealth | null }) {
  if (!health) return <Unrecorded label="BigQuery sync" />;

  const ok = health.lastOkAt;
  const down = health.lastFailAt != null && (ok == null || health.lastFailAt > ok);
  // Unlike the two delivery lines, this one runs on a fixed nightly schedule, so
  // a copy that succeeded and then stopped running is exactly the failure worth
  // seeing. Here age is the alarm.
  const stale =
    !down && ok != null && Date.now() - ok.getTime() > 36 * 60 * 60 * 1000;

  return (
    <HealthLine
      label="BigQuery sync"
      verdict={down ? "failed" : stale ? "has not run in over a day" : "is current"}
      down={down || stale}
      error={health.lastError}
      detail={
        <>
          {ok && <> · last success {ago(ok)}</>}
          {health.lastLoadedCount != null && <> · {health.lastLoadedCount} tables</>}
        </>
      }
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
    <div className="space-y-2">
      <PushDeliveryLine health={push} />
      <MailDeliveryLine health={mail} />
      <WeatherProviderLine health={weather} />
      <BigQuerySyncLine health={sync} />
    </div>
  );
}
