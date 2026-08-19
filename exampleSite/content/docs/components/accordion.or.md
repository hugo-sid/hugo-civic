---
title: "ଆକର୍ଡିଅନ"
description: "ପୃଷ୍ଠା ସ୍କାନଯୋଗ୍ୟ ରହିବା ପାଇଁ ଲମ୍ବା ସହାୟକ ବିବରଣୀକୁ ସଙ୍କୁଚିତ କରନ୍ତୁ ।"
weight: 20
---

ଏକ ଆକର୍ଡିଅନ ହେଉଛି ଦୁଇଟି ସର୍ଟକୋଡ: ଗୋଟିଏ ମୋଡ଼ୁଥିବା ସର୍ଟକୋଡ ଯାହା ଗୋଷ୍ଠୀର ବିକଳ୍ପ ବହନ କରେ,
ଏବଂ ପ୍ରତ୍ୟେକ ପ୍ୟାନେଲ ପାଇଁ ଗୋଟିଏ ଆଇଟମ ।

```
{{</* accordion bordered="true" multiselectable="true" heading_level="h3" */>}}
{{</* accordion-item title="First question" expanded="true" */>}}
Body copy.
{{</* /accordion-item */>}}
{{</* /accordion */>}}
```

{{< accordion bordered="true" multiselectable="true" heading_level="h3" >}}
{{< accordion-item title="bordered କ'ଣ ବଦଳାଏ?" expanded="true" >}}
ଏହା ପ୍ରତ୍ୟେକ ପ୍ୟାନେଲ ଚାରିପଟେ ଏକ ସୀମାରେଖା ଆଙ୍କେ । ଯେତେବେଳେ ଆକର୍ଡିଅନ ଏକ କାର୍ଡ ଭିତରେ ନ
ରହି ସିଧାସଳଖ ପୃଷ୍ଠା ପୃଷ୍ଠଭୂମି ଉପରେ ବସେ, ସେତେବେଳେ ଏହା ବ୍ୟବହାର କରନ୍ତୁ ।
{{< /accordion-item >}}
{{< accordion-item title="multiselectable କ'ଣ ବଦଳାଏ?" >}}
ଏହା ଏକାଧିକ ପ୍ୟାନେଲକୁ ଏକା ସମୟରେ ଖୋଲା ରହିବାକୁ ଦିଏ । ଏହା ବିନା, ଗୋଟିଏ ପ୍ୟାନେଲ ଖୋଲିଲେ
ଅନ୍ୟଗୁଡ଼ିକ ବନ୍ଦ ହୋଇଯାଏ ।
{{< /accordion-item >}}
{{< accordion-item title="heading_level କାହିଁକି ସେଟ କରିବେ?" >}}
ଆଇଟମଗୁଡ଼ିକ ପୂର୍ବନିର୍ଦ୍ଧାରିତ ଭାବେ `h4` ହୁଏ । ସିଧାସଳଖ ଏକ `h2` ତଳେ ଏହା ଏକ ସ୍ତର ଡେଇଁଯାଏ,
ତେଣୁ ଯେଉଁ ସ୍ତର ଡକ୍ୟୁମେଣ୍ଟର ରୂପରେଖକୁ ଅବିଚ୍ଛିନ୍ନ ରଖେ ତାହା ପାସ କରନ୍ତୁ ।
{{< /accordion-item >}}
{{< /accordion >}}

ପ୍ୟାନେଲର id ସର୍ଟକୋଡର କ୍ରମସଂଖ୍ୟାରୁ ଆସେ, ତେଣୁ ଏକାଧିକ ଆକର୍ଡିଅନ ସେମାନଙ୍କର id ଏକାପରି ନ
ହୋଇ ଗୋଟିଏ ପୃଷ୍ଠା ସେୟାର କରିପାରନ୍ତି ।
