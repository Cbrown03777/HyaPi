// Allow importing a global stylesheet with no side-effect types
declare const content: string;
export default content;

// Fallback for any CSS import in this subtree
declare module '*.css' {
	const content: string;
	export default content;
}
