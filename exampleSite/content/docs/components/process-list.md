---
title: "Process list"
description: "Number a sequence the reader has to follow in order."
weight: 30
---

Use a process list only when order genuinely matters. A sequence the reader can
do in any order is an unordered list, and numbering it implies a dependency
that is not there.

```
{{</* process-list heading_level="h3" */>}}
{{</* process-step heading="Install" */>}}
Body copy, including code blocks.
{{</* /process-step */>}}
{{</* /process-list */>}}
```

{{< process-list heading_level="h3" >}}
{{< process-step heading="Write the step heading as an action" >}}
"Install the dependencies", not "Dependencies".
{{< /process-step >}}
{{< process-step heading="Keep the body to what happens in this step" >}}
Anything that applies to the whole sequence belongs above the list.
{{< /process-step >}}
{{< process-step heading="Stop when the reader is done" >}}
A last step that only says "you're finished" is not a step.
{{< /process-step >}}
{{< /process-list >}}

Steps render where they are written, so a step body can contain any markdown —
paragraphs, lists, or a fenced code block.
