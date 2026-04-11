# Changelog

## [0.2.0](https://github.com/unfunco/terraform-aws-contact-form/compare/v0.1.0...v0.2.0) (2026-04-11)


### 💡 New features

* Add an optional WAF to improve security ([#9](https://github.com/unfunco/terraform-aws-contact-form/issues/9)) ([6aa6e9f](https://github.com/unfunco/terraform-aws-contact-form/commit/6aa6e9fbfcfac7208c755fa8ee8a1847ba24ea94))
* Allow contact fields and email templates to be configured ([#8](https://github.com/unfunco/terraform-aws-contact-form/issues/8)) ([a6bbd16](https://github.com/unfunco/terraform-aws-contact-form/commit/a6bbd1623f010b27a5160e3eb0c16691f7ec7471))
* Compute the correct case for derived names ([#6](https://github.com/unfunco/terraform-aws-contact-form/issues/6)) ([abcd275](https://github.com/unfunco/terraform-aws-contact-form/commit/abcd2759cb9c8dc93c00ba38f1ba3a994a61dec8))


### 🐛 Bug fixes

* Add Lambda concurrency and payload limits ([#10](https://github.com/unfunco/terraform-aws-contact-form/issues/10)) ([6090ea4](https://github.com/unfunco/terraform-aws-contact-form/commit/6090ea45a643b079bb4a9aedb42b349e825bb092))


### 🧹 Miscellaneous

* Add refactor release notes and registry badge ([#12](https://github.com/unfunco/terraform-aws-contact-form/issues/12)) ([3b9afd4](https://github.com/unfunco/terraform-aws-contact-form/commit/3b9afd486329281cf42cd8b9657d905b9c4007dc))
* Use WAF region argument and expand examples ([#11](https://github.com/unfunco/terraform-aws-contact-form/issues/11)) ([5342f01](https://github.com/unfunco/terraform-aws-contact-form/commit/5342f011236d2eedd47441bf2f8ea290b96b2f65))

## 0.1.0 (2026-03-21)


### 💡 New features

* Add a basic Lambda contact form handler ([#1](https://github.com/unfunco/terraform-aws-contact-form/issues/1)) ([5cb4d8f](https://github.com/unfunco/terraform-aws-contact-form/commit/5cb4d8f1ccaf7056a175a5f4c556c13624b7550d))
* Add logging and X-Ray tracing support ([#3](https://github.com/unfunco/terraform-aws-contact-form/issues/3)) ([fa05a8d](https://github.com/unfunco/terraform-aws-contact-form/commit/fa05a8d5a2cd92d08e2b7acdf9262fb2146971ca))
* Allow CORS origins to be configured ([4f42f21](https://github.com/unfunco/terraform-aws-contact-form/commit/4f42f21b508d2fe44aa3c85ba3417ff0f93202ab))
* Allow email recipients to be configured ([#4](https://github.com/unfunco/terraform-aws-contact-form/issues/4)) ([9d09331](https://github.com/unfunco/terraform-aws-contact-form/commit/9d09331a40509c3a5ec1b2a3d23676df753301eb))
* Attach the email details to the notification ([#5](https://github.com/unfunco/terraform-aws-contact-form/issues/5)) ([d7731f6](https://github.com/unfunco/terraform-aws-contact-form/commit/d7731f635427204197ce2dde10aeec062e1fe227))
* Log the event when developing or debugging ([f27dc09](https://github.com/unfunco/terraform-aws-contact-form/commit/f27dc09e4bfb0f3fbedfb3ebcf24b2f090c439d0))
