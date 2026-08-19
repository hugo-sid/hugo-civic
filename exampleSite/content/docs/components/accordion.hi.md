---
title: "अकॉर्डियन"
description: "लंबे सहायक विवरण को समेटें ताकि पृष्ठ स्कैन करने योग्य बना रहे।"
weight: 20
---

एक अकॉर्डियन दो शॉर्टकोड है: एक रैपर जो समूह के विकल्प ले जाता है, और प्रति पैनल एक
आइटम।

```
{{</* accordion bordered="true" multiselectable="true" heading_level="h3" */>}}
{{</* accordion-item title="First question" expanded="true" */>}}
Body copy.
{{</* /accordion-item */>}}
{{</* /accordion */>}}
```

{{< accordion bordered="true" multiselectable="true" heading_level="h3" >}}
{{< accordion-item title="bordered क्या बदलता है?" expanded="true" >}}
यह हर पैनल के चारों ओर एक बॉर्डर बनाता है। इसका उपयोग तब करें जब अकॉर्डियन सीधे पृष्ठ
पृष्ठभूमि पर बैठा हो, किसी कार्ड के भीतर नहीं।
{{< /accordion-item >}}
{{< accordion-item title="multiselectable क्या बदलता है?" >}}
यह एक साथ एक से ज़्यादा पैनल खुले रहने देता है। इसके बिना, एक पैनल खोलने से दूसरे बंद
हो जाते हैं।
{{< /accordion-item >}}
{{< accordion-item title="heading_level क्यों सेट करें?" >}}
आइटम डिफ़ॉल्ट रूप से `h4` लेते हैं। सीधे किसी `h2` के नीचे यह एक स्तर छोड़ देता है,
इसलिए वह स्तर पास करें जो दस्तावेज़ की रूपरेखा को निरंतर बनाए रखे।
{{< /accordion-item >}}
{{< /accordion >}}

पैनल आईडी शॉर्टकोड के क्रमांक से आती हैं, इसलिए कई अकॉर्डियन एक पृष्ठ साझा कर सकते हैं
बिना उनकी आईडी टकराए।
