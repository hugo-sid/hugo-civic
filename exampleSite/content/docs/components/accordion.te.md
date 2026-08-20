---
title: "అకార్డియన్"
description: "పొడవైన అనుబంధ వివరాలను ముడుచుకోండి, తద్వారా పేజీ చూపులోనే అర్థమవుతుంది."
weight: 20
---

అకార్డియన్ అంటే రెండు షార్ట్‌కోడ్‌లు: సమూహపు ఎంపికలను మోసే ఒక ఆవరణ, ఒక్కో
ప్యానెల్‌కు ఒక అంశం.

```
{{</* accordion bordered="true" multiselectable="true" heading_level="h3" */>}}
{{</* accordion-item title="First question" expanded="true" */>}}
Body copy.
{{</* /accordion-item */>}}
{{</* /accordion */>}}
```

{{< accordion bordered="true" multiselectable="true" heading_level="h3" >}}
{{< accordion-item title="bordered ఏమి మారుస్తుంది?" expanded="true" >}}
అది ప్రతి ప్యానెల్ చుట్టూ ఒక అంచును గీస్తుంది. అకార్డియన్ ఒక కార్డు లోపల కాక
నేరుగా పేజీ నేపథ్యంపై కూర్చున్నప్పుడు దీన్ని వాడండి.
{{< /accordion-item >}}
{{< accordion-item title="multiselectable ఏమి మారుస్తుంది?" >}}
అది ఒకటి కంటే ఎక్కువ ప్యానెల్‌లను ఒకేసారి తెరిచి ఉంచనిస్తుంది. అది లేకపోతే, ఒక
ప్యానెల్ తెరిస్తే మిగతావి మూసుకుపోతాయి.
{{< /accordion-item >}}
{{< accordion-item title="heading_level ను ఎందుకు అమర్చాలి?" >}}
అంశాలు డిఫాల్ట్‌గా `h4` గా ఉంటాయి. ఒక `h2` కు నేరుగా కింద అది ఒక స్థాయిని
దాటేస్తుంది, కాబట్టి పత్ర రూపురేఖ తెగకుండా ఉండే స్థాయిని ఇవ్వండి.
{{< /accordion-item >}}
{{< /accordion >}}

ప్యానెల్ ఐడీలు షార్ట్‌కోడ్ వరుస సంఖ్య నుండి వస్తాయి, కాబట్టి ఐడీలు ఢీకొనకుండా
ఒకే పేజీలో పలు అకార్డియన్‌లు ఉండగలవు.
