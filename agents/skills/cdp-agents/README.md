# CDP Agents

Provider adapters for authenticated AI web apps over Chrome CDP.

## Common contract
- check provider/session reachability.
- select the provider's project-like container.
- attach local files through the real UI.
- send a prompt and wait for completion.
- receive the latest completed response.
- use **@Remote Desktop Commander tool** for local filesystem, terminal, process, and verification work.

## Provider mapping
- Claude → Projects
- ChatGPT → Projects
- Gemini Chat → Notebooks
- Gemini Spark → Spark tasks/tools

## Rules
Use semantic names first and fresh refs only within the current snapshot.
Refresh the snapshot after navigation, menu opens, uploads, or submission.
Keep selectors/workflows inside provider adapters.
Never read cookies, access tokens, or stored credentials.
The browser must already be authenticated by the user.

## Content-pipeline rule
The hisual content pipeline uses **Claude only**. Do not dispatch content tasks to ChatGPT or Gemini.

## Local work
Every CDP agent prompt that needs local files, terminal commands, process control, generated assets, or verification must explicitly use:
`@Remote Desktop Commander tool`

## Headless runtime
For unattended hisual work, attach to the single XOY Chrome owner at `~/.config/xoy`; do not start a second browser against that profile.
