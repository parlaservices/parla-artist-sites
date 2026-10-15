# Cursed Canvas

Live: https://cursed-canvas.netlify.app/ (Netlify site `cursed-canvas`,
ID `c5890094-20f5-4775-945f-0d9edb7a1219`, team parlaservices; created 2026-10-15, nothing deployed until FORM_KEY exists)

Single-page tattoo booking form for Cursed Canvas (Edmondson Park NSW), built from the designer's
`cursed-canvas-booking.html` drop. The drop supplied the UI, copy and images. The submission code is
aron-parla-studio's canonical flow, not the drop's stub (the drop's `uploadFiles()` sent only file names).

- Required "Select your preferred artist" dropdown, answer key `artist_selection` (the key studio routing reads).
  Each `<option value>` must equal that artist's `studio_members.jotform_option_value` **exactly**.
  "No preference" (or any non-matching value) waits in Unassigned for a manager.
- Two required photo fields, upload kinds `reference` and `placement` (up to 5 each, re-encoded to JPEG in
  the browser). They go through the website-form uploads from parla-service #199. See
  aron-parla-studio/README.md "How a submission works" for the details.
- The tattoo description is sent as the first answer because Parla summarises an enquiry by its first answer.
- Assets are self-hosted: `logo.webp` was inlined base64 in the drop, and `hero.webp` was hotlinked from the
  studio's Squarespace site (re-encoded from a 2.9 MB PNG).
- Changes from the drop to fit the backend: PDFs are no longer accepted (images only), "Max 10MB per file"
  became "Up to 5 images" because photos are resized client-side, and a honeypot field was added.

## Deploy

```
SUPABASE_URL=https://cqqycpzitpkiepfxhvts.supabase.co/functions/v1/website-enquiry \
FORM_KEY=<website_form_id> TURNSTILE_SITE_KEY=<site key> bash cursed-canvas/deploy.sh
```

The repo keeps the `__TOKENS__`. The script substitutes them on a staged copy and refuses to run
without them. Do not deploy from the repo root.

## Go-live checklist

1. **FORM_KEY:** give the Cursed Canvas studio a key, then put its real artists into the dropdown.
   `update studios set website_form_id = gen_random_uuid() where id = '<studio id>' and website_form_id is null returning website_form_id;`
2. **CORS:** add `https://cursed-canvas.netlify.app` to the prod `ALLOWED_WEBSITE_ORIGINS` secret. The value is a
   comma-separated list and `set` replaces all of it, so keep the existing origins.
3. **Turnstile:** add `cursed-canvas.netlify.app` to the shared invisible widget's hostnames.
4. **End-to-end test:** follow aron-parla-studio/README.md steps 1–5. Its symptom table applies unchanged.
