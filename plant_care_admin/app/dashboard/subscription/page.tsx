"use client";

import { useEffect, useState } from "react";
import {
  fetchSubscriptionConfig,
  saveSubscriptionConfig,
  fetchUsersBySubscriptionStatus,
  updateUserSubscriptionStatus,
  type SubscriptionConfig,
  type SubscriptionStatus,
  type AdminUser,
} from "@/lib/firestore";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { format } from "date-fns";
import { Save, RefreshCw } from "lucide-react";

const STATUS_LABELS: Record<string, string> = {
  all: "All",
  trial: "Trial",
  active: "Premium",
  expired: "Expired",
  grandfathered: "Forever Premium",
};

const STATUS_COLORS: Record<string, string> = {
  trial: "bg-blue-100 text-blue-700",
  active: "bg-green-100 text-green-700",
  expired: "bg-red-100 text-red-700",
  grandfathered: "bg-purple-100 text-purple-700",
};

function StatusBadge({ status }: { status: string }) {
  return (
    <Badge className={STATUS_COLORS[status] || "bg-muted text-muted-foreground"}>
      {STATUS_LABELS[status] || status}
    </Badge>
  );
}

export default function SubscriptionPage() {
  const [config, setConfig] = useState<SubscriptionConfig>({
    trial_days: 14,
    trial_plant_limit: 1,
    subscription_plant_limit: 10,
    grandfathered_cutoff_date: "",
  });
  const [configLoading, setConfigLoading] = useState(true);
  const [configSaving, setConfigSaving] = useState(false);
  const [configSaved, setConfigSaved] = useState(false);
  const [configError, setConfigError] = useState("");

  const [selectedStatus, setSelectedStatus] = useState<SubscriptionStatus | "all">("all");
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [usersLoading, setUsersLoading] = useState(false);
  const [usersError, setUsersError] = useState("");
  const [updatingUid, setUpdatingUid] = useState<string | null>(null);

  useEffect(() => {
    fetchSubscriptionConfig()
      .then(setConfig)
      .catch((e) => setConfigError(e.message))
      .finally(() => setConfigLoading(false));
  }, []);

  useEffect(() => {
    loadUsers(selectedStatus);
  }, [selectedStatus]);

  async function loadUsers(status: SubscriptionStatus | "all") {
    setUsersLoading(true);
    setUsersError("");
    try {
      const list = await fetchUsersBySubscriptionStatus(status);
      setUsers(list);
    } catch (e: unknown) {
      setUsersError(e instanceof Error ? e.message : String(e));
    } finally {
      setUsersLoading(false);
    }
  }

  async function handleSaveConfig() {
    setConfigSaving(true);
    setConfigError("");
    setConfigSaved(false);
    try {
      await saveSubscriptionConfig(config);
      setConfigSaved(true);
      setTimeout(() => setConfigSaved(false), 3000);
    } catch (e: unknown) {
      setConfigError(e instanceof Error ? e.message : String(e));
    } finally {
      setConfigSaving(false);
    }
  }

  async function handleStatusChange(uid: string, newStatus: SubscriptionStatus) {
    setUpdatingUid(uid);
    try {
      await updateUserSubscriptionStatus(uid, newStatus);
      setUsers((prev) =>
        prev.map((u) =>
          u.uid === uid ? { ...u, subscriptionStatus: newStatus } : u
        )
      );
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : String(e));
    } finally {
      setUpdatingUid(null);
    }
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Subscription Settings</h1>

      {/* Config card */}
      <Card>
        <CardHeader>
          <CardTitle>App Config</CardTitle>
          <CardDescription>
            Controls trial length and plant limits. Prices are managed in App Store Connect.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {configLoading ? (
            <div className="flex items-center justify-center py-8">
              <div className="h-6 w-6 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
            </div>
          ) : (
            <div className="space-y-4">
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium">Trial Duration (days)</label>
                  <Input
                    type="number"
                    min={1}
                    max={365}
                    value={config.trial_days}
                    onChange={(e) =>
                      setConfig((c) => ({ ...c, trial_days: Number(e.target.value) }))
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Counted from user registration date
                  </p>
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium">Trial Plant Limit</label>
                  <Input
                    type="number"
                    min={1}
                    max={100}
                    value={config.trial_plant_limit}
                    onChange={(e) =>
                      setConfig((c) => ({
                        ...c,
                        trial_plant_limit: Number(e.target.value),
                      }))
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Max plants a trial user can add
                  </p>
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium">Subscription Plant Limit</label>
                  <Input
                    type="number"
                    min={1}
                    max={1000}
                    value={config.subscription_plant_limit}
                    onChange={(e) =>
                      setConfig((c) => ({
                        ...c,
                        subscription_plant_limit: Number(e.target.value),
                      }))
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Max plants for paid subscribers
                  </p>
                </div>

                <div className="space-y-1.5 sm:col-span-2 lg:col-span-3">
                  <label className="text-sm font-medium">
                    Grandfathered Cutoff Date (ISO)
                  </label>
                  <Input
                    type="text"
                    placeholder="e.g. 2026-05-15T00:00:00Z"
                    value={config.grandfathered_cutoff_date}
                    onChange={(e) =>
                      setConfig((c) => ({
                        ...c,
                        grandfathered_cutoff_date: e.target.value,
                      }))
                    }
                  />
                  <p className="text-xs text-muted-foreground">
                    Users registered before this date are grandfathered (free forever).
                    Run migrateGrandfatheredUsers Cloud Function after setting this.
                  </p>
                </div>
              </div>

              {configError && (
                <p className="text-sm text-destructive">{configError}</p>
              )}

              <div className="flex items-center gap-3">
                <Button
                  onClick={handleSaveConfig}
                  disabled={configSaving}
                  className="bg-green-600 hover:bg-green-700 text-white"
                >
                  <Save className="mr-2 h-4 w-4" />
                  {configSaving ? "Saving…" : "Save Config"}
                </Button>
                {configSaved && (
                  <span className="text-sm text-green-600 font-medium">Saved ✓</span>
                )}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Users by subscription status */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Users by Subscription</CardTitle>
              <CardDescription>
                View and manually override subscription status per user.
              </CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <Select
                value={selectedStatus}
                onValueChange={(v) => setSelectedStatus(v as SubscriptionStatus | "all")}
              >
                <SelectTrigger className="w-44">
                  {selectedStatus === "all" ? "All" : (STATUS_LABELS[selectedStatus] || selectedStatus)}
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All</SelectItem>
                  <SelectItem value="trial">Trial</SelectItem>
                  <SelectItem value="active">Premium</SelectItem>
                  <SelectItem value="expired">Expired</SelectItem>
                  <SelectItem value="grandfathered">Forever Premium</SelectItem>
                </SelectContent>
              </Select>
              <Button
                variant="outline"
                size="sm"
                onClick={() => loadUsers(selectedStatus)}
                disabled={usersLoading}
              >
                <RefreshCw className={`h-4 w-4 ${usersLoading ? "animate-spin" : ""}`} />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {usersLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-6 w-6 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
            </div>
          ) : usersError ? (
            <p className="p-4 text-sm text-destructive">{usersError}</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Registered</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Expires</TableHead>
                  <TableHead>Override</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={5}
                      className="py-10 text-center text-muted-foreground"
                    >
                      No users with &ldquo;{selectedStatus}&rdquo; status.
                    </TableCell>
                  </TableRow>
                ) : (
                  users.map((u) => (
                    <TableRow key={u.uid}>
                      <TableCell>
                        <div>
                          <p className="font-medium text-sm">{u.name || "—"}</p>
                          <p className="text-xs text-muted-foreground">{u.email}</p>
                        </div>
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {u.createdAt ? format(u.createdAt, "MMM d, yyyy") : "—"}
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={u.subscriptionStatus || "trial"} />
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {u.subscriptionExpiresAt
                          ? format(u.subscriptionExpiresAt, "MMM d, yyyy")
                          : "—"}
                      </TableCell>
                      <TableCell>
                        <Select
                          value={u.subscriptionStatus || "trial"}
                          onValueChange={(v) =>
                            handleStatusChange(u.uid, v as SubscriptionStatus)
                          }
                          disabled={updatingUid === u.uid}
                        >
                          <SelectTrigger className="h-8 w-36 text-xs">
                            {STATUS_LABELS[u.subscriptionStatus || "trial"] || u.subscriptionStatus}
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="active">Premium</SelectItem>
                            <SelectItem value="expired">Expired</SelectItem>
                            <SelectItem value="grandfathered">Forever Premium</SelectItem>
                          </SelectContent>
                        </Select>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
