module.exports = {
	types: [
		{ value: "feat", name: "feat:     A new feature" },
		{ value: "fix", name: "fix:      A bug fix" },
		{ value: "docs", name: "docs:     Documentation only changes" },
		{ value: "style", name: "style:    Changes that do not affect the meaning of the code" },
		{ value: "refactor", name: "refactor: A code change that neither fixes a bug nor adds a feature" },
		{ value: "perf", name: "perf:     A code change that improves performance" },
		{ value: "test", name: "test:     Adding missing tests or correcting existing tests" },
		{ value: "chore", name: "chore:    Changes to the build process or auxiliary tools" }
	],
	scopes: [],
	allowCustomScopes: true,
	allowBreakingChanges: ["feat", "fix"],
	// Enforce a 50 character limit for the subject (title)
	maxHeaderWidth: 50,
	// Wrap body and footer at 72 characters
	maxLineWidth: 72,
	subjectPrompt: "Write a short, imperative tense description of the change (max 50 chars):",
	messages: {
		type: "Select the type of change that you're committing:",
		scope: "\nDenote the SCOPE of this change (optional):",
		customScope: "Denote the SCOPE of this change:",
		subject: "Write a short, imperative tense description of the change (max 50 chars):\n",
		body: 'Provide a longer description of the change (optional). Use "|" to break new line:\n',
		breaking: 'List any BREAKING CHANGES (optional):\n',
		footer: 'List any ISSUES CLOSED by this change (optional). E.g.: #31, #34:\n',
		confirmCommit: "Are you sure you want to proceed with the commit above?"
	}
};
