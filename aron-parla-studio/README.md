# Aron Parla Studio

Live: https://aron-parla-studio.netlify.app/ (Netlify site `aron-parla-studio`,
ID `c80e8600-d226-46ec-b8a5-9a8d1f9db797`, team parlaservices)

A single-page tattoo booking form styled after a Jotform ("Sydney ★ September - December 2026").
It has a required "Select artist" dropdown (answer key `artist_selection`) and two required
photo fields that use the website-form uploads from parla-service #199 (migration 204).

## How a submission works

1. Photos are prepared in the browser: each one is re-encoded to JPEG (longest edge 2400px).
   That keeps files under 10 MB and strips EXIF/GPS data. Up to 5 per field.
2. `POST create-website-upload-urls` with the form key, submission id, hCaptcha token and file list.
   The response contains signed upload URLs plus a one-time `ticket`.
3. Each photo is `PUT` to its signed URL (straight to Supabase Storage).
4. `POST website-enquiry` with the answers and `upload_ticket` (the ticket replaces the captcha).
   Reference images go to `reference_images`. Area photos go to `industry_fields.tattoo_area_photos`.

The upload endpoint is derived from `__SUPABASE_URL__`: `/website-enquiry` is replaced with
`/create-website-upload-urls`. The tattoo description is sent as the first answer
because Parla summarises an enquiry by its first answer.

## Deploy

```
SUPABASE_URL=https://cqqycpzitpkiepfxhvts.supabase.co/functions/v1/website-enquiry \
FORM_KEY=<website_form_id> HCAPTCHA_SITE_KEY=<site key> bash aron-parla-studio/deploy.sh
```

The repo keeps the `__TOKENS__` placeholders. The script substitutes them on a staged copy and refuses
to run without the values. All three values are visible in the live page source, so none of them is secret.
Do not deploy from the repo root.

## Go-live checklist (manual steps)

The checklist is in the order the steps must happen. As of the first deploy (2026-10-15) the page is
live, but **submissions fail until steps 1 and 2 are done.**

### 1. Ship #199 to the prod backend (parla-service)

#199 auto-deployed to dev only. Prod (`cqqycpzitpkiepfxhvts`) still returns 404 for
`create-website-upload-urls`.

1. Generate a sweep secret: `openssl rand -hex 32`
2. GitHub → parla-service → Settings → Environments → `prod` → add the secret `WEBSITE_UPLOAD_SWEEP_SECRET`.
3. Run **0.4 Prod - Deploy Supabase Backend** on `main` with **update_secrets** ticked. This applies
   migration 204, deploys both new functions and pushes the secret:
   `gh workflow run prod-backend-deploy.yml -R parlaservices/parla-service --ref main -f update_secrets=true`
4. Supabase prod → SQL editor (Vault, which migration 204 deliberately leaves out):
   ```sql
   select vault.create_secret('<same value as step 1>', 'website_upload_sweep_secret',
     'Shared secret for website-upload-sweep');
   ```
   Without it, the hourly sweep does nothing and photos from abandoned forms stay in the private holding folder.
5. Check: this should now return 400 (validation), not 404:
   `curl -s -X POST -H 'Content-Type: application/json' -d '{}' https://cqqycpzitpkiepfxhvts.supabase.co/functions/v1/create-website-upload-urls`

### 2. Allow the site's origin (CORS)

```
supabase secrets set ALLOWED_WEBSITE_ORIGINS=https://aron-parla-studio.netlify.app --project-ref cqqycpzitpkiepfxhvts
```
The value is a comma-separated list, and `set` replaces the whole list, so include every extra origin.
It was unset on 2026-10-15. The prod workflow does not touch it. Check that the origin is echoed back:
```
curl -s -o /dev/null -D - -X OPTIONS -H 'Origin: https://aron-parla-studio.netlify.app' \
  -H 'Access-Control-Request-Method: POST' \
  https://cqqycpzitpkiepfxhvts.supabase.co/functions/v1/create-website-upload-urls | grep -i allow-origin
```

### 3. FORM_KEY (who receives the enquiries)

Since 2026-10-15 the site is deployed with the studio key `ffccb13e-bfc2-4d24-b8e7-c038f66d9a82`
(`studios.website_form_id`), so enquiries go to the studio and are routed by the chosen artist.
The dropdown values must match `studio_members.jotform_option_value` (see below). The site was first deployed
with parla-studio's user key `4d5147c2-…`. To change the key:

- **One artist's account:** in Supabase prod, run
  `update users set website_form_id = gen_random_uuid() where email = '<artist email>' and website_form_id is null returning website_form_id;`
- **Studio with routing to artists:**
  `update studios set website_form_id = gen_random_uuid() where id = '<studio id>' and website_form_id is null returning website_form_id;`
  - Then edit the dropdown `<option value>`s in `index.html` so they match each artist's
    `studio_members.jotform_option_value` **exactly**.
  - "No preference", or any value that doesn't match, waits in Unassigned for a manager.

A key must belong to only one user *or* one studio (the user lookup wins). Redeploy with the new
`FORM_KEY` afterwards.

### 4. hCaptcha

The site reuses parla-studio's site key `c92aef22-…`, which lives in the same hCaptcha account as prod's
`HCAPTCHA_SECRET_KEY`. The widget renders on the new domain.

- In the hCaptcha dashboard → Sites → that site → add `aron-parla-studio.netlify.app` to its domains.
  If domain restriction is on, tokens from unlisted hostnames fail verification ("CAPTCHA verification failed", 403).
- If you prefer a separate site key, create it in **the same hCaptcha account**, because prod has one secret.
  Then redeploy with `HCAPTCHA_SITE_KEY=<new key>`.

### 5. End-to-end test

1. Open the site and fill in every required field with test data. Add one photo to each upload field.
   Complete the captcha and submit.
2. You should see "Thank you!".
3. In the Parla dashboard, the enquiry should show the answers, the reference images and the tattoo area photos.
   The notification email should say "2 photos attached".

| Symptom (banner or console) | Cause | Fix |
|---|---|---|
| `Requested function was not found` | #199 not on prod | Step 1 |
| CORS error in console / "Unable to connect" | origin not allowed | Step 2 |
| `CAPTCHA verification failed` | site key / domain mismatch | Step 4 |
| `Form not found` | FORM_KEY not on a live user/studio | Step 3 |
| `Photo uploads are not available right now.` | `HCAPTCHA_SECRET_KEY` unset on prod | set it |
| `Too many requests…` | rate limit (5/min per IP) | wait a minute |
