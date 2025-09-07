export default function AdminIndex() {
	return (
		<div className="max-w-screen-md mx-auto p-6 space-y-6">
			<header>
				<h1 className="text-2xl font-semibold">Admin</h1>
				<p className="text-sm text-white/60 mt-1">Internal operational panels. Use navigation to access specific tools.</p>
			</header>
			<div className="grid gap-4 sm:grid-cols-2">
				<a href="/admin/alloc" className="block rounded border border-white/15 bg-white/5 p-4 hover:border-white/30 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-500">
					<h2 className="font-medium mb-1">Allocation Planner</h2>
					<p className="text-xs text-white/60">Preview and simulate rebalances across venues.</p>
				</a>
			</div>
		</div>
	);
}
