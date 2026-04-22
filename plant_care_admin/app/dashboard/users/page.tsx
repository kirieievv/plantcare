"use client";

import { useEffect, useState, useMemo } from "react";
import { fetchUsers, type AdminUser } from "@/lib/firestore";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  flexRender,
  createColumnHelper,
  type SortingState,
} from "@tanstack/react-table";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { format } from "date-fns";
import { ArrowUpDown, Search } from "lucide-react";
import Link from "next/link";

const col = createColumnHelper<AdminUser>();

function initials(name: string) {
  return name
    .split(" ")
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

function fmtDate(d?: Date) {
  if (!d) return "—";
  return format(d, "MMM d, yyyy");
}

function isActiveRecently(lastLogin?: Date) {
  if (!lastLogin) return false;
  return Date.now() - lastLogin.getTime() < 7 * 24 * 60 * 60 * 1000;
}

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [globalFilter, setGlobalFilter] = useState("");
  const [sorting, setSorting] = useState<SortingState>([]);

  useEffect(() => {
    fetchUsers()
      .then(setUsers)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const columns = useMemo(
    () => [
      col.accessor("name", {
        header: "User",
        cell: (info) => (
          <div className="flex items-center gap-3">
            <Avatar className="h-8 w-8">
              <AvatarFallback className="bg-green-100 text-green-700 text-xs font-semibold">
                {initials(info.getValue() || info.row.original.email)}
              </AvatarFallback>
            </Avatar>
            <div>
              <Link
                href={`/dashboard/users/${info.row.original.uid}`}
                className="font-medium hover:underline"
              >
                {info.getValue() || "—"}
              </Link>
              <p className="text-xs text-muted-foreground">{info.row.original.email}</p>
            </div>
          </div>
        ),
      }),
      col.accessor("createdAt", {
        header: ({ column }) => (
          <button
            className="flex items-center gap-1 hover:text-foreground"
            onClick={() => column.toggleSorting()}
          >
            Registered <ArrowUpDown className="h-3 w-3" />
          </button>
        ),
        cell: (info) => fmtDate(info.getValue()),
        sortingFn: "datetime",
      }),
      col.accessor("lastLogin", {
        header: "Last login",
        cell: (info) => {
          const d = info.getValue();
          return (
            <div className="flex items-center gap-2">
              <span>{fmtDate(d)}</span>
              {isActiveRecently(d) && (
                <Badge variant="secondary" className="bg-green-100 text-green-700 text-xs">
                  Active
                </Badge>
              )}
            </div>
          );
        },
        sortingFn: "datetime",
      }),
      col.accessor("timezone", {
        header: "Timezone",
        cell: (info) => info.getValue() || "—",
      }),
      col.accessor("location", {
        header: "Location",
        cell: (info) => info.getValue() || "—",
      }),
    ],
    []
  );

  const table = useReactTable({
    data: users,
    columns,
    state: { globalFilter, sorting },
    onGlobalFilterChange: setGlobalFilter,
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Users</h1>
        {!loading && (
          <span className="text-sm text-muted-foreground">{users.length} total</span>
        )}
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search by name or email…"
              value={globalFilter}
              onChange={(e) => setGlobalFilter(e.target.value)}
              className="pl-9"
            />
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <div className="h-6 w-6 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
            </div>
          ) : error ? (
            <p className="p-4 text-sm text-destructive">{error}</p>
          ) : (
            <Table>
              <TableHeader>
                {table.getHeaderGroups().map((hg) => (
                  <TableRow key={hg.id}>
                    {hg.headers.map((h) => (
                      <TableHead key={h.id} className="text-xs uppercase tracking-wide text-muted-foreground">
                        {h.isPlaceholder
                          ? null
                          : flexRender(h.column.columnDef.header, h.getContext())}
                      </TableHead>
                    ))}
                  </TableRow>
                ))}
              </TableHeader>
              <TableBody>
                {table.getRowModel().rows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={columns.length} className="py-10 text-center text-muted-foreground">
                      No users found.
                    </TableCell>
                  </TableRow>
                ) : (
                  table.getRowModel().rows.map((row) => (
                    <TableRow key={row.id} className="hover:bg-muted/50">
                      {row.getVisibleCells().map((cell) => (
                        <TableCell key={cell.id} className="py-3">
                          {flexRender(cell.column.columnDef.cell, cell.getContext())}
                        </TableCell>
                      ))}
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
