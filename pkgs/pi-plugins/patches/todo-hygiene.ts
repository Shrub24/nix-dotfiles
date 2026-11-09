import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { STATE_ENTRY_TYPE } from "../tool/types.ts";
import { commitState, getState, sid } from "./store.ts";

/**
 * Drop completed tasks from the session's live state and record the pruned
 * snapshot, so replay sees the same list the overlay shows. Called at the turn
 * boundary, where the overlay already stops rendering completed rows: state
 * kept them indefinitely, which made `list` and every recorded snapshot grow
 * with tasks nobody would look at again.
 */
export function flushCompleted(pi: ExtensionAPI, ctx: ExtensionContext): boolean {
	const session = sid(ctx);
	const state = getState(session);
	const removed = new Set(state.tasks.filter((task) => task.status === "completed").map((task) => task.id));
	if (removed.size === 0) return false;
	// Depends-on edges to a dropped task would render as a reference to a task
	// nothing can show any more, so the surviving tasks lose them here.
	const tasks = state.tasks
		.filter((task) => !removed.has(task.id))
		.map((task) =>
			task.blockedBy?.some((id) => removed.has(id))
				? { ...task, blockedBy: task.blockedBy.filter((id) => !removed.has(id)) }
				: task,
		);
	const next = { tasks, nextId: state.nextId };
	commitState(session, next);
	pi.appendEntry(STATE_ENTRY_TYPE, { action: "clear", params: {}, ...next });
	return true;
}

/**
 * Message listing the tasks still open, injected at the start of every run.
 * The tool's prompt guidance asks for the list to be checked, and a model that
 * has moved on never does; the carried-over entries are otherwise invisible
 * until something asks for them.
 */
export function openTasksMessage(
	ctx: ExtensionContext,
): { customType: string; content: string; display: false } | undefined {
	const open = getState(sid(ctx)).tasks.filter((task) => task.status === "pending" || task.status === "in_progress");
	if (open.length === 0) return undefined;
	const lines = open.map((task) => {
		const label = task.status === "in_progress" && task.activeForm ? task.activeForm : task.subject;
		return `#${task.id} ${task.status}: ${label}`;
	});
	return {
		customType: "rpiv-todo-open",
		display: false,
		content: [
			`${open.length} todo ${open.length === 1 ? "entry is" : "entries are"} still open from earlier turns:`,
			...lines,
			"Mark each one completed as its work lands, or delete it if it is no longer wanted; do not leave it on the list unmentioned.",
		].join("\n"),
	};
}
