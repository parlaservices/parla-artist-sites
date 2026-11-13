# Happy Birthday Tattoo

Live (once deployed): https://myparla.app/happy-birthday-tattoo. It is served from parla-app as
`public/happy-birthday-tattoo.html`, with the assets in `public/happy-birthday-tattoo/`. This folder is the
**source copy**: it holds the `__TOKENS__`, and the parla-app copy holds the real values. The two should
differ only in those three tokens, because asset URLs are already absolute (`/happy-birthday-tattoo/...`).

This is a single-page tattoo booking form for Happy Birthday Tattoo (242 Marrickville Rd, Marrickville NSW),
built from the designer's `happy-birthday-booking.html` drop. The drop supplied the UI, copy and logo. The
submission code is cursed-canvas's canonical flow, copied verbatim except for the answer map and the studio
email. The drop's version was replaced: its `uploadFiles()` was a stub that sent only file names, and it used
the answer key `artist`, which studio routing does not read.

- **Required "Select your preferred artist" dropdown.** Its answer key is `artist_selection`. Each
  `<option value>` must equal that artist's `studio_members.jotform_option_value` **exactly**. A request with
  "No preference", or with any value that matches no artist, waits in Unassigned for a manager. The options are
  the designer's: Sanchez, Sean, CPM, Norbert, Paramount Tattoo Removal.
- **Photo fields.** Reference images (kind `reference`) are required. Placement photos (kind `placement`) are
  optional, as in the drop. Each field takes up to 5 images, re-encoded to JPEG in the browser. Because a
  reference image is required, every submission goes through `create-website-upload-urls`.
- **First answer.** The design description is sent first, because Parla summarises an enquiry by its first
  answer. Phone is sent under the key `phone`, which migration 211 copies onto the enquiry.
- **Changes from the drop to fit the backend:**
  - PDF is no longer accepted (the backend takes images only).
  - "Max 10MB per file" is now "Up to 5 images", because photos are resized client-side.
  - A honeypot field was added, and the submission id stays the same across retries.
  - The Turnstile line uses the repo-wide `.captcha-notice` class.
  - The inline base64 logo is now `logo.webp`.
  - The DEV HANDOFF comment was removed.

## Deploy (myparla.app)

There is no Netlify site and no `deploy.sh`, on purpose (see `onboarding/` runbook, decision D1). In a
parla-app worktree off `origin/main`:

1. Copy `index.html` to `public/happy-birthday-tattoo.html` and replace the three tokens:
   `__SUPABASE_URL__` = `https://cqqycpzitpkiepfxhvts.supabase.co/functions/v1/website-enquiry`,
   `__TURNSTILE_SITE_KEY__` = `0x4AAAAAAFXZz1Dk0gmVHJfd`, and `__FORM_KEY__` = the studio's `website_form_id`.
2. Copy `logo.webp` and `favicon.svg` to `public/happy-birthday-tattoo/`.
3. In `public/_redirects`, add `/happy-birthday-tattoo/  /happy-birthday-tattoo  301` **above** `/*`.
4. Check: `diff` this file against the public copy. Only the three token lines may differ.
5. Open a PR and merge it, then run the GitHub workflow **"0.3 Prod - Deploy Frontend"**. Merging alone does not deploy.

## Go-live checklist

1. **Studio + key:** the studio must exist in prod. Give it a key:
   `update studios set website_form_id = gen_random_uuid() where id = '<studio id>' and website_form_id is null returning website_form_id;`
2. **Slug:** `select id from users where lower(slug) = 'happy-birthday-tattoo';` must return 0 rows. A static
   file wins over the SPA's `/:slug` booking route and would shadow that artist's page.
3. **Artists:** each artist accepts their studio invite. Then go to Parla → Studio → Artists → each artist →
   "Studio form option", and enter the exact value from the table below.

   | `<option value>` | Parla artist (active, is_artist) |
   |---|---|
   | `Sanchez` | |
   | `Sean` | |
   | `CPM` | |
   | `Norbert` | |
   | `Paramount Tattoo Removal` | |

4. **CORS / Turnstile:** no change needed. `https://myparla.app` is already allowed and is on the shared widget.
5. **End-to-end test:** follow runbook section 7. Send one named-artist submission and one "No preference"
   submission, each with a photo. Then Accept the test enquiry and clean it up.
