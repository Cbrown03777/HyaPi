"use client";
import { useInfiniteQuery } from '@tanstack/react-query';
import { fetchProposals } from '@/api/govProposals';

export function useGovProposals(params?: { status?: 'Open'|'Closed'|'All'; pageSize?: number }) {
  const status = params?.status ?? 'All';
  const pageSize = params?.pageSize ?? 20;
  const q = useInfiniteQuery({
    queryKey: ['govProposals', status, pageSize],
    queryFn: ({ pageParam }: { pageParam?: string }) => fetchProposals({ limit: pageSize, cursor: pageParam, status }),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last: any) => last?.data?.nextCursor ?? undefined,
    refetchOnWindowFocus: false,
  });
  const items = (q.data?.pages ?? []).flatMap((p: any) => p?.data?.items ?? []);
  const hasNextPage = !!q.data?.pages?.[q.data.pages.length - 1]?.data?.nextCursor;
  return { ...q, items, hasNextPage } as const;
}
