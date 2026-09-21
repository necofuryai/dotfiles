# Security

- Never hardcode API keys, tokens or credentials — not in source, and not in config files, Dockerfiles, CI workflows or deployment manifests. Read them from the environment.
- Fail fast when a required secret is missing: throw at startup with the variable name in the message. No non-null assertions, no empty-string fallbacks, no silent defaults — a missing secret must not surface later as an opaque 401.
