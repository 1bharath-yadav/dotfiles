---
id: cards.template
aliases: []
tags:
  - anki
  - study
subject: "{{SUBJECT}}"
topic: "{{TOPIC}}"
---

TARGET DECK: {{SUBJECT}}::{{TOPIC}}

FILE TAGS: {{subject}} {{topic}}

%%
Plugin Regex:
Basic = ((?:[^\n][\n]?)+)#flashcard\s*((?:\n(?!---).*)+)

Notes:

- First TARGET DECK in the file is used.
- FILE TAGS apply to every card in this file.
- Do not manually edit <!--ID: ...--> lines after sync.
  %%

