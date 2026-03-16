---
description: "Writing guidelines for Quarto documentation following Positron style guide"
applyTo: "**/*.qmd"
---

# Quarto Documentation Guidelines

## Writing and Style

- Write at approximately 12th grade reading level with sentences of 28-30 words or fewer
- Use present tense and active voice; avoid contractions and gerunds as nouns
- Use the Oxford comma and spell out acronyms on first use
- Maintain an energetic, compassionate tone that is simple and direct
- Use clear, literal language suitable for screen readers and translation tools; avoid idioms and metaphors
- Do not use possessives with product names

## Formatting

- Use Title Case for titles/H1s; sentence case for other headings
- Always include `title` and `description` in YAML front matter
- Bold UI elements, italicize commands, use backticks for code
- Use the Quarto `kbd` shortcode for keyboard shortcuts: `{{< kbd mac=Command-Shift-P win=Ctrl-Shift-P linux=Ctrl-Shift-P >}}`
- Link to settings: `[positron://settings/category.nameOfSetting](positron://settings/category.nameOfSetting)`
- Use em dashes (—) for emphasis; en dashes (–) for ranges