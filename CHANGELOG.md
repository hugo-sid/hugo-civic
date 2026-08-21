# Changelog

## [0.3.0](https://github.com/hugo-sid/hugo-civic/compare/v0.2.0...v0.3.0) (2026-08-21)


### :sparkles: Features

* add search with pagefind ([#2](https://github.com/hugo-sid/hugo-civic/issues/2)) ([e814810](https://github.com/hugo-sid/hugo-civic/commit/e814810136ebb2ea3a4cf16aaa6b36c3439f71ae))
* **example:** configure exampleSite for English and Spanish ([6d26774](https://github.com/hugo-sid/hugo-civic/commit/6d26774b4b7e96e985d217968f9ac64303ac8be4))
* **header:** unstyle the mobile language selector button ([a80ae7b](https://github.com/hugo-sid/hugo-civic/commit/a80ae7b272725d5f119f3eb2c5f65e40d9cb5754))
* **i18n:** add Hindi as a third language ([d9c8124](https://github.com/hugo-sid/hugo-civic/commit/d9c8124ec1b385b981feb1d4fdfa67c5e4be3b6b))
* **i18n:** add language selector and hreflang alternates ([9f3bd6b](https://github.com/hugo-sid/hugo-civic/commit/9f3bd6b685d674d33950088327dbb98bf6a10ff7))
* **i18n:** add Odia as a fourth language ([841e958](https://github.com/hugo-sid/hugo-civic/commit/841e958966b5e1a11306a441949655c512c07bbc))
* **i18n:** add Tamil as a fifth language ([4c11bdc](https://github.com/hugo-sid/hugo-civic/commit/4c11bdcf4b7770069b8fafc30e28614c0645f798))
* **i18n:** add Telugu as a sixth language ([d6d15ce](https://github.com/hugo-sid/hugo-civic/commit/d6d15ce0519483351ab89a4c8b10217d18efa5e9))
* **i18n:** self-host Noto Sans Devanagari for Hindi content ([3324551](https://github.com/hugo-sid/hugo-civic/commit/3324551561e34c785db8d70259ba9b6b4012cf79))


### :bug: Bug Fixes

* **header:** space the mobile language selector off the menu button ([608edd6](https://github.com/hugo-sid/hugo-civic/commit/608edd629c455f3c1b8a7ad321f300a53d0d804f))
* **i18n:** repair in-page-nav scroll-spy for non-Latin headings ([0894780](https://github.com/hugo-sid/hugo-civic/commit/0894780f9bb6221c6cbcd2ef015715910650a188))
* **i18n:** translate menu labels and fix identifier prefix leak ([42f848f](https://github.com/hugo-sid/hugo-civic/commit/42f848f6217ab251458e56c3b165f69f5c624184))


### :hammer: Housekeeping

* ignore Hugo's generated jsconfig.json ([38f5dd2](https://github.com/hugo-sid/hugo-civic/commit/38f5dd2442d6457977ffa0ff42d2efd023430708))


### :memo: Documentation

* add multilingual implementation guide ([d92951e](https://github.com/hugo-sid/hugo-civic/commit/d92951ed0bf4aeec96d312af339c826cd14eeaa5))
* add pagefind implementation plan ([fe61be0](https://github.com/hugo-sid/hugo-civic/commit/fe61be0beaaf017f95bc0c05b2d69637eee84bbe))
* add widest-reach design checklist ([f9f58b0](https://github.com/hugo-sid/hugo-civic/commit/f9f58b0cecd50116cd3faab94a46254ff6f7b299))
* record the Hindi rollout ([4d6131b](https://github.com/hugo-sid/hugo-civic/commit/4d6131bc0a39c02f4b10d5064384d65c15d6137f))
* record the Odia rollout, and enforce the danda convention ([3fde3d2](https://github.com/hugo-sid/hugo-civic/commit/3fde3d2e7ec476f3e90a9bd5bec3267c73b1efc0))
* record the Tamil rollout, and a defect it exposed ([65758a5](https://github.com/hugo-sid/hugo-civic/commit/65758a540c5ecd13742cb88b2ed124c7267e9564))
* record the Telugu rollout, and a defect it exposed ([c654860](https://github.com/hugo-sid/hugo-civic/commit/c654860cc902035153061dcd7213cd8047453798))
* rewrite README for multilingual and search features ([c17dcdb](https://github.com/hugo-sid/hugo-civic/commit/c17dcdb0e92e2600a9c99914af0c636abdb7dbd8))


### :page_facing_up: Example Content

* **example:** add Hindi translations for all example pages ([b35d089](https://github.com/hugo-sid/hugo-civic/commit/b35d0898b3fa7af5f40f0dd551610b677cad7f66))
* **example:** add Odia translations for all example pages ([f540ad8](https://github.com/hugo-sid/hugo-civic/commit/f540ad8c19372eb31ed595e379429091f12902f9))
* **example:** add Spanish translations for example pages ([650eebd](https://github.com/hugo-sid/hugo-civic/commit/650eebd18f308d6b7404ba108766207ebc0aa7c9))
* **example:** add Tamil translations for all example pages ([2224721](https://github.com/hugo-sid/hugo-civic/commit/222472101931ac4620e6730ef960ea44cb67452a))
* **example:** add Telugu translations for all example pages ([728ad95](https://github.com/hugo-sid/hugo-civic/commit/728ad956eb7f236428e7bc0d27851b0bbaafa8a0))


### :construction_worker: CI/CD

* give the content type a changelog section ([4505ada](https://github.com/hugo-sid/hugo-civic/commit/4505adadf1314868b302b6056cec64b484b32227))


### :white_check_mark: Tests

* **i18n:** add translation table consistency check ([75ec732](https://github.com/hugo-sid/hugo-civic/commit/75ec732a10db45554a6cb7a978d21e8d207ea422))
* **search:** validate per-language search page and masthead action ([66f92e4](https://github.com/hugo-sid/hugo-civic/commit/66f92e40f3ce7b4582e2f83dec61e9fe291dc24b))

## [0.2.0](https://github.com/hugo-sid/hugo-civic/compare/v0.1.0...v0.2.0) (2026-08-07)


### :sparkles: Features

* **article:** add a date, author and topic byline to single pages ([3f921f8](https://github.com/hugo-sid/hugo-civic/commit/3f921f83f8377569fc8c3f7af754c28fcf67a305))
* **article:** add one onward block of related or previous/next links ([6407e64](https://github.com/hugo-sid/hugo-civic/commit/6407e64d2a4c5a5cfa2e60cdfd29655daa1e6fd1))
* **card-group:** render a page collection as cards ([6c192d2](https://github.com/hugo-sid/hugo-civic/commit/6c192d20d8e16c13e74cd537ba50d4036b09496f))
* **nav:** let a section opt out of the side navigation ([ed8dad4](https://github.com/hugo-sid/hugo-civic/commit/ed8dad4ee736e7558ec9f734b437ce513b036b23))
* **pagination:** paginate section listings with usa-pagination ([92d0c6a](https://github.com/hugo-sid/hugo-civic/commit/92d0c6afd26ee0fc8a2ff26446a52ba1501be6eb))
* **seo:** add share images and article metadata to Open Graph tags ([7992659](https://github.com/hugo-sid/hugo-civic/commit/79926594342bf0990876a9e950e01df3ddc85cab))
* **taxonomy:** add taxonomy and term templates ([64da1ba](https://github.com/hugo-sid/hugo-civic/commit/64da1ba79208885f2bf669abff1991242a9b72e5))


### :bug: Bug Fixes

* **styles:** keep the reading column independent of the in-page nav ([765e539](https://github.com/hugo-sid/hugo-civic/commit/765e539ee510bd8148b339eb71e2990eb09a5564))


### :hammer: Housekeeping

* initial commit ([2fee1fc](https://github.com/hugo-sid/hugo-civic/commit/2fee1fc91c453c6897eb820e62ab9111b5e08bf3))
* update baseurl ([15e5faf](https://github.com/hugo-sid/hugo-civic/commit/15e5fafa08fa76787db59291eddc50b1faa22ead))


### :memo: Documentation

* **example:** document building a blog or news site ([a1167e6](https://github.com/hugo-sid/hugo-civic/commit/a1167e6c69e522f910f65cf28c6b172420a9ca27))
* **example:** expand the news section to eight tagged posts ([00a4a0d](https://github.com/hugo-sid/hugo-civic/commit/00a4a0d7e8e90160adf78c02fe79d1aa661665d1))


### :construction_worker: CI/CD

* fix Vercel deployment ([bb099e5](https://github.com/hugo-sid/hugo-civic/commit/bb099e5af45e33b1cb00fabbba0e1749e3b78ed4))
* fix Vercel deployment - 2 ([2968dd6](https://github.com/hugo-sid/hugo-civic/commit/2968dd669fb343d01475ef9b95f574c9a716d279))
* setup Vercel & release-please ([fc2e289](https://github.com/hugo-sid/hugo-civic/commit/fc2e28944459903d32970cf10ae5603ee157b448))
* switch release-please to manifest mode with the node release type ([a438198](https://github.com/hugo-sid/hugo-civic/commit/a4381988f7e790c1689070b70c134153dc5b2f4e))
